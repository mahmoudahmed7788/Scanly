import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scanly/App-Router.dart';
import 'package:scanly/Auth/Auth_Cubit.dart';
import 'package:scanly/Core/App_Theme.dart';
import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Service/Ads/AdService.dart';
import 'package:scanly/Service/Firebase/firebase_options.dart';
import 'package:scanly/Core/ScanlyActivityService.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ScanlyBootstrap(),
  );
}

class ScanlyBootstrap extends StatefulWidget {
  const ScanlyBootstrap({
    super.key,
  });

  @override
  State<ScanlyBootstrap> createState() =>
      _ScanlyBootstrapState();
}

class _ScanlyBootstrapState
    extends State<ScanlyBootstrap> {
  bool _backgroundStarted = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _startBackgroundServices();
      },
    );
  }

  void _startBackgroundServices() {
    if (_backgroundStarted) {
      return;
    }

    _backgroundStarted = true;

    unawaited(
      _initializeBackgroundServices(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(),
      child: const ScanlyApp(),
    );
  }
}

Future<void> _initializeBackgroundServices() async {
  unawaited(
    _initTheme(),
  );

  unawaited(
    _initDocumentStorage(),
  );

  unawaited(
    _initActivityService(),
  );

  Future<void>.delayed(
    const Duration(seconds: 1),
    () {
      unawaited(
        _initAds(),
      );
    },
  );

  Future<void>.delayed(
    const Duration(seconds: 2),
    () {
      unawaited(
        _initSupabase(),
      );
    },
  );
}

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

Future<void> _initSupabase() async {
  try {
    const supabaseUrl = String.fromEnvironment(
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

class ScanlyApp extends StatelessWidget {
  const ScanlyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (
        context,
        themeMode,
        child,
      ) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Scanly',
          theme: AppTheme.defaultTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}