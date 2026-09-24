import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scanly/App-Router.dart';
import 'package:scanly/Auth/Auth_Cubit.dart';
import 'package:scanly/Core/DocumentStorage.dart';
import 'package:scanly/Service/Firebase/firebase_options.dart';
import 'package:scanly/core/App_Theme.dart';
import 'package:scanly/core/ScanlyActivityService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // شغّل Flutter فورًا
  runApp(
    BlocProvider(
      create: (_) => AuthCubit(),
      child: const ScanlyApp(),
    ),
  );

  // initialization بعد تشغيل التطبيق
  await _initializeApp();
}

Future<void> _initializeApp() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully.');
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('$stackTrace');
  }

  await Future.wait([
    _initDocumentStorage(),
    _initActivityService(),
    _initTheme(),
    _initSupabase(),
  ]);
}

Future<void> _initDocumentStorage() async {
  try {
    await DocumentStorage.init();
    debugPrint('DocumentStorage initialized successfully.');
  } catch (e, stackTrace) {
    debugPrint('DocumentStorage initialization error: $e');
    debugPrint('$stackTrace');
  }
}

Future<void> _initActivityService() async {
  try {
    await ScanlyActivityService.init();
    debugPrint('ScanlyActivityService initialized successfully.');
  } catch (e, stackTrace) {
    debugPrint('ScanlyActivityService initialization error: $e');
    debugPrint('$stackTrace');
  }
}

Future<void> _initTheme() async {
  try {
    await ThemeController.loadTheme();
  } catch (e, stackTrace) {
    debugPrint('Theme initialization error: $e');
    debugPrint('$stackTrace');
  }
}

Future<void> _initSupabase() async {
  try {
    const supabaseUrl =
        String.fromEnvironment('SUPABASE_URL');

    const supabasePublishableKey =
        String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    );

    if (supabaseUrl.isNotEmpty &&
        supabasePublishableKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabasePublishableKey,
      );

      debugPrint(
        'Supabase initialized successfully.',
      );
    } else {
      debugPrint(
        'Supabase configuration is missing.',
      );
    }
  } catch (e, stackTrace) {
    debugPrint(
      'Supabase initialization error: $e',
    );
    debugPrint('$stackTrace');
  }
}

class ScanlyApp extends StatelessWidget {
  const ScanlyApp({super.key});

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