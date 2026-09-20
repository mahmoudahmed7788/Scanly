import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scanly/App-Router.dart';
import 'package:scanly/App_Theme.dart';
import 'package:scanly/Auth_Cubit.dart';
import 'package:scanly/DocumentModel.dart';
import 'package:scanly/ScanlyActivityService.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ScanlyBootstrap());
}

class ScanlyBootstrap extends StatefulWidget {
  const ScanlyBootstrap({super.key});

  @override
  State<ScanlyBootstrap> createState() => _ScanlyBootstrapState();
}

class _ScanlyBootstrapState extends State<ScanlyBootstrap> {
  bool initialized = false;

  @override
  void initState() {
    super.initState();
    initializeApp();
  }

  Future<void> initializeApp() async {
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

    if (!mounted) return;

    setState(() {
      initialized = true;
    });
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
      debugPrint('Theme initialized successfully.');
    } catch (e, stackTrace) {
      debugPrint('Theme initialization error: $e');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _initSupabase() async {
    try {
      const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
      const supabasePublishableKey =
          String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

      if (supabaseUrl.isNotEmpty &&
          supabasePublishableKey.isNotEmpty) {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabasePublishableKey,
        );

        debugPrint('Supabase initialized successfully.');
      } else {
        debugPrint('Supabase configuration is missing.');
      }
    } catch (e, stackTrace) {
      debugPrint('Supabase initialization error: $e');
      debugPrint('$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: SizedBox.expand(
            child: Image(
              image: AssetImage(
                'assets/images/Launch_Page.png',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => AuthCubit(),
      child: const ScanlyApp(),
    );
  }
}

class ScanlyApp extends StatelessWidget {
  const ScanlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, themeMode, child) {
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
