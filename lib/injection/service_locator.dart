import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/datasources/datasources.dart';
import '../data/repositories/repositories_impl.dart';
import '../domain/repositories/repositories.dart';
import '../presentation/blocs/blocs.dart';
import '../services/seeding_service.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ── Firebase externals
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseDatabase>(
    () => FirebaseDatabase.instanceFor(
      app: sl<FirebaseAuth>().app,
      databaseURL:
          'https://devmob-covoitlocal-55dbc-default-rtdb.europe-west1.firebasedatabase.app',
    ),
  );
  sl.registerLazySingleton<GoogleSignIn>(
    () => GoogleSignIn(scopes: ['email', 'profile']),
  );

  // ── Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
      googleSignIn: sl(),
    ),
  );
  sl.registerLazySingleton<RideRemoteDataSource>(
    () => RideRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<MessageRemoteDataSource>(
    () => MessageRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<MapRemoteDataSource>(
    () => MapRemoteDataSourceImpl(
      realtimeDb: sl(),
      orsApiKey: const String.fromEnvironment(
        'ORS_API_KEY',
        defaultValue: 'YOUR_ORS_API_KEY_HERE',
      ),
    ),
  );

  // ── Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<RideRepository>(
    () => RideRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(remote: sl()),
  );
  sl.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryImpl(remote: sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remote: sl()),
  );
  sl.registerLazySingleton<MapRepository>(
    () => MapRepositoryImpl(remote: sl()),
  );

  // ── Services
  sl.registerLazySingleton<SeedingService>(
    () => SeedingService(firestore: sl(), realtimeDb: sl()),
  );

  // ── BLoCs (factory = fresh instance per route)
  sl.registerFactory<AuthBloc>(() => AuthBloc(authRepository: sl()));
  sl.registerFactory<HomeBloc>(
    () => HomeBloc(rideRepository: sl(), userRepository: sl()),
  );
  sl.registerFactory<TripsBloc>(() => TripsBloc(rideRepository: sl()));
  sl.registerFactory<TripDetailBloc>(
    () => TripDetailBloc(rideRepository: sl(), userRepository: sl()),
  );
  sl.registerFactory<MapBloc>(
    () => MapBloc(
      mapRepository: sl(),
      rideRepository: sl(),
      userRepository: sl(),
    ),
  );
  sl.registerFactory<MessagesBloc>(() => MessagesBloc(messageRepository: sl()));
  sl.registerFactory<NotificationsBloc>(
    () => NotificationsBloc(notificationRepository: sl()),
  );
  sl.registerFactory<ProfileBloc>(() => ProfileBloc(authRepository: sl()));
  sl.registerFactory<AdminBloc>(
    () => AdminBloc(userRepository: sl(), rideRepository: sl()),
  );
}
