import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dialer_provider.dart';
import '../../providers/locale_provider.dart';
import '../../utils/colors.dart';
import '../../utils/localization.dart';
import 'contact_details.dart';
import 'add_contact.dart';

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerCallFlow(BuildContext context, DialerProvider provider, String phone, String name) {
    provider.handleCallAction(context, phone, name);
  }

  @override
  Widget build(BuildContext context) {
    final dialerProvider = Provider.of<DialerProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final local = AppLocalization(localeProvider.locale);

    final filteredContacts = dialerProvider.getFilteredContacts();

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          local.translate('contacts'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // Elegant Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => dialerProvider.setContactSearchQuery(val),
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
                          dialerProvider.setContactSearchQuery('');
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

          // Contacts Display List
          Expanded(
            child: filteredContacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 64,
                          color: AppColors.textSecondary(context).withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          local.translate('noContacts'),
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
                    itemCount: filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];
                      final firstLetter = contact.name.isNotEmpty 
                          ? contact.name[0].toUpperCase() 
                          : '?';

                      // Alphabet Header grouping separator logic
                      bool showHeader = false;
                      if (index == 0) {
                        showHeader = true;
                      } else {
                        final prevContact = filteredContacts[index - 1];
                        final prevLetter = prevContact.name.isNotEmpty 
                            ? prevContact.name[0].toUpperCase() 
                            : '?';
                        if (firstLetter != prevLetter) {
                          showHeader = true;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader)
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0, top: 12.0, bottom: 6.0),
                              child: Text(
                                firstLetter,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentPurple,
                                ),
                              ),
                            ),
                          ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.getAvatarColor(contact.name),
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
                                firstLetter,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            title: Text(
                              contact.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            subtitle: Text(
                              contact.phone,
                              style: TextStyle(
                                color: AppColors.textSecondary(context),
                                fontSize: 13,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    contact.isFavorite
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: contact.isFavorite
                                        ? AppColors.starGold
                                        : AppColors.textSecondary(context).withOpacity(0.4),
                                    size: 24,
                                  ),
                                  onPressed: () async {
                                    await dialerProvider.toggleFavoriteContact(
                                      contact.id ?? 0,
                                      contact.isFavorite,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).clearSnackBars();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            contact.isFavorite
                                                ? 'Removed ${contact.name} from favorites'
                                                : 'Added ${contact.name} to favorites',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          backgroundColor: contact.isFavorite
                                              ? AppColors.accentPink
                                              : AppColors.accentPurple,
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.phone_rounded, color: AppColors.callGreen),
                                  onPressed: () => _triggerCallFlow(context, dialerProvider, contact.phone, contact.name),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ContactDetails(contact: contact),
                                ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddContact()),
          );
        },
        backgroundColor: AppColors.accentPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }
}
