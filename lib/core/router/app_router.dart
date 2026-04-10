import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/widgets/widgets.dart';
import '../constants/app_constants.dart';
import '../../injection/service_locator.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/ride_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../presentation/blocs/blocs.dart';
import '../../presentation/pages/admin/admin_trip_history_page.dart';
import '../../presentation/pages/admin/admin_user_public_info_page.dart';
import '../../presentation/pages/pages.dart';

class AppRouter {
  static AuthBloc? _authBloc;
  static AuthBloc get _auth {
    _authBloc ??= sl<AuthBloc>();
    return _authBloc!;
  }

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (c, s) => BlocProvider.value(
          value: _auth..add(const AuthStarted()),
          child: const SplashPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (c, s) =>
            BlocProvider.value(value: _auth, child: const LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (c, s) =>
            BlocProvider.value(value: _auth, child: const RegisterPage()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (c, s) =>
            BlocProvider.value(value: _auth, child: const ForgotPasswordPage()),
      ),

      GoRoute(
        path: AppRoutes.home,
        builder: (c, s) =>
            BlocProvider.value(value: _auth, child: const MainShell()),
      ),

      GoRoute(
        path: AppRoutes.allRides,
        builder: (c, s) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _auth),
            BlocProvider(create: (_) => sl<HomeBloc>()),
          ],
          child: const AllRidesPage(),
        ),
      ),

      // ── Create Ride — provides RideRepository + AuthBloc
      GoRoute(
        path: AppRoutes.createRide,
        builder: (c, s) => MultiBlocProvider(
          providers: [BlocProvider.value(value: _auth)],
          child: RepositoryProvider.value(
            value: sl<RideRepository>(),
            child: const CreateRidePage(),
          ),
        ),
      ),

      GoRoute(
        path: '${AppRoutes.tripDetail}/:id',
        builder: (c, s) {
          final rideId = s.pathParameters['id'] ?? '';
          return MultiBlocProvider(
            providers: [
              BlocProvider.value(value: _auth),
              BlocProvider(create: (_) => sl<TripDetailBloc>()),
            ],
            child: TripDetailPage(rideId: rideId),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.chat,
        builder: (c, s) {
          final extra = s.extra as Map<String, dynamic>? ?? {};
          return BlocProvider(
            create: (_) => sl<MessagesBloc>(),
            child: ChatPage(
              currentUserId: extra['currentUserId'] as String? ?? '',
              otherUserId: extra['otherUserId'] as String? ?? '',
              otherUserName: extra['otherUserName'] as String?,
              rideId: extra['rideId'] as String?,
              conversationId: extra['conversationId'] as String?,
            ),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.notifications,
        builder: (c, s) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _auth),
            BlocProvider(create: (_) => sl<NotificationsBloc>()),
          ],
          child: const NotificationsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (c, s) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _auth),
            BlocProvider(create: (_) => sl<AdminBloc>()),
          ],
          child: const AdminDashboardPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminTrips,
        builder: (c, s) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _auth),
            BlocProvider(
              create: (_) => sl<AdminBloc>()..add(const AdminStarted()),
            ),
          ],
          child: const AdminTripHistoryPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminUserInfo,
        builder: (c, s) {
          final user = s.extra as AppUser;
          return AdminUserPublicInfoPage(user: user);
        },
      ),
      GoRoute(
        path: AppRoutes.ridePreferences,
        builder: (c, s) => MultiBlocProvider(
          providers: [BlocProvider.value(value: _auth)],
          child: RepositoryProvider.value(
            value: sl<UserRepository>(),
            child: const RidePreferencesPage(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.vehicleDetails,
        builder: (c, s) => MultiBlocProvider(
          providers: [BlocProvider.value(value: _auth)],
          child: RepositoryProvider.value(
            value: sl<UserRepository>(),
            child: const EditVehiclePage(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.personalInfo,
        builder: (c, s) {
          final user = s.extra as AppUser;
          return RepositoryProvider.value(
            value: sl<UserRepository>(),
            child: PersonalInfoPage(user: user),
          );
        },
      ),
    ],
  );
}
