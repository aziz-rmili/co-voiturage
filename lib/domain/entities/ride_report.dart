import 'package:equatable/equatable.dart';

class RideReport extends Equatable {
  final String id;
  final String rideId;
  final String reporterId;
  final String driverId;
  final String reason;
  final String? details;
  final DateTime createdAt;
  final String status;

  const RideReport({
    required this.id,
    required this.rideId,
    required this.reporterId,
    required this.driverId,
    required this.reason,
    this.details,
    required this.createdAt,
    this.status = 'open',
  });

  RideReport copyWith({
    String? id,
    String? rideId,
    String? reporterId,
    String? driverId,
    String? reason,
    String? details,
    DateTime? createdAt,
    String? status,
  }) {
    return RideReport(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      reporterId: reporterId ?? this.reporterId,
      driverId: driverId ?? this.driverId,
      reason: reason ?? this.reason,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  bool get isOpen => status == 'open';

  @override
  List<Object?> get props => [
    id,
    rideId,
    reporterId,
    driverId,
    reason,
    details,
    createdAt,
    status,
  ];
}
