import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact_model.dart';
import '../../providers/dialer_provider.dart';
import '../../providers/locale_provider.dart';
import '../../utils/colors.dart';
import '../../utils/localization.dart';
import 'add_contact.dart';

class ContactDetails extends StatelessWidget {
  final ContactModel contact;

  const ContactDetails({
    super.key,
    required this.contact,
  });

  void _triggerCallFlow(BuildContext context, DialerProvider provider, String phone, String name) {
    provider.handleCallAction(context, phone, name);
  }

  void _showWhatsAppChecker(BuildContext context, AppLocalization local, String actionType, String phone) {
    bool isWhatsAppInstalled = false; // Mocking false to trigger the play store redirect flow

    if (isWhatsAppInstalled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening WhatsApp for $actionType...'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.callGreen,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.surface(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.warningOrange, size: 28),
                const SizedBox(width: 10),
                Text(
                  local.translate('whatsAppNotInstalled'),
                  style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              local.translate('whatsAppInstallPlayStore'),
              style: TextStyle(color: AppColors.textSecondary(context), height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  local.translate('cancel'),
                  style: TextStyle(color: AppColors.textSecondary(context)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Redirecting to Google Play Store...'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.accentPurple,
                    ),
                  );
                },
                child: Text(
                  local.translate('whatsAppInstallBtn'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _confirmDeleteContact(BuildContext context, DialerProvider provider, AppLocalization local, int? id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            local.translate('deleteConfirmTitle'),
            style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.bold),
          ),
          content: Text(
            local.translate('deleteConfirmDesc'),
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(local.translate('cancel'), style: TextStyle(color: AppColors.textSecondary(context))),
            ),
            TextButton(
              onPressed: () async {
                if (id != null) {
                  await provider.deleteContact(id);
                }
                if (context.mounted) {
                  Navigator.pop(context); // Pop dialog
                  Navigator.pop(context); // Pop details page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact deleted successfully'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.hangupRed,
                    ),
                  );
                }
              },
              child: Text(local.translate('delete'), style: const TextStyle(color: AppColors.hangupRed, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _shareContact(BuildContext context, ContactModel c) {
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share Contact Info',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(context, Icons.copy_rounded, 'Copy Text', () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied contact details to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.accentPurple,
                      ),
                    );
                  }),
                  _buildShareOption(context, Icons.qr_code_2_rounded, 'QR Code', () => Navigator.pop(context)),
                  _buildShareOption(context, Icons.message_rounded, 'SMS Share', () => Navigator.pop(context)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Icon(icon, color: AppColors.accentPurple, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsAppButton(BuildContext context, IconData icon, String label, AppLocalization local, String phone) {
    return InkWell(
      onTap: () => _showWhatsAppChecker(context, local, label, phone),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldBadge(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.accentPurple,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0, top: 20.0, bottom: 8.0),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary(context),
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dialerProvider = Provider.of<DialerProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final local = AppLocalization(localeProvider.locale);

    // Watch dynamic updates to see block/favorite status
    final isBlocked = dialerProvider.isNumberBlocked(contact.phone);
    final dbContact = dialerProvider.contacts.firstWhere(
      (c) => c.nativeId == contact.nativeId || c.phone == contact.phone,
      orElse: () => contact,
    );

    // Extract fields
    final phonesList = dbContact.phones.isNotEmpty
        ? dbContact.phones
        : [{'number': dbContact.phone, 'label': 'MOBILE'}];
    final emailsList = dbContact.emails.isNotEmpty
        ? dbContact.emails
        : (dbContact.email.isNotEmpty ? [{'address': dbContact.email, 'label': 'HOME'}] : <Map<String, String>>[]);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // AppBar Favorite Action
          IconButton(
            icon: Icon(
              dbContact.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: dbContact.isFavorite ? AppColors.starGold : AppColors.textSecondary(context),
              size: 26,
            ),
            onPressed: () async {
              if (dbContact.id != null) {
                await dialerProvider.toggleFavoriteContact(dbContact.id!, dbContact.isFavorite);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(local.translate('favSuccess')),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.accentPurple,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
          ),
          // Three Dot Dropdown
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.textPrimary(context)),
            color: AppColors.surface(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (val) {
              if (val == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddContact(contactToEdit: dbContact)),
                );
              } else if (val == 'delete') {
                _confirmDeleteContact(context, dialerProvider, local, dbContact.id);
              } else if (val == 'share') {
                _shareContact(context, dbContact);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, color: AppColors.accentPurple, size: 20),
                    const SizedBox(width: 10),
                    Text(local.translate('edit'), style: TextStyle(color: AppColors.textPrimary(context))),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    const Icon(Icons.share_rounded, color: AppColors.accentPurple, size: 20),
                    const SizedBox(width: 10),
                    Text(local.translate('share'), style: TextStyle(color: AppColors.textPrimary(context))),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_rounded, color: AppColors.hangupRed, size: 20),
                    const SizedBox(width: 10),
                    Text(local.translate('delete'), style: const TextStyle(color: AppColors.hangupRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              
              // Profile circular initials avatar with sleek gradient background
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.getAvatarColor(dbContact.name),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.getAvatarColor(dbContact.name).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dbContact.name.isNotEmpty ? dbContact.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Contact Name
              Text(
                dbContact.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),

              // Organization/Job Badge
              if (dbContact.company.isNotEmpty || dbContact.jobTitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accentPurple.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.business_center_rounded, color: AppColors.accentPurple, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        dbContact.jobTitle.isNotEmpty && dbContact.company.isNotEmpty
                            ? '${dbContact.jobTitle} at ${dbContact.company}'
                            : (dbContact.jobTitle.isNotEmpty ? dbContact.jobTitle : dbContact.company),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),

              // Quick Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(
                    context,
                    Icons.phone_rounded,
                    'Call',
                    AppColors.callGreen,
                    () => _triggerCallFlow(context, dialerProvider, dbContact.phone, dbContact.name),
                  ),
                  _buildQuickAction(
                    context,
                    Icons.message_rounded,
                    'Message',
                    AppColors.accentPurple,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening device SMS app for ${dbContact.phone}...'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.accentPurple,
                        ),
                      );
                    },
                  ),
                  _buildQuickAction(
                    context,
                    isBlocked ? Icons.check_circle_outline_rounded : Icons.block_flipped,
                    isBlocked ? local.translate('unblock') : local.translate('block'),
                    isBlocked ? AppColors.callGreen : AppColors.hangupRed,
                    () async {
                      if (isBlocked) {
                        await dialerProvider.unblockContact(dbContact.phone);
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
                        await dialerProvider.blockContact(dbContact.phone, dbContact.name);
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
                ],
              ),

              // SECTION: PHONE NUMBERS LIST
              _buildSectionHeader(context, 'Phone Numbers'),
              Column(
                children: phonesList.map((phoneRecord) {
                  final number = phoneRecord['number'] ?? '';
                  final label = phoneRecord['label'] ?? 'MOBILE';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Row(
                        children: [
                          Text(
                            number,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildFieldBadge(context, label),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Tap to quick dial number',
                          style: TextStyle(color: AppColors.textSecondary(context).withOpacity(0.6), fontSize: 12),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone_rounded, color: AppColors.callGreen),
                            onPressed: () => _triggerCallFlow(context, dialerProvider, number, dbContact.name),
                          ),
                          IconButton(
                            icon: const Icon(Icons.message_rounded, color: AppColors.accentPurple),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Opening device SMS app for $number...'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.accentPurple,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      onTap: () => _triggerCallFlow(context, dialerProvider, number, dbContact.name),
                    ),
                  );
                }).toList(),
              ),

              // SECTION: EMAILS LIST
              if (emailsList.isNotEmpty) ...[
                _buildSectionHeader(context, 'Email Addresses'),
                Column(
                  children: emailsList.map((emailRecord) {
                    final address = emailRecord['address'] ?? '';
                    final label = emailRecord['label'] ?? 'HOME';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                address,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildFieldBadge(context, label),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Tap to write an email',
                            style: TextStyle(color: AppColors.textSecondary(context).withOpacity(0.6), fontSize: 12),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.email_outlined, color: AppColors.accentPurple),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Opening device mail app for $address...'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.accentPurple,
                              ),
                            );
                          },
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Opening device mail app for $address...'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.accentPurple,
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],

              // SECTION: ADDRESS
              if (dbContact.address.isNotEmpty) ...[
                _buildSectionHeader(context, 'Street Address'),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const Icon(Icons.map_rounded, color: AppColors.accentPurple, size: 28),
                    title: Text(
                      dbContact.address,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Tap to view address in maps',
                        style: TextStyle(color: AppColors.textSecondary(context).withOpacity(0.6), fontSize: 12),
                      ),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening maps for ${dbContact.address}...'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.accentPurple,
                        ),
                      );
                    },
                  ),
                ),
              ],

              // SECTION: NOTES
              if (dbContact.notes.isNotEmpty) ...[
                _buildSectionHeader(context, 'Notes / Nickname'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notes_rounded, color: AppColors.accentPurple.withOpacity(0.7), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Personal Note',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary(context)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Text(
                          dbContact.notes,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary(context),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // SECTION: WHATSAPP INTEGRATION
              const SizedBox(height: 8),
              _buildSectionHeader(context, 'WhatsApp Integration'),
              _buildWhatsAppButton(context, Icons.chat_bubble_outline_rounded, local.translate('whatsAppMessage'), local, dbContact.phone),
              const SizedBox(height: 10),
              _buildWhatsAppButton(context, Icons.phone_callback_rounded, local.translate('whatsAppVoiceCall'), local, dbContact.phone),
              const SizedBox(height: 10),
              _buildWhatsAppButton(context, Icons.video_call_rounded, local.translate('whatsAppVideoCall'), local, dbContact.phone),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
