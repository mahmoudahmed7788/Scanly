import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:scanly/App-Router.dart';
import 'package:scanly/Auth_Cubit.dart';
import 'package:scanly/DocumentModel.dart';

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

      await DocumentStorage.init();

      if (!mounted) return;

      setState(() {
        initialized = true;
      });
    } catch (e) {
      debugPrint('Initialization error: $e');

      if (!mounted) return;

      setState(() {
        initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF6750A4),
          body: SizedBox.expand(),
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
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Scanly',
      routerConfig: AppRouter.router,
    );
  }
}