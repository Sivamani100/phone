import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dialer_provider.dart';
import '../../providers/locale_provider.dart';
import '../../utils/colors.dart';
import '../../utils/localization.dart';
import 'permission_setup.dart';

class LanguageSetup extends StatefulWidget {
  final bool isOnboarding;
  const LanguageSetup({super.key, this.isOnboarding = false});

  @override
  State<LanguageSetup> createState() => _LanguageSetupState();
}

class _LanguageSetupState extends State<LanguageSetup> {
  String _selectedLangCode = 'en';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      setState(() {
        _selectedLangCode = localeProvider.locale.languageCode;
      });
    });
  }

  Widget _buildLanguageCard(
    BuildContext context,
    String langName,
    String nativeName,
    String langCode,
    String flag,
  ) {
    final isSelected = _selectedLangCode == langCode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLangCode = langCode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.accentPurple.withOpacity(0.08) 
              : AppColors.surfaceCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accentPurple : AppColors.border(context),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentPurple.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                flag,
                style: const TextStyle(fontSize: 26),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    langName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: langCode,
              groupValue: _selectedLangCode,
              activeColor: AppColors.accentPurple,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedLangCode = val;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockAdBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.only(top: 10, bottom: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warningOrange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AD',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              'Google AdMob Mock Banner Active',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary(context).withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final dialerProvider = Provider.of<DialerProvider>(context);
    final local = AppLocalization(localeProvider.locale);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isOnboarding
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary(context)),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          local.translate('selectLanguage'),
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildLanguageCard(context, 'English', 'English (Default)', 'en', '🇺🇸'),
                    _buildLanguageCard(context, 'Hindi', 'हिंदी (Hindi)', 'hi', '🇮🇳'),
                    _buildLanguageCard(context, 'Portuguese', 'Português (Portuguese)', 'pt', '🇵🇹'),
                  ],
                ),
              ),
              _buildMockAdBanner(context),
              const SizedBox(height: 12),
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
                    // Update Language
                    await localeProvider.setLocale(Locale(_selectedLangCode));

                    if (widget.isOnboarding) {
                      await dialerProvider.setLanguageSeen();
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const PermissionSetup()),
                        );
                      }
                    } else {
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _selectedLangCode == 'en'
                                  ? 'Language updated successfully!'
                                  : _selectedLangCode == 'hi'
                                      ? 'भाषा सफलतापूर्वक सहेज ली गई है!'
                                      : 'Idioma atualizado com sucesso!',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.accentPurple,
                          ),
                        );
                      }
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.isOnboarding ? local.translate('continueBtn') : local.translate('save'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.isOnboarding) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
