import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/call_log_model.dart';
import '../../providers/dialer_provider.dart';
import '../../providers/locale_provider.dart';
import '../../utils/colors.dart';
import '../../utils/localization.dart';
import '../contacts/contact_details.dart';
import '../../models/contact_model.dart';

class RecentsTab extends StatefulWidget {
  const RecentsTab({super.key});

  @override
  State<RecentsTab> createState() => _RecentsTabState();
}

class _RecentsTabState extends State<RecentsTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<CallLogModel>> _groupCallLogs(List<CallLogModel> logs, AppLocalization local) {
    final groups = <String, List<CallLogModel>>{
      local.translate('today'): [],
      local.translate('yesterday'): [],
      local.translate('older'): [],
    };

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    for (var log in logs) {
      final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
      if (logDate == todayDate) {
        groups[local.translate('today')]!.add(log);
      } else if (logDate == yesterdayDate) {
        groups[local.translate('yesterday')]!.add(log);
      } else {
        groups[local.translate('older')]!.add(log);
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '0s';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      if (minutes > 0) {
        if (remainingSeconds > 0) {
          return '${hours}h ${minutes}m ${remainingSeconds}s';
        }
        return '${hours}h ${minutes}m';
      }
      if (remainingSeconds > 0) {
        return '${hours}h ${remainingSeconds}s';
      }
      return '${hours}h';
    }
    if (minutes > 0) {
      if (remainingSeconds > 0) {
        return '${minutes}m ${remainingSeconds}s';
      }
      return '${minutes}m';
    }
    return '${remainingSeconds}s';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _getCallTypeIcon(String type) {
    switch (type) {
      case 'incoming':
        return const Icon(Icons.call_received_rounded, color: AppColors.callGreen, size: 14);
      case 'outgoing':
        return const Icon(Icons.call_made_rounded, color: AppColors.accentPurple, size: 14);
      case 'missed':
      default:
        return const Icon(Icons.call_missed_rounded, color: AppColors.hangupRed, size: 14);
    }
  }

  void _triggerCallFlow(BuildContext context, DialerProvider provider, String phone, String name) {
    provider.handleCallAction(context, phone, name);
  }

  void _showLogOptionsSheet(BuildContext context, CallLogModel log, DialerProvider provider, AppLocalization local) {
    final isBlocked = provider.isNumberBlocked(log.phone);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.border(context), width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary(context).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person_outline_rounded, color: AppColors.accentPurple),
                title: Text(
                  local.translate('details'),
                  style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Find or construct contact
                  final contact = provider.contacts.firstWhere(
                    (c) => c.phone.replaceAll(RegExp(r'\D'), '') == log.phone.replaceAll(RegExp(r'\D'), ''),
                    orElse: () => ContactModel(name: log.name.isNotEmpty ? log.name : 'Unknown', phone: log.phone, email: ''),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ContactDetails(contact: contact)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded, color: AppColors.accentPurple),
                title: Text(
                  'Call History Details',
                  style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCallHistoryDetailsDialog(context, log.phone, provider, local);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_all_rounded, color: AppColors.accentPurple),
                title: Text(
                  local.translate('copy'),
                  style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: log.phone));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(local.translate('numberCopied')),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.accentPurple,
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  isBlocked ? Icons.check_circle_outline_rounded : Icons.block_flipped,
                  color: isBlocked ? AppColors.callGreen : AppColors.hangupRed,
                ),
                title: Text(
                  isBlocked ? local.translate('unblock') : local.translate('block'),
                  style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  if (isBlocked) {
                    await provider.unblockContact(log.phone);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(local.translate('removedFromBlocklist')),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.callGreen,
                        ),
                      );
                    }
                  } else {
                    await provider.blockContact(log.phone, log.name.isNotEmpty ? log.name : 'Blocked Number');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(local.translate('addedToBlocklist')),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.hangupRed,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep_rounded, color: AppColors.hangupRed),
                title: Text(
                  local.translate('delete'),
                  style: const TextStyle(color: AppColors.hangupRed, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteCallLog(context, log, provider, local);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteCallLog(BuildContext context, CallLogModel log, DialerProvider provider, AppLocalization local) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Delete Record',
            style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.bold),
          ),
          content: Text(
            local.translate('deleteLogConfirmDesc'),
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(local.translate('cancel'), style: TextStyle(color: AppColors.textSecondary(context))),
            ),
            TextButton(
              onPressed: () async {
                if (log.id != null) {
                  await provider.deleteCallLogRecord(log.id!);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(local.translate('delete'), style: const TextStyle(color: AppColors.hangupRed, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showCallHistoryDetailsDialog(BuildContext context, String phone, DialerProvider provider, AppLocalization local) {
    // Filters call history only for this number
    final userLogs = provider.callLogs.where((l) => l.phone == phone).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log History',
                style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                phone,
                style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: userLogs.isEmpty
                ? Center(
                    child: Text(
                      local.translate('noCallLogs'),
                      style: TextStyle(color: AppColors.textSecondary(context)),
                    ),
                  )
                : ListView.builder(
                    itemCount: userLogs.length,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, idx) {
                      final item = userLogs[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            _getCallTypeIcon(item.type),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.type.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                  Text(
                                    _formatTime(item.timestamp),
                                    style: TextStyle(color: AppColors.textSecondary(context), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              item.type == 'missed' ? 'Missed' : _formatDuration(item.durationSeconds),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(local.translate('ok'), style: const TextStyle(color: AppColors.accentPurple, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dialerProvider = Provider.of<DialerProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final local = AppLocalization(localeProvider.locale);

    final filteredLogs = dialerProvider.getFilteredCallLogs();
    final groupedLogs = _groupCallLogs(filteredLogs, local);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          local.translate('appName'),
          style: TextStyle(
            color: AppColors.accentPurple,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (filteredLogs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever_rounded, color: AppColors.hangupRed),
              tooltip: 'Clear Call History',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: AppColors.surface(context),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text(
                        'Clear History',
                        style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        'Are you sure you want to clear the entire call history?',
                        style: TextStyle(color: AppColors.textSecondary(context)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(local.translate('cancel'), style: TextStyle(color: AppColors.textSecondary(context))),
                        ),
                        TextButton(
                          onPressed: () async {
                            await dialerProvider.clearHistory();
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Clear All', style: TextStyle(color: AppColors.hangupRed, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Elegant Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => dialerProvider.setRecentsSearchQuery(val),
              style: TextStyle(color: AppColors.textPrimary(context)),
              decoration: InputDecoration(
                hintText: local.translate('searchPlaceholder'),
                hintStyle: TextStyle(color: AppColors.textSecondary(context).withOpacity(0.6)),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary(context)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          dialerProvider.setRecentsSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceCard(context),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.accentPurple, width: 1.5),
                ),
              ),
            ),
          ),

          // Logs Display List
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.call_end_rounded,
                          size: 64,
                          color: AppColors.textSecondary(context).withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          local.translate('noCallLogs'),
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: groupedLogs.length,
                    itemBuilder: (context, groupIndex) {
                      final groupKey = groupedLogs.keys.elementAt(groupIndex);
                      final groupItems = groupedLogs[groupKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Group Title Date Header
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0, top: 16.0, bottom: 8.0),
                            child: Text(
                              groupKey.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentPurple,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),

                          // Group Call items
                          ListView.builder(
                            itemCount: groupItems.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, logIndex) {
                              final log = groupItems[logIndex];
                              final isMissed = log.type == 'missed';
                              final title = log.name.isNotEmpty ? log.name : log.phone;
                              final letter = title.isNotEmpty ? title[0].toUpperCase() : '?';

                              return ListTile(
                                leading: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: AppColors.getAvatarColor(log.name.isNotEmpty ? log.name : log.phone),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    letter,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isMissed ? AppColors.hangupRed : AppColors.textPrimary(context),
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    _getCallTypeIcon(log.type),
                                    const SizedBox(width: 6),
                                    Text(
                                      isMissed
                                          ? 'Missed'
                                          : '${_formatDuration(log.durationSeconds)} • ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                    Text(
                                      _formatTime(log.timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary(context)),
                                  onPressed: () => _showLogOptionsSheet(context, log, dialerProvider, local),
                                ),
                                onTap: () => _triggerCallFlow(context, dialerProvider, log.phone, log.name),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
