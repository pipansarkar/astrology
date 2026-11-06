import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'astro/ephemeris.dart';
import 'backend/supabase_config.dart';
import 'charts/chart_style_setting.dart';
import 'l10n/l10n.dart';
import 'notifications/push_service.dart';
import 'settings/place_setting.dart';
import 'screens/astrologer_desk_screen.dart';
import 'screens/home_screen.dart';
import 'screens/horoscope_screen.dart';
import 'screens/questions_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Copies the ephemeris files to app storage on first launch.
  await Future.wait([
    Ephemeris.init(),
    initBackend(),
    ChartStyleSetting.load(),
    PlaceSetting.load(),
    LanguageSetting.load(),
  ]);

  PushService.onOpen = (target) {
    final screen = switch (target) {
      PushTarget.myQuestions => const QuestionsScreen(),
      PushTarget.astrologerDesk => const AstrologerDeskScreen(),
      PushTarget.horoscope => const HoroscopeScreen(),
    };
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => screen));
  };
  PushService.onForeground = (title, body) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(body.isEmpty ? title : '$title: $body')),
    );
  };
  await PushService.init();

  runApp(const AstrologyApp());
}

class AstrologyApp extends StatelessWidget {
  const AstrologyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4A2C82); // deep indigo
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageSetting.notifier,
      builder: (context, lang, _) => MaterialApp(
        // Rebuild everything when the language changes.
        key: ValueKey(lang),
        title: 'Astrology',
        locale: Locale(lang.name),
        supportedLocales: const [Locale('en'), Locale('bn'), Locale('hi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: messengerKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: seed),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: seed,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
