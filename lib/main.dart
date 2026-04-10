import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Initialization
  // Note: For Android/iOS, you must add your google-services.json/GoogleService-Info.plist
  // and potentially run `flutterfire configure` to generate firebase_options.dart.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Localization
  await EasyLocalization.ensureInitialized();

  // Initialize Hive for offline support
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('cache');

  runApp(
    EasyLocalization(
      path: 'assets/translations',
      supportedLocales: const [Locale('en'), Locale('te')],
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: const ProviderScope(
        child: KisanSaathiApp(),
      ),
    ),
  );
}

class KisanSaathiApp extends ConsumerWidget {
  const KisanSaathiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Kisan Saathi AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
