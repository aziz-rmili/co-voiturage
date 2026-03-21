import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import '../../core/errors/exceptions.dart';
import '../../domain/entities/driver_location.dart';

abstract class MapRemoteDataSource {
  Stream<List<DriverLocation>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusKm = 20,
  });
  Future<void> publishDriverLocation(DriverLocation location);
  Future<void> removeDriverLocation(String driverId);
  Future<List<List<double>>> getRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  });
}

class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final FirebaseDatabase _realtimeDb;
  final String _orsApiKey; // OpenRouteService API key

  MapRemoteDataSourceImpl({
    required FirebaseDatabase realtimeDb,
    required String orsApiKey,
  }) : _realtimeDb = realtimeDb,
       _orsApiKey = orsApiKey;

  DatabaseReference get _driversRef => _realtimeDb.ref('active_drivers');

  // ── Driver locations stream ───────────────────────────────────────────────

  @override
  Stream<List<DriverLocation>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusKm = 20,
  }) {
    return _driversRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      final result = <DriverLocation>[];
      data.forEach((key, value) {
        try {
          final map = Map<String, dynamic>.from(value as Map);
          final dLat = (map['latitude'] as num).toDouble();
          final dLng = (map['longitude'] as num).toDouble();
          final distKm = _haversineKm(latitude, longitude, dLat, dLng);
          if (distKm <= radiusKm) {
            result.add(
              DriverLocation(
                driverId: key as String,
                latitude: dLat,
                longitude: dLng,
                rideId: map['rideId'] as String?,
                destination: map['destination'] as String?,
                departureTime: map['departureTime'] as String?,
                seatsLeft: (map['seatsLeft'] as num?)?.toInt() ?? 0,
                updatedAt: DateTime.fromMillisecondsSinceEpoch(
                  (map['updatedAt'] as num?)?.toInt() ??
                      DateTime.now().millisecondsSinceEpoch,
                ),
              ),
            );
          }
        } catch (_) {}
      });
      return result;
    });
  }

  // ── Publish driver location ───────────────────────────────────────────────

  @override
  Future<void> publishDriverLocation(DriverLocation location) async {
    try {
      await _driversRef.child(location.driverId).set({
        'latitude': location.latitude,
        'longitude': location.longitude,
        'rideId': location.rideId,
        'destination': location.destination,
        'departureTime': location.departureTime,
        'seatsLeft': location.seatsLeft,
        'updatedAt': location.updatedAt.millisecondsSinceEpoch,
      });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> removeDriverLocation(String driverId) async {
    try {
      await _driversRef.child(driverId).remove();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── OpenRouteService polyline ─────────────────────────────────────────────

  @override
  Future<List<List<double>>> getRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    const baseUrl =
        'https://api.openrouteservice.org/v2/directions/driving-car';
    final uri = Uri.parse(baseUrl);
    final body = jsonEncode({
      'coordinates': [
        [fromLng, fromLat],
        [toLng, toLat],
      ],
    });

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': _orsApiKey,
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        throw ServerException(message: 'ORS error: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final coords =
          (json['features'] as List?)?.first['geometry']['coordinates']
              as List? ??
          [];

      return coords
          .map<List<double>>(
            (c) => [(c as List)[1].toDouble(), c[0].toDouble()],
          )
          .toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Haversine distance ────────────────────────────────────────────────────

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a =
        _sin2(dLat / 2) + _cos(_rad(lat1)) * _cos(_rad(lat2)) * _sin2(dLng / 2);
    return r * 2 * _asin(_sqrt(a));
  }

  double _rad(double deg) => deg * 3.141592653589793 / 180;
  double _sin2(double x) => _sin(x) * _sin(x);
  double _sin(double x) {
    // Taylor series sin
    double s = x, t = x;
    for (int i = 1; i <= 6; i++) {
      t *= -x * x / ((2 * i) * (2 * i + 1));
      s += t;
    }
    return s;
  }

  double _cos(double x) => _sin(3.141592653589793 / 2 - x);
  double _sqrt(double x) {
    if (x <= 0) return 0;
    double r = x;
    for (int i = 0; i < 20; i++) r = (r + x / r) / 2;
    return r;
  }

  double _asin(double x) {
    // arcsin via atan approximation
    return x + (x * x * x) / 6 + (3 * x * x * x * x * x) / 40;
  }
}
