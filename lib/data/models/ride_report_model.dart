import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ride_report.dart';

class RideReportModel extends RideReport {
  const RideReportModel({
    required super.id,
    required super.rideId,
    required super.reporterId,
    required super.driverId,
    required super.reason,
    super.details,
    required super.createdAt,
    super.status,
  });

  factory RideReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideReportModel.fromMap(data, doc.id);
  }

  factory RideReportModel.fromMap(Map<String, dynamic> map, String id) {
    return RideReportModel(
      id: id,
      rideId: map['rideId'] as String? ?? '',
      reporterId: map['reporterId'] as String? ?? '',
      driverId: map['driverId'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      details: map['details'] as String?,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now().toUtc(),
      status: map['status'] as String? ?? 'open',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rideId': rideId,
      'reporterId': reporterId,
      'driverId': driverId,
      'reason': reason,
      'details': details,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}
