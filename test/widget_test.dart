import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:callin/main.dart';
import 'package:callin/providers/theme_provider.dart';
import 'package:callin/providers/locale_provider.dart';
import 'package:callin/providers/dialer_provider.dart';

void main() {
  // Set up sqflite for ffi testing environment
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Set up shared preferences mock initial values
  SharedPreferences.setMockInitialValues({});

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => DialerProvider()),
        ],
        child: const CallinApp(onboardingComplete: false),
      ),
    );

    // Pump the transition timer of 2200ms
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();
  });
}
