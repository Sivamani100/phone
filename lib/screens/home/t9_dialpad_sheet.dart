import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dialer_provider.dart';
import '../../providers/locale_provider.dart';
import '../../utils/colors.dart';
import '../../utils/localization.dart';
import '../contacts/add_contact.dart';

class T9DialpadSheet extends StatelessWidget {
  const T9DialpadSheet({super.key});

  Widget _buildDialKey(
    BuildContext context,
    String digit,
    String subText,
    VoidCallback onTap, {
    VoidCallback? onLongPress,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard(context),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border(context), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              digit,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            if (subText.isNotEmpty)
              Text(
                subText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(context).withOpacity(0.7),
                  letterSpacing: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _triggerCallFlow(BuildContext context, DialerProvider provider, String phone, String name) {
    provider.handleCallAction(context, phone, name);
  }

  @override
  Widget build(BuildContext context) {
    final dialerProvider = Provider.of<DialerProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final local = AppLocalization(localeProvider.locale);

    final showActions = dialerProvider.dialerInput.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppColors.border(context), width: 1.5),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.textSecondary(context).withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),

          // T9 Search Results List (Dynamic height)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            constraints: BoxConstraints(
              maxHeight: dialerProvider.dialerInput.isEmpty ? 0 : 160,
            ),
            child: dialerProvider.dialerInput.isEmpty
                ? const SizedBox.shrink()
                : dialerProvider.t9SearchResults.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            local.translate('noContacts'),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(context); // Dismiss sheet
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddContact(initialPhone: dialerProvider.dialerInput),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentPurple),
                            label: Text(
                              local.translate('addContact'),
                              style: const TextStyle(color: AppColors.accentPurple, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: dialerProvider.t9SearchResults.length,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemBuilder: (context, index) {
                          final contact = dialerProvider.t9SearchResults[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.getAvatarColor(contact.name),
                              child: Text(
                                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              contact.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            subtitle: Text(
                              contact.phone,
                              style: TextStyle(color: AppColors.textSecondary(context)),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.callGreen),
                              onPressed: () {
                                Navigator.pop(context); // Dismiss sheet
                                _triggerCallFlow(context, dialerProvider, contact.phone, contact.name);
                              },
                            ),
                            onTap: () {
                              Navigator.pop(context); // Dismiss sheet
                              _triggerCallFlow(context, dialerProvider, contact.phone, contact.name);
                            },
                          );
                        },
                      ),
          ),

          if (dialerProvider.dialerInput.isNotEmpty) const Divider(height: 1),

          // Dialed Number Display Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            height: 64,
            alignment: Alignment.center,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(
                dialerProvider.dialerInput,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          // Keypad Layout Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDialKey(context, '1', '', () => dialerProvider.addDialerDigit('1')),
                    _buildDialKey(context, '2', 'ABC', () => dialerProvider.addDialerDigit('2')),
                    _buildDialKey(context, '3', 'DEF', () => dialerProvider.addDialerDigit('3')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDialKey(context, '4', 'GHI', () => dialerProvider.addDialerDigit('4')),
                    _buildDialKey(context, '5', 'JKL', () => dialerProvider.addDialerDigit('5')),
                    _buildDialKey(context, '6', 'MNO', () => dialerProvider.addDialerDigit('6')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDialKey(context, '7', 'PQRS', () => dialerProvider.addDialerDigit('7')),
                    _buildDialKey(context, '8', 'TUV', () => dialerProvider.addDialerDigit('8')),
                    _buildDialKey(context, '9', 'WXYZ', () => dialerProvider.addDialerDigit('9')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDialKey(context, '*', '', () => dialerProvider.addDialerDigit('*')),
                    _buildDialKey(
                      context,
                      '0',
                      '+',
                      () => dialerProvider.addDialerDigit('0'),
                      onLongPress: () => dialerProvider.addDialerDigit('+'),
                    ),
                    _buildDialKey(context, '#', '', () => dialerProvider.addDialerDigit('#')),
                  ],
                ),
                const SizedBox(height: 20),

                // Control Action Row (Add, Call, Delete)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Plus Add Icon
                    SizedBox(
                      width: 70,
                      child: showActions
                          ? IconButton(
                              icon: const Icon(Icons.person_add_alt_1_rounded, size: 28, color: AppColors.accentPurple),
                              onPressed: () {
                                Navigator.pop(context); // Dismiss sheet
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddContact(initialPhone: dialerProvider.dialerInput),
                                  ),
                                );
                              },
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Centered Call Action
                    GestureDetector(
                      onTap: () {
                        if (dialerProvider.dialerInput.isNotEmpty) {
                          Navigator.pop(context); // Dismiss sheet
                          _triggerCallFlow(context, dialerProvider, dialerProvider.dialerInput, '');
                        }
                      },
                      child: Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: dialerProvider.dialerInput.isEmpty
                                ? [Colors.grey.shade400, Colors.grey.shade500]
                                : [AppColors.callGreen, const Color(0xFF15803D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: dialerProvider.dialerInput.isEmpty
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.callGreen.withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                        ),
                        child: const Icon(
                          Icons.phone_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),

                    // Backspace Clear
                    SizedBox(
                      width: 70,
                      child: showActions
                          ? GestureDetector(
                              onTap: () => dialerProvider.removeLastDialerDigit(),
                              onLongPress: () => dialerProvider.clearDialerInput(),
                              child: Icon(
                                Icons.backspace_rounded,
                                size: 24,
                                color: AppColors.textSecondary(context),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
