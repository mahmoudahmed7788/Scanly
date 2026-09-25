import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scanly/App-Router.dart';
import 'package:scanly/Auth/Auth_Cubit.dart';
import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Core/App_Theme.dart';
import 'package:scanly/Core/ScanlyActivityService.dart';
import 'package:scanly/Service/Firebase/firebase_options.dart';
import 'package:scanly/Service/Ads/AdService.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==========================================================
  // FIREBASE
  // ==========================================================
  //
  // Firebase is initialized before runApp because AuthCubit
  // and the authentication flow may depend on it.
  //

  try {
    await Firebase.initializeApp(
      options:
          DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint(
      'Firebase initialized successfully.',
    );
  } catch (e, stackTrace) {
    debugPrint(
      'Firebase initialization error: $e',
    );

    debugPrint(
      '$stackTrace',
    );

    // Firebase is required by the application.
    rethrow;
  }

  // ==========================================================
  // START APP IMMEDIATELY
  // ==========================================================
  //
  // IMPORTANT:
  //
  // We do NOT wait for:
  //
  // - Supabase
  // - Theme
  // - DocumentStorage
  // - ScanlyActivityService
  // - Ads
  //
  // before showing the Flutter application.
  //

  runApp(
    BlocProvider(
      create: (_) => AuthCubit(),
      child: const ScanlyApp(),
    ),
  );

  // ==========================================================
  // BACKGROUND INITIALIZATION
  // ==========================================================
  //
  // Everything below starts after the UI is already running.
  //

  unawaited(
    _initializeBackgroundServices(),
  );
}

// ============================================================
// BACKGROUND INITIALIZATION
// ============================================================

Future<void> _initializeBackgroundServices() async {
  // ----------------------------------------------------------
  // 1. Supabase
  // ----------------------------------------------------------

  await _initSupabase();

  // ----------------------------------------------------------
  // 2. Theme
  // ----------------------------------------------------------

  await _initTheme();

  // ----------------------------------------------------------
  // 3. Document Storage
  // ----------------------------------------------------------

  await _initDocumentStorage();

  // ----------------------------------------------------------
  // 4. Activity Service
  // ----------------------------------------------------------

  await _initActivityService();

  // ----------------------------------------------------------
  // 5. Ads
  // ----------------------------------------------------------

  await _initAds();

  debugPrint(
    'Background initialization completed.',
  );
}

// ============================================================
// SUPABASE
// ============================================================

Future<void> _initSupabase() async {
  try {
    const supabaseUrl =
        String.fromEnvironment(
      'SUPABASE_URL',
    );

    const supabasePublishableKey =
        String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    );

    if (supabaseUrl.isEmpty ||
        supabasePublishableKey.isEmpty) {
      debugPrint(
        'Supabase configuration is missing.',
      );

      return;
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabasePublishableKey,
    );

    debugPrint(
      'Supabase initialized successfully.',
    );
  } catch (e, stackTrace) {
    debugPrint(
      'Supabase initialization error: $e',
    );

    debugPrint(
      '$stackTrace',
    );
  }
}

// ============================================================
// DOCUMENT STORAGE
// ============================================================

Future<void> _initDocumentStorage() async {
  try {
    await DocumentStorage.init();

    debugPrint(
      'DocumentStorage initialized successfully.',
    );
  } catch (e, stackTrace) {
    debugPrint(
      'DocumentStorage initialization error: $e',
    );

    debugPrint(
      '$stackTrace',
    );
  }
}

// ============================================================
// ACTIVITY SERVICE
// ============================================================

Future<void> _initActivityService() async {
  try {
    await ScanlyActivityService.init();

    debugPrint(
      'ScanlyActivityService initialized successfully.',
    );
  } catch (e, stackTrace) {
    debugPrint(
      'ScanlyActivityService initialization error: $e',
    );

    debugPrint(
      '$stackTrace',
    );
  }
}

// ============================================================
// THEME
// ============================================================

Future<void> _initTheme() async {
  try {
    await ThemeController.loadTheme();

    debugPrint(
      'Theme initialized successfully.',
    );
  } catch (e, stackTrace) {
    debugPrint(
      'Theme initialization error: $e',
    );

    debugPrint(
      '$stackTrace',
    );
  }
}

// ============================================================
// ADS
// ============================================================

Future<void> _initAds() async {
  try {
    await AdService.initialize();

    debugPrint(
      'AdService initialized successfully.',
    );
  } catch (e, stackTrace) {
    debugPrint(
      'AdService initialization error: $e',
    );

    debugPrint(
      '$stackTrace',
    );
  }
}

// ============================================================
// APP
// ============================================================

class ScanlyApp extends StatelessWidget {
  const ScanlyApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable:
          ThemeController.mode,
      builder: (
        context,
        themeMode,
        child,
      ) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,

          title: 'Scanly',

          theme:
              AppTheme.defaultTheme,

          darkTheme:
              AppTheme.darkTheme,

          themeMode:
              themeMode,

          routerConfig:
              AppRouter.router,
        );
      },
    );
  }
}