import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_navigator.dart';
import '../screens/calling/active_call.dart';
import '../screens/calling/sim_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:call_log/call_log.dart' as cl;
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../models/contact_model.dart';
import '../models/call_log_model.dart';
import '../models/blocked_number.dart';
import '../database/database_helper.dart';

class DialerProvider with ChangeNotifier {
  // Database instance helper (only for blocked numbers now)
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // App Lists
  List<ContactModel> _contacts = [];
  List<CallLogModel> _callLogs = [];
  List<BlockedNumber> _blockedNumbers = [];
  List<ContactModel> _t9SearchResults = [];

  List<ContactModel> get contacts => _contacts;
  List<CallLogModel> get callLogs => _callLogs;
  List<BlockedNumber> get blockedNumbers => _blockedNumbers;
  List<ContactModel> get t9SearchResults => _t9SearchResults;

  // Onboarding States
  bool _welcomeSplashSeen = false;
  bool _languageSetupSeen = false;
  bool _permissionSetupSeen = false;

  bool get welcomeSplashSeen => _welcomeSplashSeen;
  bool get languageSetupSeen => _languageSetupSeen;
  bool get permissionSetupSeen => _permissionSetupSeen;

  // Dialer T9 Input State
  String _dialerInput = '';
  String get dialerInput => _dialerInput;

  // Search input filters
  String _contactSearchQuery = '';
  String _recentsSearchQuery = '';

  String get contactSearchQuery => _contactSearchQuery;
  String get recentsSearchQuery => _recentsSearchQuery;

  // Active Calling States
  bool _isCallActive = false;
  String _activeCallerName = '';
  String _activeCallerPhone = '';
  String _activeCallState = 'disconnected';
  Timer? _callTimer;
  int _callDurationSeconds = 0;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isOnHold = false;
  String _simSelected = 'SIM 1';
  bool _isScreenPushed = false;
  bool _isDefaultDialer = false;

  /// True once _loadOnboardingStates() has completed.
  /// InitialSplash waits on this before deciding which screen to show.
  bool _isInitialized = false;

  bool get isCallActive => _isCallActive;
  String get activeCallerName => _activeCallerName;
  String get activeCallerPhone => _activeCallerPhone;
  String get activeCallState => _activeCallState;
  int get callDurationSeconds => _callDurationSeconds;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isOnHold => _isOnHold;
  String get simSelected => _simSelected;
  bool get isDefaultDialer => _isDefaultDialer;
  bool get isInitialized => _isInitialized;

  DialerProvider() {
    _initPlatformChannel();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadOnboardingStates();
    // Signal splash that onboarding state is now known — BEFORE slower operations
    _isInitialized = true;
    notifyListeners();
    // Continue loading remaining data in the background
    checkDefaultDialerStatus();
    refreshAllData();
  }

  static const MethodChannel _platform = MethodChannel('com.antigravity.callin/dialer');

