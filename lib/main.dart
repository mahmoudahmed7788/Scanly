import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:scanly/App-Router.dart';
import 'package:scanly/Auth_Cubit.dart';
import 'package:scanly/DocumentModel.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    BlocProvider(
      create: (_) => AuthCubit(),
      child: const ScanlyApp(),
    ),
  );

  DocumentStorage.init();
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