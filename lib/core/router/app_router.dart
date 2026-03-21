import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../injection/service_locator.dart';
import '/../core/constants/app_constants.dart';
import '/../presentation/blocs/notifications_bloc.dart';
import '/../presentation/blocs/trip_detail_bloc.dart';
import '/../presentation/pages/splash/splash_page.dart';
import '/../presentation/pages/auth/login_page.dart';
import '/../presentation/pages/auth/register_page.dart';
import '/../presentation/pages/auth/forgot_password_page.dart';
import '../../presentation/pages/notification_page.dart';
import '../../presentation/pages/passenger/trip_detail_page.dart';
import '../../presentation/widgets/main_shell.dart';

class AppRouter {
  // ❌ No longer a static field
  // static final GoRouter router = GoRouter(...);

  // ✅ A factory method called after setupServiceLocator() completes
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const MainShell(),
        ),
        GoRoute(
          path: '${AppRoutes.tripDetail}/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return BlocProvider(
              create: (_) => sl<TripDetailBloc>(),
              child: TripDetailPage(rideId: id),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<NotificationsBloc>(),
            child: const NotificationsPage(),
          ),
        ),
      ],
    );
  }
}
