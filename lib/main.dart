import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siade2/l10n/app_localizations.dart';
import 'package:siade2/src/features/splash/pages/pages.dart';
import 'package:siade2/src/providers/providers.dart';
import 'package:siade2/src/theme/theme.dart';
// sizer used in MyApp via Sizer widget
import 'package:sizer/sizer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ignore: unused_import
import 'package:siade2/src/commons/services/api_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:siade2/src/core/local/connectivity_service.dart';
import 'package:siade2/src/core/local/local_database.dart';
import 'package:siade2/src/core/local/sync_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:siade2/firebase_options.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:siade2/src/core/services/asset_optimization_service.dart';
import 'package:siade2/src/core/services/notification_service.dart';
import 'package:siade2/src/core/services/app_logger.dart';
import 'package:siade2/src/core/services/moderation_service.dart';
import 'package:siade2/src/core/services/background_task_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔥 Initialiser Firebase Crashlytics (checklist point 9)
  // En prod : tous les crashs Flutter + Dart sont capturés automatiquement
  if (!kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }
  // Capturer les erreurs Flutter non gérées (widget build errors, etc.)
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Capturer les erreurs dans les isolates / zones async
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // 🔔 Initialiser les notifications push (FCM) — non-bloquant
  NotificationService().init().catchError((e) {
    debugPrint('❌ [NotificationService] init() failed: $e');
  });

  // 🚀 Configurer les limites du cache d'images pour optimiser les performances
  AssetOptimizationService().configureCacheLimits();

  // 💾 Initialiser la BDD locale au démarrage
  await LocalDatabase().database;

  // 🛡️ Charger les blocages et les contenus signalés avant le premier écran,
  // pour qu'aucun contenu masqué n'apparaisse même brièvement.
  await ModerationService().charger();

  // 🔋 Initialiser WorkManager (checklist point 12 — Xiaomi/Tecno/Infinix)
  await BackgroundTaskService().init();
  await BackgroundTaskService().schedulePeriodic();

  // 🌐 Lancer la sync si une connexion est disponible au démarrage
  final connectivity = ConnectivityService();
  final isOnline = await connectivity.checkNow();
  if (isOnline) {
    SyncService().syncNow();
  } else {
    AppLogger().warning('Démarrage hors-ligne — sync différée', tag: 'App');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        // ConnectivityService partagé entre UserProvider et l'UI
        ChangeNotifierProvider<ConnectivityService>(
          create: (_) => connectivity,
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

final _navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.setNavigatorKey(_navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return Sizer(
          builder: (context, _, _) {
            return MaterialApp(
              navigatorKey: _navigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'SIADE 2',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              locale: localeProvider.locale,
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: [Locale('fr'), Locale('en')],
              home: RocketSplashScreen(),
            );
          },
        );
      },
    );
  }
}
