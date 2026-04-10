import 'dart:convert';
import 'dart:math' as math;
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
  final String _orsApiKey;

  MapRemoteDataSourceImpl({
    required FirebaseDatabase realtimeDb,
    required String orsApiKey,
  }) : _realtimeDb = realtimeDb,
       _orsApiKey = orsApiKey;

  DatabaseReference get _driversRef => _realtimeDb.ref('active_drivers');

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
                departure: map['departure'] as String?,
                departureTime: map['departureTime'] as String?,
                departureLat: (map['departureLat'] as num?)?.toDouble(),
                departureLng: (map['departureLng'] as num?)?.toDouble(),
                arrivalLat: (map['arrivalLat'] as num?)?.toDouble(),
                arrivalLng: (map['arrivalLng'] as num?)?.toDouble(),
                seatsLeft: (map['seatsLeft'] as num?)?.toInt() ?? 0,
                pricePerSeat: (map['pricePerSeat'] as num?)?.toDouble(),
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

  @override
  Future<void> publishDriverLocation(DriverLocation location) async {
    try {
      await _driversRef.child(location.driverId).set({
        'latitude': location.latitude,
        'longitude': location.longitude,
        'rideId': location.rideId,
        'destination': location.destination,
        'departure': location.departure,
        'departureTime': location.departureTime,
        'departureLat': location.departureLat,
        'departureLng': location.departureLng,
        'arrivalLat': location.arrivalLat,
        'arrivalLng': location.arrivalLng,
        'seatsLeft': location.seatsLeft,
        'pricePerSeat': location.pricePerSeat,
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

  @override
  Future<List<List<double>>> getRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final hasValidOrsKey =
        _orsApiKey.isNotEmpty && _orsApiKey != 'YOUR_ORS_API_KEY_HERE';

    if (hasValidOrsKey) {
      final orsRoute = await _getRouteFromOrs(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      );
      if (orsRoute.isNotEmpty) {
        return orsRoute;
      }
    }

    final osrmRoute = await _getRouteFromOsrm(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
    if (osrmRoute.isNotEmpty) {
      return osrmRoute;
    }

    throw const ServerException(
      message: 'Could not compute road route for this trip.',
    );
  }

  Future<List<List<double>>> _getRouteFromOrs({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    const baseUrl =
        'https://api.openrouteservice.org/v2/directions/driving-car';
    final body = jsonEncode({
      'coordinates': [
        [fromLng, fromLat],
        [toLng, toLat],
      ],
    });
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': _orsApiKey,
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode != 200) {
        return const [];
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
    } catch (_) {
      return const [];
    }
  }

  Future<List<List<double>>> _getRouteFromOsrm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '$fromLng,$fromLat;$toLng,$toLat'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return const [];
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = json['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        return const [];
      }

      final geometry = routes.first['geometry'] as Map<String, dynamic>?;
      final coords = geometry?['coordinates'] as List? ?? const [];

      return coords
          .map<List<double>>(
            (c) => [(c as List)[1].toDouble(), c[0].toDouble()],
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;
}
