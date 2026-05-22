import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact_model.dart';
import '../../providers/dialer_provider.dart';
import '../../providers/locale_provider.dart';
import '../../utils/colors.dart';
import '../../utils/localization.dart';

class AddContact extends StatefulWidget {
  final String? initialPhone;
  final ContactModel? contactToEdit;

  const AddContact({
    super.key,
    this.initialPhone,
    this.contactToEdit,
  });

  @override
  State<AddContact> createState() => _AddContactState();
}

class _AddContactState extends State<AddContact> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _jobTitleController;
  late TextEditingController _notesController;
  late TextEditingController _addressController;

  List<Map<String, String>> _phones = [];
  List<Map<String, String>> _emails = [];

  final List<TextEditingController> _phoneControllers = [];
  final List<TextEditingController> _emailControllers = [];

  final List<String> _phoneLabels = ['MOBILE', 'HOME', 'WORK', 'MAIN', 'OTHER'];
  final List<String> _emailLabels = ['HOME', 'WORK', 'OTHER'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.contactToEdit?.name ?? '',
    );
    _companyController = TextEditingController(
      text: widget.contactToEdit?.company ?? '',
    );
    _jobTitleController = TextEditingController(
      text: widget.contactToEdit?.jobTitle ?? '',
    );
    _notesController = TextEditingController(
      text: widget.contactToEdit?.notes ?? '',
    );
    _addressController = TextEditingController(
      text: widget.contactToEdit?.address ?? '',
    );

    if (widget.contactToEdit != null) {
      _phones = List.from(widget.contactToEdit!.phones);
      _emails = List.from(widget.contactToEdit!.emails);
      
      if (_phones.isEmpty && widget.contactToEdit!.phone.isNotEmpty) {
        _phones.add({'number': widget.contactToEdit!.phone, 'label': 'MOBILE'});
      }
      if (_emails.isEmpty && widget.contactToEdit!.email.isNotEmpty) {
        _emails.add({'address': widget.contactToEdit!.email, 'label': 'HOME'});
      }
    } else {
      _phones.add({
        'number': widget.initialPhone ?? '',
        'label': 'MOBILE',
      });
      _emails.add({
        'address': '',
        'label': 'HOME',
      });
    }

    for (var phone in _phones) {
      _phoneControllers.add(TextEditingController(text: phone['number']));
    }
    for (var email in _emails) {
      _emailControllers.add(TextEditingController(text: email['address']));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _notesController.dispose();
    _addressController.dispose();
    for (var ctrl in _phoneControllers) {
      ctrl.dispose();
    }
    for (var ctrl in _emailControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _addPhoneField() {
    setState(() {
      _phones.add({'number': '', 'label': 'MOBILE'});
      _phoneControllers.add(TextEditingController());
    });
  }

  void _removePhoneField(int index) {
    setState(() {
      _phones.removeAt(index);
      _phoneControllers[index].dispose();
      _phoneControllers.removeAt(index);
    });
  }

  void _addEmailField() {
    setState(() {
      _emails.add({'address': '', 'label': 'HOME'});
      _emailControllers.add(TextEditingController());
    });
  }

  void _removeEmailField(int index) {
    setState(() {
      _emails.removeAt(index);
      _emailControllers[index].dispose();
      _emailControllers.removeAt(index);
    });
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentPurple, size: 20),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary(context),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: AppColors.textPrimary(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary(context).withOpacity(0.8), fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.accentPurple.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: AppColors.surface(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border(context), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border(context), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accentPurple, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dialerProvider = Provider.of<DialerProvider>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final local = AppLocalization(localeProvider.locale);

    final isEditMode = widget.contactToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditMode ? local.translate('edit') : local.translate('addContact'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Form(
            key: _formKey,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: 16),
                
                // Static Avatar Placeholder Display
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentPurple,
                          AppColors.accentPurple.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPurple.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // SECTION 1: PERSONAL INFO
                _buildSectionHeader(context, 'Personal Details', Icons.person_outline_rounded),
                _buildCardContainer(context, [
                  _buildTextField(
                    context: context,
                    controller: _nameController,
                    label: local.translate('nameLabel'),
                    icon: Icons.person_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    context: context,
                    controller: _companyController,
                    label: 'Company / Organization',
                    icon: Icons.business_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    context: context,
                    controller: _jobTitleController,
                    label: 'Job Title',
                    icon: Icons.work_outline_rounded,
                  ),
                ]),

                // SECTION 2: PHONE NUMBERS
                _buildSectionHeader(context, 'Phone Numbers', Icons.phone_android_rounded),
                _buildCardContainer(context, [
                  ...List.generate(_phones.length, (index) {
                    final phoneCtrl = _phoneControllers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          // Dropdown for label
                          Container(
                            width: 100,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _phoneLabels.contains(_phones[index]['label'])
                                    ? _phones[index]['label']
                                    : 'MOBILE',
                                style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13, fontWeight: FontWeight.bold),
                                dropdownColor: AppColors.surface(context),
                                borderRadius: BorderRadius.circular(16),
                                items: _phoneLabels.map((lbl) {
                                  return DropdownMenuItem<String>(
                                    value: lbl,
                                    child: Text(lbl),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _phones[index]['label'] = val!;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Number field
                          Expanded(
                            child: TextFormField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15),
                              onChanged: (val) => _phones[index]['number'] = val.trim(),
                              validator: (value) {
                                if (index == 0 && (value == null || value.trim().isEmpty)) {
                                  return 'First phone number is required';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'Phone number',
                                hintStyle: TextStyle(color: AppColors.textSecondary(context).withOpacity(0.5)),
                                filled: true,
                                fillColor: AppColors.surface(context),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: AppColors.border(context)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: AppColors.border(context)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.accentPurple, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          if (_phones.length > 1) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.hangupRed),
                              onPressed: () => _removePhoneField(index),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  // Add phone button
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.accentPurple),
                    onPressed: _addPhoneField,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Add Phone Number', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ]),

                // SECTION 3: EMAIL ADDRESSES
                _buildSectionHeader(context, 'Email Addresses', Icons.email_outlined),
                _buildCardContainer(context, [
                  ...List.generate(_emails.length, (index) {
                    final emailCtrl = _emailControllers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          // Dropdown for label
                          Container(
                            width: 100,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _emailLabels.contains(_emails[index]['label'])
                                    ? _emails[index]['label']
                                    : 'HOME',
                                style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13, fontWeight: FontWeight.bold),
                                dropdownColor: AppColors.surface(context),
                                borderRadius: BorderRadius.circular(16),
                                items: _emailLabels.map((lbl) {
                                  return DropdownMenuItem<String>(
                                    value: lbl,
                                    child: Text(lbl),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _emails[index]['label'] = val!;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Email field
                          Expanded(
                            child: TextFormField(
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15),
                              onChanged: (val) => _emails[index]['address'] = val.trim(),
                              decoration: InputDecoration(
                                hintText: 'Email address',
                                hintStyle: TextStyle(color: AppColors.textSecondary(context).withOpacity(0.5)),
                                filled: true,
                                fillColor: AppColors.surface(context),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: AppColors.border(context)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: AppColors.border(context)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.accentPurple, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          if (_emails.length > 1) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.hangupRed),
                              onPressed: () => _removeEmailField(index),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  // Add email button
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.accentPurple),
                    onPressed: _addEmailField,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Add Email Address', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ]),

                // SECTION 4: MORE DETAILS
                _buildSectionHeader(context, 'Additional Details', Icons.add_to_photos_outlined),
                _buildCardContainer(context, [
                  _buildTextField(
                    context: context,
                    controller: _addressController,
                    label: 'Street Address',
                    icon: Icons.map_rounded,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    context: context,
                    controller: _notesController,
                    label: 'Notes / Nickname',
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                ]),

                const SizedBox(height: 36),

                // Save Action Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final name = _nameController.text.trim();
                        final company = _companyController.text.trim();
                        final jobTitle = _jobTitleController.text.trim();
                        final notes = _notesController.text.trim();
                        final address = _addressController.text.trim();

                        // Sync dynamic controllers to maps
                        for (int i = 0; i < _phones.length; i++) {
                          _phones[i]['number'] = _phoneControllers[i].text.trim();
                        }
                        for (int i = 0; i < _emails.length; i++) {
                          _emails[i]['address'] = _emailControllers[i].text.trim();
                        }

                        // Filter empty entries
                        final activePhones = _phones.where((p) => p['number']!.isNotEmpty).toList();
                        final activeEmails = _emails.where((e) => e['address']!.isNotEmpty).toList();

                        if (activePhones.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('At least one phone number is required'),
                              backgroundColor: AppColors.hangupRed,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        final String primaryPhone = activePhones.first['number']!;
                        final String primaryEmail = activeEmails.isNotEmpty ? activeEmails.first['address']! : '';

                        if (isEditMode) {
                          final updatedContact = widget.contactToEdit!.copyWith(
                            name: name,
                            phone: primaryPhone,
                            email: primaryEmail,
                            phones: activePhones,
                            emails: activeEmails,
                            company: company,
                            jobTitle: jobTitle,
                            notes: notes,
                            address: address,
                          );
                          await dialerProvider.updateContact(updatedContact);
                        } else {
                          await dialerProvider.addContact(
                            name,
                            primaryPhone,
                            primaryEmail,
                            phones: activePhones,
                            emails: activeEmails,
                            company: company,
                            jobTitle: jobTitle,
                            notes: notes,
                            address: address,
                          );
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditMode
                                    ? 'Contact updated successfully!'
                                    : 'Contact created successfully!',
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.callGreen,
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      local.translate('save'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

