import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/datasources/auth_remote_datasource.dart';
import '../data/datasources/map_remote_datasource.dart';
import '../data/datasources/message_remote_datasource.dart';
import '../data/datasources/notification_remote_datasource.dart';
import '../data/datasources/ride_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/message_repository_impl.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../data/repositories/map_repository_impl.dart';
import '../data/repositories/ride_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/map_repository.dart';
import '../domain/repositories/message_repository.dart';
import '../domain/repositories/notification_repository.dart';
import '../domain/repositories/ride_repository.dart';
import '../presentation/blocs/auth_bloc.dart';
import '../presentation/blocs/home_bloc.dart';
import '../presentation/blocs/map_bloc.dart';
import '../presentation/blocs/messages_bloc.dart';
import '../presentation/blocs/notifications_bloc.dart';
import '../presentation/blocs/profile_bloc.dart';
import '../presentation/blocs/trip_detail_bloc.dart';
import '../presentation/blocs/trips_bloc.dart';
import '../data/seeding/seeding_service.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  await sl.reset();

  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseDatabase>(() => FirebaseDatabase.instance);
  sl.registerLazySingleton<GoogleSignIn>(
    () => GoogleSignIn(scopes: ['email', 'profile']),
  );

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

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<RideRepository>(
    () => RideRepositoryImpl(remoteDataSource: sl()),
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

  sl.registerLazySingleton<SeedingService>(
    () => SeedingService(firestore: sl(), realtimeDb: sl()),
  );

  sl.registerFactory<AuthBloc>(() => AuthBloc(authRepository: sl()));
  sl.registerFactory<HomeBloc>(() => HomeBloc(rideRepository: sl()));
  sl.registerFactory<TripsBloc>(() => TripsBloc(rideRepository: sl()));
  sl.registerFactory<TripDetailBloc>(
    () => TripDetailBloc(rideRepository: sl()),
  );
  sl.registerFactory<MapBloc>(
    () => MapBloc(mapRepository: sl(), rideRepository: sl()),
  );
  sl.registerFactory<MessagesBloc>(() => MessagesBloc(messageRepository: sl()));
  sl.registerFactory<NotificationsBloc>(
    () => NotificationsBloc(notificationRepository: sl()),
  );
  sl.registerFactory<ProfileBloc>(() => ProfileBloc(authRepository: sl()));

  debugPrint('✅ setupServiceLocator completed'); // ← add this
}
