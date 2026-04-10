import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/vehicle.dart';
import '../models/app_user_model.dart';

abstract class UserRemoteDataSource {
  Future<AppUserModel?> getUserById(String uid);
  Future<List<AppUserModel>> getUsersByIds(List<String> uids);
  Stream<List<AppUserModel>> getPendingDrivers();
  Stream<List<AppUserModel>> getReportedDrivers();
  Future<void> approveDriver(String uid);
  Future<void> banDriver({
    required String uid,
    DateTime? until,
    bool indefinite = false,
  });
  Future<void> updateRidePreferences({
    required String uid,
    required Map<String, dynamic> ridePreferences,
  });
  Future<void> updateVehicles({
    required String uid,
    required List<Vehicle> vehicles,
  });
  Future<void> updateUser({
    required String uid,
    required Map<String, dynamic> updates,
  });
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  static const String _driverCredentials = 'driver_credentials';

  final FirebaseFirestore _firestore;
  UserRemoteDataSourceImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  static VerificationStatus _parseVerification(dynamic value) {
    switch (value as String?) {
      case 'pending':
        return VerificationStatus.pending;
      case 'verified':
        return VerificationStatus.verified;
      default:
        return VerificationStatus.unverified;
    }
  }

  @override
  Future<AppUserModel?> getUserById(String uid) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      final currentUser = AppUserModel.fromMap(data, doc.id);

      final expiredTemporaryBan =
          currentUser.bannedUntil != null &&
          currentUser.bannedUntil!.toUtc().isBefore(DateTime.now().toUtc());
      final wasVerifiedBeforeBan =
          currentUser.verification == VerificationStatus.pending;

      if (expiredTemporaryBan && wasVerifiedBeforeBan) {
        await docRef.update({
          'verification': VerificationStatus.verified.name,
          'bannedUntil': null,
          'isBanned': false,
        });
        final refreshed = await docRef.get();
        return AppUserModel.fromFirestore(refreshed);
      }

      return currentUser;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<AppUserModel>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    try {
      final futures = uids.map((id) => getUserById(id));
      final results = await Future.wait(futures);
      return results.whereType<AppUserModel>().toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<List<AppUserModel>> getPendingDrivers() {
    try {
      return _firestore
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .where('verification', isEqualTo: 'pending')
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((doc) => AppUserModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<List<AppUserModel>> getReportedDrivers() {
    try {
      return _firestore
          .collection('users')
          .where('reportCount', isGreaterThan: 0)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((doc) => AppUserModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> approveDriver(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'verification': VerificationStatus.verified.name,
      });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> banDriver({
    required String uid,
    DateTime? until,
    bool indefinite = false,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        throw ServerException(message: 'User not found.');
      }

      final userMap = userDoc.data() as Map<String, dynamic>;
      final currentVerification = _parseVerification(userMap['verification']);
      final shouldSetPending =
          currentVerification == VerificationStatus.verified;
      final updates = <String, dynamic>{
        'isBanned': indefinite,
        'bannedUntil': indefinite
            ? null
            : (until != null ? Timestamp.fromDate(until) : null),
      };

      if (shouldSetPending) {
        updates['verification'] = VerificationStatus.pending.name;
      }

      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateRidePreferences({
    required String uid,
    required Map<String, dynamic> ridePreferences,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'ridePreferences': ridePreferences,
        'preferences': _toLegacyPreferenceTags(ridePreferences),
      });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateVehicles({
    required String uid,
    required List<Vehicle> vehicles,
  }) async {
    try {
      final vehicleData = vehicles.map((vehicle) => vehicle.toMap()).toList();

      await _firestore.collection('users').doc(uid).update({
        'vehicles': vehicleData,
        'role': 'passenger',
        'verification': 'pending',
      });

      await _firestore.collection(_driverCredentials).doc(uid).set({
        'licenseNumber': vehicles.first.licenseNumber,
        'licenseExpirationDate': vehicles.first.licenseExpirationDate,
        'vehicleModel': vehicles.first.model,
        'vehicleColor': vehicles.first.color,
        'licensePlate': vehicles.first.licensePlate,
        'reviewStatus': 'pending',
      }, SetOptions(merge: true));
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateUser({
    required String uid,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  List<String> _toLegacyPreferenceTags(Map<String, dynamic> pref) {
    final tags = <String>[];
    if (pref['smokingAllowed'] == false) tags.add('no_smoking');
    if (pref['petsAllowed'] == true) tags.add('pets_welcome');

    final luggage = pref['luggageSize'] as String?;
    if (luggage == 'standardSuitcase') tags.add('medium_bag');
    if (luggage == 'smallBagOnly') tags.add('small_bag_only');
    if (luggage == 'largeItems') tags.add('large_items');

    final conversation = pref['conversationLevel'] as String?;
    if (conversation == 'quietRide') tags.add('quiet_trip');
    if (conversation == 'chatty') tags.add('chatty');

    final music = pref['musicLevel'] as String?;
    if (music != null && music.isNotEmpty) {
      tags.add('music_$music');
    }
    return tags;
  }
}