  void _initPlatformChannel() {
    _platform.setMethodCallHandler((call) async {
      if (call.method == 'incomingCall') {
        final args = call.arguments as Map?;
        final number = args?['number'] as String? ?? '';
        
        // Query database directly to handle cold-starts before Provider has loaded blocked list
        final dbBlockedList = await _dbHelper.getBlockedNumbers();
        final dbBlocked = dbBlockedList.any((b) => _numbersMatch(b.phone, number));
        if (dbBlocked) {
          debugPrint('Incoming call from blocked number ($number) rejected at startup.');
          await endCall();
          return null;
        }

        _isCallActive = true;
        _activeCallerPhone = number;
        _callDurationSeconds = 0; // Reset timer for new call
        
        _resolveActiveCallerName();
        _activeCallState = 'ringing';
        notifyListeners();

        // Show in-app caller screen
        try {
          if (AppNavigator.key.currentState != null) {
            if (!_isScreenPushed) {
              _isScreenPushed = true;
              AppNavigator.key.currentState!.push(
                MaterialPageRoute(builder: (_) => const ActiveCall()),
              ).then((_) {
                _isScreenPushed = false;
              });
            }
          }
        } catch (e) {}
      } else if (call.method == 'defaultDialerResult') {
        final granted = call.arguments as bool? ?? false;
        debugPrint('Default dialer result: $granted');
        _isDefaultDialer = granted;
        notifyListeners();
        return granted;
      } else if (call.method == 'isBlocked') {
        final args = call.arguments as Map?;
        final number = args?['number'] as String? ?? '';
        // Ensure blocked numbers are refreshed from DB
        final dbBlockedList = await _dbHelper.getBlockedNumbers();
        final blocked = dbBlockedList.any((b) => _numbersMatch(b.phone, number));
        return blocked;
      } else if (call.method == 'callState') {
        final args = call.arguments as Map?;
        final state = args?['state'] as String? ?? '';
        final number = args?['number'] as String? ?? '';

        String normalizedState = state;
        if (state == 'answered' || state == 'unhold') {
          normalizedState = 'connected';
        }

        if (normalizedState == 'disconnected') {
          if (_activeCallState == 'disconnected') {
            // Already handled / disconnecting, skip duplicate scheduling
            return null;
          }
          _isCallActive = false;
          _activeCallState = 'disconnected';
          _callTimer?.cancel();
          _callTimer = null;
          _isMuted = false;
          _isSpeakerOn = false;
          _isOnHold = false;
          notifyListeners();

          refreshCallLogs();
          Future.delayed(const Duration(milliseconds: 1000), () {
            refreshCallLogs();
          });

          Future.delayed(const Duration(milliseconds: 800), () {
            try {
              if (AppNavigator.key.currentState != null && AppNavigator.key.currentState!.canPop()) {
                AppNavigator.key.currentState!.pop();
              }
            } catch (e) {}
          });
          return null;
        }

        _activeCallerPhone = number;
        _activeCallState = normalizedState;
        _isCallActive = normalizedState != 'disconnected';

        _resolveActiveCallerName();

        // Manage active call duration timer
        if (normalizedState == 'connected') {
          _isMuted = false;
          _isSpeakerOn = false;
          _isOnHold = false;
          if (_callTimer == null) {
            _callDurationSeconds = 0;
            _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              _callDurationSeconds++;
              notifyListeners();
            });
          }
        }

        notifyListeners();

        // show the in-app caller screen when call becomes active/ringing
        if (_isCallActive) {
          try {
            if (AppNavigator.key.currentState != null) {
              if (!_isScreenPushed) {
                _isScreenPushed = true;
                AppNavigator.key.currentState!.push(
                  MaterialPageRoute(builder: (_) => const ActiveCall()),
                ).then((_) {
                  _isScreenPushed = false;
                });
              }
            }
          } catch (e) {}
        }
      }
    });
  }

  Future<void> checkDefaultDialerStatus() async {
    try {
      final bool status = await _platform.invokeMethod('isDefaultDialer');
      if (_isDefaultDialer != status) {
        _isDefaultDialer = status;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to check default dialer status: $e');
    }
  }

  Future<void> requestSetAsDefaultDialer() async {
    try {
      await _platform.invokeMethod('requestDefaultDialer');
      await checkDefaultDialerStatus();
    } catch (e) {
      debugPrint('Failed to request default dialer: $e');
    }
  }

  // --- Onboarding Persistence ---
  Future<void> _loadOnboardingStates() async {
    final prefs = await SharedPreferences.getInstance();
    _welcomeSplashSeen = prefs.getBool('welcome_seen') ?? false;
    _languageSetupSeen = prefs.getBool('lang_seen') ?? false;
    _permissionSetupSeen = prefs.getBool('perm_seen') ?? false;
    notifyListeners();
  }

  Future<void> setWelcomeSeen() async {
    _welcomeSplashSeen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_seen', true);
    notifyListeners();
  }

  Future<void> setLanguageSeen() async {
    _languageSetupSeen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lang_seen', true);
    notifyListeners();
  }

  Future<void> setPermissionSeen() async {
    _permissionSetupSeen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('perm_seen', true);
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    _welcomeSplashSeen = false;
    _languageSetupSeen = false;
    _permissionSetupSeen = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_seen', false);
    await prefs.setBool('lang_seen', false);
    await prefs.setBool('perm_seen', false);
    notifyListeners();
  }

  // --- Data Loading & Synchronization ---
  Future<void> refreshAllData() async {
    await refreshContacts();
    await refreshCallLogs();
    await refreshBlockedNumbers();
  }

  Future<void> refreshContacts() async {
    try {
      final permissionStatus = await fc.FlutterContacts.permissions.request(
        fc.PermissionType.read,
      );
      if (permissionStatus == fc.PermissionStatus.granted ||
          permissionStatus == fc.PermissionStatus.limited) {
        try {
          final List<fc.Contact> contacts = await fc.FlutterContacts.getAll(
            properties: const {
              fc.ContactProperty.name,
              fc.ContactProperty.phone,
              fc.ContactProperty.email,
              fc.ContactProperty.address,
              fc.ContactProperty.organization,
              fc.ContactProperty.note,
              fc.ContactProperty.favorite,
            },
          );
          // Load persisted favorites
          final prefs = await SharedPreferences.getInstance();
          final favList = prefs.getStringList('favorites') ?? <String>[];
          final favSet = favList.map((s) => s.replaceAll(RegExp(r'\D'), '')).toSet();

          _contacts = contacts.map((c) {
            final String phone = c.phones.isNotEmpty ? c.phones.first.number : '';
            final String email = c.emails.isNotEmpty
                ? c.emails.first.address
                : '';

            final List<Map<String, String>> phonesList = c.phones.map((p) {
              String lbl = 'MOBILE';
              if (p.label.label == fc.PhoneLabel.home) lbl = 'HOME';
              if (p.label.label == fc.PhoneLabel.work) lbl = 'WORK';
              if (p.label.label == fc.PhoneLabel.main) lbl = 'MAIN';
              if (p.label.label == fc.PhoneLabel.other) lbl = 'OTHER';
              if (p.label.label == fc.PhoneLabel.custom) lbl = p.label.customLabel?.toUpperCase() ?? 'CUSTOM';
              return {'number': p.number, 'label': lbl};
            }).toList();

            final List<Map<String, String>> emailsList = c.emails.map((e) {
              String lbl = 'HOME';
              if (e.label.label == fc.EmailLabel.work) lbl = 'WORK';
              if (e.label.label == fc.EmailLabel.other) lbl = 'OTHER';
              if (e.label.label == fc.EmailLabel.custom) lbl = e.label.customLabel?.toUpperCase() ?? 'CUSTOM';
              return {'address': e.address, 'label': lbl};
            }).toList();

            final String company = c.organizations.isNotEmpty ? (c.organizations.first.name ?? '') : '';
            final String jobTitle = c.organizations.isNotEmpty ? (c.organizations.first.jobTitle ?? '') : '';
            final String notes = c.notes.isNotEmpty ? c.notes.first.note : '';
            final String address = c.addresses.isNotEmpty ? (c.addresses.first.formatted ?? '') : '';

            return ContactModel(
              id: (c.id ?? '').hashCode,
              nativeId: c.id ?? '',
              name: ((c.displayName?.isNotEmpty) == true)
                  ? c.displayName!
                  : 'Unknown',
              phone: phone,
              email: email,
              isFavorite: favSet.contains(phone.replaceAll(RegExp(r'\D'), '')) || c.android?.isFavorite == true,
              phones: phonesList,
              emails: emailsList,
              company: company,
              jobTitle: jobTitle,
              notes: notes,
              address: address,
            );
          }).toList();
          if (_isCallActive) {
            _resolveActiveCallerName();
          }
          _filterT9Results();
          notifyListeners();
        } catch (e) {
          debugPrint("Error fetching contacts: $e");
        }
      }
    } catch (e) {
      debugPrint("Failed to request contact permissions: $e");
    }
  }

  Future<void> refreshCallLogs() async {
    try {
      Iterable<cl.CallLogEntry> entries = await cl.CallLog.get();
      _callLogs = entries.map((e) {
        String type = 'outgoing';
        if (e.callType == cl.CallType.incoming) type = 'incoming';
        if (e.callType == cl.CallType.missed) type = 'missed';

        return CallLogModel(
          name: (e.name != null && e.name!.isNotEmpty) ? e.name! : 'Unknown',
          phone: e.number ?? 'Unknown',
          type: type,
          timestamp: DateTime.fromMillisecondsSinceEpoch(e.timestamp ?? 0),
          durationSeconds: e.duration ?? 0,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to fetch call logs: $e");
    }
  }

  Future<void> refreshBlockedNumbers() async {
    _blockedNumbers = await _dbHelper.getBlockedNumbers();
    notifyListeners();
  }

  // --- Filtered lists for Screens ---
  List<ContactModel> getFilteredContacts() {
    if (_contactSearchQuery.isEmpty) return _contacts;
    return _contacts.where((c) {
      return c.name.toLowerCase().contains(_contactSearchQuery.toLowerCase()) ||
          c.phone.contains(_contactSearchQuery);
    }).toList();
  }

  List<CallLogModel> getFilteredCallLogs() {
    if (_recentsSearchQuery.isEmpty) return _callLogs;
    return _callLogs.where((l) {
      return l.name.toLowerCase().contains(_recentsSearchQuery.toLowerCase()) ||
          l.phone.contains(_recentsSearchQuery);
    }).toList();
  }

  void setContactSearchQuery(String query) {
    _contactSearchQuery = query;
    notifyListeners();
  }

  void setRecentsSearchQuery(String query) {
    _recentsSearchQuery = query;
    notifyListeners();
  }

  // --- Contacts Operations ---
  Future<void> addContact(
    String name,
    String phone,
    String email, {
    List<Map<String, String>>? phones,
    List<Map<String, String>>? emails,
    String company = '',
    String jobTitle = '',
    String notes = '',
    String address = '',
  }) async {
    final permissionStatus = await fc.FlutterContacts.permissions.request(
      fc.PermissionType.readWrite,
    );
    if (permissionStatus == fc.PermissionStatus.granted ||
        permissionStatus == fc.PermissionStatus.limited) {
      final actualPhones = phones ?? [{'number': phone, 'label': 'MOBILE'}];
      final actualEmails = emails ?? [{'address': email, 'label': 'HOME'}];

      final fcPhones = actualPhones.map((p) {
        final l = p['label']?.toUpperCase();
        fc.Label<fc.PhoneLabel> phoneLabel;
        if (l == 'HOME') {
          phoneLabel = const fc.Label(fc.PhoneLabel.home);
        } else if (l == 'WORK') {
          phoneLabel = const fc.Label(fc.PhoneLabel.work);
        } else if (l == 'MAIN') {
          phoneLabel = const fc.Label(fc.PhoneLabel.main);
        } else if (l == 'OTHER') {
          phoneLabel = const fc.Label(fc.PhoneLabel.other);
        } else if (l != null && l != 'MOBILE') {
          phoneLabel = fc.Label(fc.PhoneLabel.custom, p['label']);
        } else {
          phoneLabel = const fc.Label(fc.PhoneLabel.mobile);
        }
        return fc.Phone(number: p['number']!, label: phoneLabel);
      }).toList();

      final fcEmails = actualEmails.map((e) {
        final l = e['label']?.toUpperCase();
        fc.Label<fc.EmailLabel> emailLabel;
        if (l == 'WORK') {
          emailLabel = const fc.Label(fc.EmailLabel.work);
        } else if (l == 'OTHER') {
          emailLabel = const fc.Label(fc.EmailLabel.other);
        } else if (l != null && l != 'HOME') {
          emailLabel = fc.Label(fc.EmailLabel.custom, e['label']);
        } else {
          emailLabel = const fc.Label(fc.EmailLabel.home);
        }
        return fc.Email(address: e['address']!, label: emailLabel);
      }).toList();

      final parts = name.trim().split(' ');
      final String first = parts.isNotEmpty ? parts.first : '';
      final String last = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      final newContact = fc.Contact(
        name: fc.Name(first: first, last: last),
        phones: fcPhones,
        emails: fcEmails,
        organizations: (company.isNotEmpty || jobTitle.isNotEmpty)
            ? [fc.Organization(name: company, jobTitle: jobTitle)]
            : [],
        notes: notes.isNotEmpty ? [fc.Note(note: notes)] : [],
        addresses: address.isNotEmpty ? [fc.Address(formatted: address)] : [],
      );

      await fc.FlutterContacts.create(newContact);
      await refreshContacts();
    }
  }

  Future<void> updateContact(ContactModel contact) async {
    final permissionStatus = await fc.FlutterContacts.permissions.request(
      fc.PermissionType.readWrite,
    );
    if (permissionStatus == fc.PermissionStatus.granted ||
        permissionStatus == fc.PermissionStatus.limited) {
      final fc.Contact? nativeContact = await fc.FlutterContacts.get(
        contact.nativeId,
        properties: const {
          fc.ContactProperty.name,
          fc.ContactProperty.phone,
          fc.ContactProperty.email,
          fc.ContactProperty.address,
          fc.ContactProperty.organization,
          fc.ContactProperty.note,
        },
      );
      if (nativeContact != null) {
        final parts = contact.name.trim().split(' ');
        final String first = parts.isNotEmpty ? parts.first : '';
        final String last = parts.length > 1 ? parts.sublist(1).join(' ') : '';

        final updatedPhones = contact.phones.map((p) {
          final l = p['label']?.toUpperCase();
          fc.Label<fc.PhoneLabel> phoneLabel;
          if (l == 'HOME') {
            phoneLabel = const fc.Label(fc.PhoneLabel.home);
          } else if (l == 'WORK') {
            phoneLabel = const fc.Label(fc.PhoneLabel.work);
          } else if (l == 'MAIN') {
            phoneLabel = const fc.Label(fc.PhoneLabel.main);
          } else if (l == 'OTHER') {
            phoneLabel = const fc.Label(fc.PhoneLabel.other);
          } else if (l != null && l != 'MOBILE') {
            phoneLabel = fc.Label(fc.PhoneLabel.custom, p['label']);
          } else {
            phoneLabel = const fc.Label(fc.PhoneLabel.mobile);
          }
          return fc.Phone(number: p['number']!, label: phoneLabel);
        }).toList();

        final updatedEmails = contact.emails.map((e) {
          final l = e['label']?.toUpperCase();
          fc.Label<fc.EmailLabel> emailLabel;
          if (l == 'WORK') {
            emailLabel = const fc.Label(fc.EmailLabel.work);
          } else if (l == 'OTHER') {
            emailLabel = const fc.Label(fc.EmailLabel.other);
          } else if (l != null && l != 'HOME') {
            emailLabel = fc.Label(fc.EmailLabel.custom, e['label']);
          } else {
            emailLabel = const fc.Label(fc.EmailLabel.home);
          }
          return fc.Email(address: e['address']!, label: emailLabel);
        }).toList();

        final updatedContact = nativeContact.copyWith(
          name: fc.Name(first: first, last: last),
          phones: updatedPhones,
          emails: updatedEmails,
          organizations: (contact.company.isNotEmpty || contact.jobTitle.isNotEmpty)
              ? [fc.Organization(name: contact.company, jobTitle: contact.jobTitle)]
              : [],
          notes: contact.notes.isNotEmpty ? [fc.Note(note: contact.notes)] : [],
          addresses: contact.address.isNotEmpty ? [fc.Address(formatted: contact.address)] : [],
        );

        await fc.FlutterContacts.update(updatedContact);
        await refreshContacts();
      }
    }
  }

  Future<void> deleteContact(int id) async {
    final permissionStatus = await fc.FlutterContacts.permissions.request(
      fc.PermissionType.readWrite,
    );
    if (permissionStatus == fc.PermissionStatus.granted ||
        permissionStatus == fc.PermissionStatus.limited) {
      ContactModel? foundContact;
      try {
        foundContact = _contacts.firstWhere((c) => c.id == id);
      } catch (_) {}

      if (foundContact != null && foundContact.nativeId.isNotEmpty) {
        await fc.FlutterContacts.delete(foundContact.nativeId);
        await refreshContacts();
      }
    }
  }

  Future<void> toggleFavoriteContact(int id, bool currentFavState) async {
    // Toggle favorite state for contact identified by our internal id
    ContactModel? contact;
    try {
      contact = _contacts.firstWhere((c) => c.id == id);
    } catch (e) {
      return;
    }

    final updated = contact.copyWith(isFavorite: !currentFavState);
    final idx = _contacts.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _contacts[idx] = updated;
    }

    // Persist favorites by phone number
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favorites') ?? <String>[];
    final normalized = updated.phone.replaceAll(RegExp(r'\D'), '');
    final favSet = favList.map((s) => s.replaceAll(RegExp(r'\D'), '')).toSet();
    if (updated.isFavorite) {
      favSet.add(normalized);
    } else {
      favSet.remove(normalized);
    }
    await prefs.setStringList('favorites', favSet.toList());
    notifyListeners();
  }

  // --- Blocklist Operations ---
  Future<void> blockContact(String phone, String name) async {
    final block = BlockedNumber(phone: phone, name: name);
    await _dbHelper.insertBlockedNumber(block);
    await refreshBlockedNumbers();
  }

  Future<void> unblockContact(String phone) async {
    await _dbHelper.deleteBlockedNumberByPhone(phone);
    await refreshBlockedNumbers();
  }

  bool isNumberBlocked(String phone) {
    return _blockedNumbers.any(
      (b) => _numbersMatch(b.phone, phone),
    );
  }

  // --- Call History Operations ---
  Future<void> deleteCallLogRecord(int id) async {
    // Android doesn't allow easy deletion of a single log entry through call_log package natively
    // We just refresh.
    await refreshCallLogs();
  }

  Future<void> clearHistory() async {
    await refreshCallLogs();
  }

  // --- Dialer T9 Engine ---
  void addDialerDigit(String digit) {
    _dialerInput += digit;
    _filterT9Results();
    notifyListeners();
  }

  void removeLastDialerDigit() {
    if (_dialerInput.isNotEmpty) {
      _dialerInput = _dialerInput.substring(0, _dialerInput.length - 1);
      _filterT9Results();
      notifyListeners();
    }
  }

  void clearDialerInput() {
    _dialerInput = '';
    _t9SearchResults = [];
    notifyListeners();
  }

  void _filterT9Results() {
    if (_dialerInput.isEmpty) {
      _t9SearchResults = [];
      return;
    }

    final t9Regex = _generateT9Regex(_dialerInput);
    final inputLower = _dialerInput;

    _t9SearchResults = _contacts.where((contact) {
      final cleanPhone = contact.phone.replaceAll(RegExp(r'\D'), '');
      final matchesPhone = cleanPhone.contains(inputLower);
      if (matchesPhone) return true;

      final nameLower = contact.name.toLowerCase();
      final matchesName = t9Regex.hasMatch(nameLower);
      return matchesName;
    }).toList();
  }

  RegExp _generateT9Regex(String digits) {
    final map = {
      '2': '[abc]',
      '3': '[def]',
      '4': '[ghi]',
      '5': '[jkl]',
      '6': '[mno]',
      '7': '[pqrs]',
      '8': '[tuv]',
      '9': '[wxyz]',
      '0': '[ ]',
      '1': '[.]',
    };

    String pattern = '';
    for (int i = 0; i < digits.length; i++) {
      final key = digits[i];
      pattern += map[key] ?? RegExp.escape(key);
    }
    return RegExp(pattern);
  }

  // --- Real Calling Engine ---
  void setSim(String sim) {
    _simSelected = sim;
    notifyListeners();
  }

  Future<int> getActiveSimCount() async {
    try {
      final int count = await _platform.invokeMethod('getActiveSimCount');
      return count;
    } catch (e) {
      debugPrint('Failed to get active SIM count: $e');
      return 1;
    }
  }

  Future<void> handleCallAction(BuildContext context, String phone, String name) async {
    final simCount = await getActiveSimCount();
    if (simCount <= 1) {
      setSim('SIM 1');
      await startCall(phone, name);
    } else {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return SimSelector(
            phoneNumber: phone,
            onSelected: (sim) {
              setSim(sim);
              startCall(phone, name);
            },
          );
        },
      );
    }
  }

  Future<void> startCall(String phone, String name) async {
    _callDurationSeconds = 0; // Reset timer for new call
    try {
      const platform = MethodChannel('com.antigravity.callin/dialer');
      await platform.invokeMethod('startCall', {'number': phone, 'name': name});
    } catch (e) {
      await FlutterPhoneDirectCaller.callNumber(phone);
    }

    _isCallActive = true;
    _activeCallerPhone = phone;
    _resolveActiveCallerName();
    if (name.isNotEmpty && _activeCallerName == phone) {
      _activeCallerName = name;
    }
    _activeCallState = 'dialing';
    notifyListeners();

    Future.delayed(const Duration(seconds: 5), () {
      refreshCallLogs();
    });
  }

  Future<void> answerCall() async {
    try {
      await _platform.invokeMethod('answerCall');
      _activeCallState = 'connected';
      _isMuted = false;
      _isSpeakerOn = false;
      _isOnHold = false;
      _callDurationSeconds = 0;
      _callTimer?.cancel();
      _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _callDurationSeconds++;
        notifyListeners();
      });
      notifyListeners();
    } catch (e) {
      debugPrint('answerCall platform error: $e');
    }
  }

  Future<void> endCall() async {
    try {
      await _platform.invokeMethod('endCall');
    } catch (e) {
      debugPrint('endCall platform error: $e');
    }
    
    if (_activeCallState == 'disconnected') {
      return;
    }
    
    _isCallActive = false;
    _activeCallState = 'disconnected';
    _callTimer?.cancel();
    _callTimer = null;
    _isMuted = false;
    _isSpeakerOn = false;
    _isOnHold = false;
    notifyListeners();

    refreshCallLogs();
    Future.delayed(const Duration(milliseconds: 1000), () {
      refreshCallLogs();
    });

    // Pop the screen after a brief delay so they see "Disconnected" and duration
    Future.delayed(const Duration(milliseconds: 800), () {
      try {
        if (AppNavigator.key.currentState != null && AppNavigator.key.currentState!.canPop()) {
          AppNavigator.key.currentState!.pop();
        }
      } catch (e) {}
    });
  }

  void triggerMissedCall(String phone, String name) {
    // Handled by OS natively.
  }

  Future<void> toggleMute() async {
    try {
      final target = !_isMuted;
      await _platform.invokeMethod('setMute', {'muted': target});
      _isMuted = target;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to set mute: $e');
    }
  }

  Future<void> toggleSpeaker() async {
    try {
      final target = !_isSpeakerOn;
      await _platform.invokeMethod('setSpeaker', {'enabled': target});
      _isSpeakerOn = target;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to set speaker: $e');
    }
  }

  Future<void> toggleHold() async {
    try {
      final target = !_isOnHold;
      await _platform.invokeMethod('setHold', {'hold': target});
      _isOnHold = target;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to set hold: $e');
    }
  }

  /// Sends a real DTMF tone to the active call via the native InCallService.
  Future<void> playDtmfTone(String digit) async {
    try {
      await _platform.invokeMethod('playDtmfTone', {'digit': digit});
    } catch (e) {
      debugPrint('Failed to play DTMF tone: $e');
    }
  }

  bool _numbersMatch(String p1, String p2) {
    final d1 = p1.replaceAll(RegExp(r'\D'), '');
    final d2 = p2.replaceAll(RegExp(r'\D'), '');
    if (d1.isEmpty || d2.isEmpty) return false;

    if (d1 == d2) return true;

    if (d1.length >= 10 && d2.length >= 10) {
      return d1.substring(d1.length - 10) == d2.substring(d2.length - 10);
    }

    final len = d1.length < d2.length ? d1.length : d2.length;
    if (len >= 7) {
      return d1.substring(d1.length - len) == d2.substring(d2.length - len);
    }

    return false;
  }

  void _resolveActiveCallerName() {
    if (_activeCallerPhone.isEmpty) return;

    final matchedContact = _contacts.firstWhere(
      (c) {
        if (_numbersMatch(c.phone, _activeCallerPhone)) return true;
        return c.phones.any((p) => _numbersMatch(p['number'] ?? '', _activeCallerPhone));
      },
      orElse: () => ContactModel(name: 'Unknown', phone: _activeCallerPhone, email: ''),
    );
    _activeCallerName = matchedContact.name != 'Unknown' ? matchedContact.name : _activeCallerPhone;
  }
}
