import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/ride_report.dart';
import '../../domain/repositories/ride_repository.dart';
import '../../domain/repositories/user_repository.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class AdminStarted extends AdminEvent {
  const AdminStarted();
}

class AdminApproveDriverRequested extends AdminEvent {
  final String userId;
  const AdminApproveDriverRequested({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class AdminBanDriverRequested extends AdminEvent {
  final String userId;
  final DateTime? until;
  final bool indefinite;

  const AdminBanDriverRequested({
    required this.userId,
    this.until,
    this.indefinite = false,
  });

  @override
  List<Object?> get props => [userId, until, indefinite];
}

class _PendingDriversUpdated extends AdminEvent {
  final List<AppUser> drivers;
  const _PendingDriversUpdated(this.drivers);
  @override
  List<Object?> get props => [drivers];
}

class _ReportedDriversUpdated extends AdminEvent {
  final List<AppUser> drivers;
  const _ReportedDriversUpdated(this.drivers);
  @override
  List<Object?> get props => [drivers];
}

class _AllRidesUpdated extends AdminEvent {
  final List<Ride> rides;
  const _AllRidesUpdated(this.rides);
  @override
  List<Object?> get props => [rides];
}

class _RideReportsUpdated extends AdminEvent {
  final List<RideReport> reports;
  const _RideReportsUpdated(this.reports);
  @override
  List<Object?> get props => [reports];
}

class AdminResolveReportRequested extends AdminEvent {
  final String reportId;
  const AdminResolveReportRequested({required this.reportId});
  @override
  List<Object?> get props => [reportId];
}

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

class AdminLoaded extends AdminState {
  final List<AppUser> pendingDrivers;
  final List<AppUser> reportedDrivers;
  final List<Ride> allRides;
  final List<RideReport> reportedRideReports;
  final String? message;

  const AdminLoaded({
    this.pendingDrivers = const [],
    this.reportedDrivers = const [],
    this.allRides = const [],
    this.reportedRideReports = const [],
    this.message,
  });

  AdminLoaded copyWith({
    List<AppUser>? pendingDrivers,
    List<AppUser>? reportedDrivers,
    List<Ride>? allRides,
    List<RideReport>? reportedRideReports,
    String? message,
  }) {
    return AdminLoaded(
      pendingDrivers: pendingDrivers ?? this.pendingDrivers,
      reportedDrivers: reportedDrivers ?? this.reportedDrivers,
      allRides: allRides ?? this.allRides,
      reportedRideReports: reportedRideReports ?? this.reportedRideReports,
      message: message,
    );
  }

  int get totalRides => allRides.length;
  int get completedRides =>
      allRides.where((r) => r.status == RideStatus.completed).length;
  int get activeRides =>
      allRides.where((r) => r.status == RideStatus.active).length;
  int get scheduledRides =>
      allRides.where((r) => r.status == RideStatus.scheduled).length;
  int get pendingApprovals => pendingDrivers.length;
  int get reportedDriverCount => reportedDrivers.length;
  int get disputeCount => reportedRideReports.length;
  double get totalRevenue => allRides.fold<double>(
    0.0,
    (sum, ride) =>
        sum + (ride.pricePerPassenger * ride.confirmedPassengerIds.length),
  );

  double get totalCommission => totalRevenue * 0.15;

  @override
  List<Object?> get props => [
    pendingDrivers,
    reportedDrivers,
    allRides,
    reportedRideReports,
    message,
  ];
}

class AdminError extends AdminState {
  final String message;
  const AdminError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final UserRepository _userRepository;
  final RideRepository _rideRepository;

  StreamSubscription<List<AppUser>>? _pendingSub;
  StreamSubscription<List<AppUser>>? _reportedSub;
  StreamSubscription<List<Ride>>? _ridesSub;
  StreamSubscription<List<RideReport>>? _reportSub;

  AdminBloc({
    required UserRepository userRepository,
    required RideRepository rideRepository,
  }) : _userRepository = userRepository,
       _rideRepository = rideRepository,
       super(const AdminInitial()) {
    on<AdminStarted>(_onStarted);
    on<_PendingDriversUpdated>(_onPendingDriversUpdated);
    on<_ReportedDriversUpdated>(_onReportedDriversUpdated);
    on<_AllRidesUpdated>(_onAllRidesUpdated);
    on<_RideReportsUpdated>(_onRideReportsUpdated);
    on<AdminResolveReportRequested>(_onResolveReportRequested);
    on<AdminApproveDriverRequested>(_onApproveDriverRequested);
    on<AdminBanDriverRequested>(_onBanDriverRequested);
  }

  Future<void> _onStarted(AdminStarted event, Emitter<AdminState> emit) async {
    emit(const AdminLoading());
    await _pendingSub?.cancel();
    await _reportedSub?.cancel();
    await _ridesSub?.cancel();

    _pendingSub = _userRepository.getPendingDrivers().listen(
      (drivers) => add(_PendingDriversUpdated(drivers)),
      onError: (_) {
        if (!emit.isDone)
          emit(const AdminError(message: 'Failed to load pending drivers.'));
      },
    );

    _reportedSub = _userRepository.getReportedDrivers().listen(
      (drivers) => add(_ReportedDriversUpdated(drivers)),
      onError: (_) {
        if (!emit.isDone)
          emit(const AdminError(message: 'Failed to load reported drivers.'));
      },
    );

    _ridesSub = _rideRepository.getAllRides().listen(
      (rides) => add(_AllRidesUpdated(rides)),
      onError: (_) {
        if (!emit.isDone)
          emit(const AdminError(message: 'Failed to load platform rides.'));
      },
    );

    _reportSub = _rideRepository.getRideReports().listen(
      (reports) => add(_RideReportsUpdated(reports)),
      onError: (_) {
        if (!emit.isDone)
          emit(const AdminError(message: 'Failed to load ride reports.'));
      },
    );
  }

  void _onPendingDriversUpdated(
    _PendingDriversUpdated event,
    Emitter<AdminState> emit,
  ) {
    if (state is AdminLoaded) {
      emit((state as AdminLoaded).copyWith(pendingDrivers: event.drivers));
      return;
    }
    emit(AdminLoaded(pendingDrivers: event.drivers));
  }

  void _onReportedDriversUpdated(
    _ReportedDriversUpdated event,
    Emitter<AdminState> emit,
  ) {
    if (state is AdminLoaded) {
      emit((state as AdminLoaded).copyWith(reportedDrivers: event.drivers));
      return;
    }
    emit(AdminLoaded(reportedDrivers: event.drivers));
  }

  void _onAllRidesUpdated(_AllRidesUpdated event, Emitter<AdminState> emit) {
    if (state is AdminLoaded) {
      emit((state as AdminLoaded).copyWith(allRides: event.rides));
      return;
    }
    emit(AdminLoaded(allRides: event.rides));
  }

  void _onRideReportsUpdated(
    _RideReportsUpdated event,
    Emitter<AdminState> emit,
  ) {
    if (state is AdminLoaded) {
      emit((state as AdminLoaded).copyWith(reportedRideReports: event.reports));
      return;
    }
    emit(AdminLoaded(reportedRideReports: event.reports));
  }

  Future<void> _onResolveReportRequested(
    AdminResolveReportRequested event,
    Emitter<AdminState> emit,
  ) async {
    if (state is! AdminLoaded) return;
    try {
      await _rideRepository.resolveRideReport(event.reportId);
      emit(
        (state as AdminLoaded).copyWith(message: 'Report marked as resolved.'),
      );
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onApproveDriverRequested(
    AdminApproveDriverRequested event,
    Emitter<AdminState> emit,
  ) async {
    if (state is! AdminLoaded) return;
    try {
      await _userRepository.approveDriver(event.userId);
      emit(
        (state as AdminLoaded).copyWith(
          message: 'Driver approved successfully.',
        ),
      );
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onBanDriverRequested(
    AdminBanDriverRequested event,
    Emitter<AdminState> emit,
  ) async {
    if (state is! AdminLoaded) return;
    try {
      await _userRepository.banDriver(
        uid: event.userId,
        until: event.until,
        indefinite: event.indefinite,
      );
      final description = event.indefinite
          ? 'Driver banned permanently.'
          : 'Driver banned until ${event.until?.toLocal().toString().split(' ').first ?? 'unknown'}.';
      emit((state as AdminLoaded).copyWith(message: description));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _pendingSub?.cancel();
    _reportedSub?.cancel();
    _ridesSub?.cancel();
    _reportSub?.cancel();
    return super.close();
  }
}
