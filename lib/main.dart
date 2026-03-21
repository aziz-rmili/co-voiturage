import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'firebase_option.dart';
import 'injection/service_locator.dart';
import 'presentation/blocs/auth_bloc.dart';
import 'presentation/blocs/home_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await setupServiceLocator();
    debugPrint('✅ setupServiceLocator done');
    debugPrint('✅ AuthBloc registered: ${sl.isRegistered<AuthBloc>()}');
    debugPrint('✅ HomeBloc registered: ${sl.isRegistered<HomeBloc>()}');
  } catch (e, stack) {
    debugPrint('❌ setupServiceLocator threw: $e');
    debugPrint(stack.toString());
    rethrow;
  }

  final router = AppRouter.createRouter();
  runApp(RideLeafApp(router: router));
}

class RideLeafApp extends StatelessWidget {
  final GoRouter router;
  const RideLeafApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>(),
      child: MaterialApp.router(
        title: 'RideLeaf',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E4D35),
            brightness: Brightness.light,
          ),
          fontFamily: 'SF Pro Display',
        ),
        routerConfig: router,
      ),
    );
  }
}
