import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

/// Run this once (e.g. from a debug button or during dev) to populate
/// Firestore + Realtime Database with realistic demo data matching the designs.
///
/// Usage:
///   await SeedingService(
///     firestore: FirebaseFirestore.instance,
///     realtimeDb: FirebaseDatabase.instance,
///   ).seed();
class SeedingService {
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _realtimeDb;

  SeedingService({
    required FirebaseFirestore firestore,
    required FirebaseDatabase realtimeDb,
  }) : _firestore = firestore,
       _realtimeDb = realtimeDb;

  Future<void> seed() async {
    print('[SeedingService] Starting seed...');
    await _seedUsers();
    await _seedRides();
    await _seedConversations();
    await _seedNotifications();
    await _seedDriverLocations();
    print('[SeedingService] Done ✅');
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  Future<void> _seedUsers() async {
    final users = [
      {
        'uid': 'seed_user_julien',
        'name': 'Julien Morel',
        'email': 'julien@rideleaf.app',
        'phone': '+216 20 123 456',
        'photoUrl': '',
        'dateInscription': Timestamp.fromDate(DateTime(2024, 1, 15)),
        'preferences': ['no_smoking', 'pets_welcome'],
        'averageRating': 4.9,
        'verification': 'verified',
        'role': 'passenger',
      },
      {
        'uid': 'seed_user_ahmed',
        'name': 'Ahmed M',
        'email': 'ahmed@rideleaf.app',
        'phone': '+216 25 456 789',
        'photoUrl': '',
        'dateInscription': Timestamp.fromDate(DateTime(2024, 2, 10)),
        'preferences': ['no_smoking'],
        'averageRating': 4.9,
        'verification': 'verified',
        'role': 'driver',
      },
      {
        'uid': 'seed_user_maher',
        'name': 'Maher K',
        'email': 'maher@rideleaf.app',
        'phone': '+216 22 789 012',
        'photoUrl': '',
        'dateInscription': Timestamp.fromDate(DateTime(2024, 3, 5)),
        'preferences': ['medium_bag'],
        'averageRating': 5.0,
        'verification': 'verified',
      },
      {
        'uid': 'seed_user_sami',
        'name': 'Sami N',
        'email': 'sami@rideleaf.app',
        'phone': '+216 23 321 654',
        'photoUrl': '',
        'dateInscription': Timestamp.fromDate(DateTime(2024, 1, 28)),
        'preferences': ['no_smoking', 'max_2_back'],
        'averageRating': 4.8,
        'verification': 'verified',
      },
      {
        'uid': 'seed_user_salim',
        'name': 'Salim K',
        'email': 'salim@rideleaf.app',
        'phone': '+216 26 654 987',
        'photoUrl': '',
        'dateInscription': Timestamp.fromDate(DateTime(2024, 4, 2)),
        'preferences': [],
        'averageRating': 4.7,
        'verification': 'pending',
      },
      {
        'uid': 'seed_user_mounir',
        'name': 'Mounir Smida',
        'email': 'mounir@rideleaf.app',
        'phone': '+216 21 987 321',
        'photoUrl': '',
        'dateInscription': Timestamp.fromDate(DateTime(2023, 11, 20)),
        'preferences': [
          'no_smoking',
          'pets_welcome',
          'medium_bag',
          'max_2_back',
        ],
        'averageRating': 4.9,
        'verification': 'verified',
      },
      // Message contacts
      {
        'uid': 'seed_user_amir',
        'name': 'Amir saad',
        'email': 'amir@rideleaf.app',
        'phone': '+216 27 111 222',
        'photoUrl': '',
        'dateInscription': Timestamp.fromDate(DateTime(2024, 5, 1)),
        'preferences': [],
        'averageRating': 4.6,
        'verification': 'verified',
      },
      {
        'uid': 'seed_user_mayssem',
        'name': 'Mayssem M',
        'email': 'mayssem@rideleaf.app',
        'phone': '+216 28 333 444',
        'photoUrl': '',
        'dateInscription': Timestamp.fromDate(DateTime(2024, 5, 10)),
        'preferences': [],
        'averageRating': 4.5,
        'verification': 'verified',
      },
      {
        'uid': 'seed_user_aysser',
        'name': 'Aysser BR',
        'email': 'aysser@rideleaf.app',
        'phone': '+216 29 555 666',
        'photoUrl': '',
        'dateInscription': Timestamp.fromDate(DateTime(2024, 6, 3)),
        'preferences': [],
        'averageRating': 4.8,
        'verification': 'verified',
      },
      {
        'uid': 'seed_user_yossra',
        'name': 'Yossra BS',
        'email': 'yossra@rideleaf.app',
        'phone': '+216 24 777 888',
        'photoUrl': '',
        'dateInscription': Timestamp.fromDate(DateTime(2024, 6, 15)),
        'preferences': [],
        'averageRating': 4.7,
        'verification': 'verified',
      },
    ];

    final batch = _firestore.batch();
    for (final u in users) {
      final uid = u['uid'] as String;
      final ref = _firestore.collection('users').doc(uid);
      final data = Map<String, dynamic>.from(u)..remove('uid');
      batch.set(ref, data, SetOptions(merge: true));
    }
    await batch.commit();
    print('[SeedingService] Users seeded.');
  }

  // ── Rides ─────────────────────────────────────────────────────────────────

  Future<void> _seedRides() async {
    final now = DateTime.now();

    final rides = [
      // Upcoming - confirmed (Julien as passenger)
      {
        'id': 'seed_ride_1',
        'driverId': 'seed_user_sami',
        'departure': const GeoPoint(36.8190, 10.1658), // Tunis center
        'arrival': const GeoPoint(36.8685, 10.3453), // Sidi Bou Said
        'departureAddress': 'Tunis',
        'arrivalAddress': 'Sidi Bou Said',
        'dateHour': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day, 17, 30),
        ),
        'availableSeats': 3,
        'pricePerPassenger': 4.0,
        'pendingPassengerIds': [],
        'confirmedPassengerIds': ['seed_user_julien'],
        'status': 'scheduled',
      },
      // Upcoming - pending (Julien as passenger)
      {
        'id': 'seed_ride_2',
        'driverId': 'seed_user_salim',
        'departure': const GeoPoint(36.4512, 10.7365), // Nabeul
        'arrival': const GeoPoint(36.8496, 11.1030), // Kelibia
        'departureAddress': 'Nabeul',
        'arrivalAddress': 'Kelibia',
        'dateHour': Timestamp.fromDate(
          now.add(const Duration(days: 3)).copyWith(hour: 8, minute: 15),
        ),
        'availableSeats': 2,
        'pricePerPassenger': 8.0,
        'pendingPassengerIds': [],
        'confirmedPassengerIds': ['seed_user_julien'],
        'status': 'scheduled',
      },
      // Popular route - Tunis → Sidi Bou Said (Ahmed)
      {
        'id': 'seed_ride_3',
        'driverId': 'seed_user_ahmed',
        'departure': const GeoPoint(36.8190, 10.1658),
        'arrival': const GeoPoint(36.8685, 10.3453),
        'departureAddress': 'Tunis',
        'arrivalAddress': 'Sidi Bou Said',
        'dateHour': Timestamp.fromDate(now.add(const Duration(hours: 2))),
        'availableSeats': 3,
        'pricePerPassenger': 4.0,
        'pendingPassengerIds': [],
        'confirmedPassengerIds': [],
        'status': 'scheduled',
      },
      // Popular route - Sousse → Monastir (Maher)
      {
        'id': 'seed_ride_4',
        'driverId': 'seed_user_maher',
        'departure': const GeoPoint(35.8245, 10.6346), // Sousse
        'arrival': const GeoPoint(35.7643, 10.8113), // Monastir
        'departureAddress': 'Sousse',
        'arrivalAddress': 'Monastir',
        'dateHour': Timestamp.fromDate(now.add(const Duration(hours: 3))),
        'availableSeats': 2,
        'pricePerPassenger': 5.0,
        'pendingPassengerIds': [], 'confirmedPassengerIds': [],
        'status': 'scheduled',
      },
      // Trip detail showcase - Nabeul → Sousse (Mounir)
      {
        'id': 'seed_ride_5',
        'driverId': 'seed_user_mounir',
        'departure': const GeoPoint(36.4512, 10.7365), // Nabeul
        'arrival': const GeoPoint(35.8245, 10.6346), // Sousse
        'departureAddress': 'Nabeul',
        'arrivalAddress': 'Sousse',
        'dateHour': Timestamp.fromDate(
          now.add(const Duration(hours: 1)).copyWith(minute: 30),
        ),
        'availableSeats': 3,
        'pricePerPassenger': 16.0,
        'pendingPassengerIds': [], 'confirmedPassengerIds': [],
        'status': 'scheduled',
        'vehicleModel': 'Tesla Model 3',
        'vehicleColor': 'White',
        'driverNote':
            "I usually leave on time. Small luggage is welcome. Let's keep the ride friendly and comfortable for everyone!",
      },
      // Past trips
      {
        'id': 'seed_ride_past_1',
        'driverId': 'seed_user_ahmed',
        'departure': const GeoPoint(36.8190, 10.1658),
        'arrival': const GeoPoint(36.8685, 10.3453),
        'departureAddress': 'Tunis',
        'arrivalAddress': 'Carthage',
        'dateHour': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        'availableSeats': 3,
        'pricePerPassenger': 3.5,
        'pendingPassengerIds': [],
        'confirmedPassengerIds': ['seed_user_julien', 'seed_user_amir'],
        'status': 'completed',
      },
      {
        'id': 'seed_ride_past_2',
        'driverId': 'seed_user_julien',
        'departure': const GeoPoint(36.8190, 10.1658),
        'arrival': const GeoPoint(36.7382, 10.0763),
        'departureAddress': 'Tunis',
        'arrivalAddress': 'La Marsa',
        'dateHour': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
        'availableSeats': 2,
        'pricePerPassenger': 3.0,
        'pendingPassengerIds': [],
        'confirmedPassengerIds': ['seed_user_mayssem', 'seed_user_aysser'],
        'status': 'completed',
      },
    ];

    final batch = _firestore.batch();
    for (final r in rides) {
      final id = r['id'] as String;
      final ref = _firestore.collection('rides').doc(id);
      final data = Map<String, dynamic>.from(r)..remove('id');
      batch.set(ref, data, SetOptions(merge: true));
    }
    await batch.commit();
    print('[SeedingService] Rides seeded.');
  }

  // ── Conversations + Messages ───────────────────────────────────────────────

  Future<void> _seedConversations() async {
    final now = DateTime.now();

    final conversations = [
      {
        'id': 'seed_conv_1',
        'participantIds': ['seed_user_julien', 'seed_user_amir'],
        'lastMessage': "Perfect, I'll wait for you at the entrance.",
        'lastMessageTime': Timestamp.fromDate(
          now.subtract(const Duration(hours: 1, minutes: 15)),
        ),
        'unreadCount': {'seed_user_julien': 1},
        'rideId': 'seed_ride_1',
        'messages': [
          {
            'senderId': 'seed_user_amir',
            'receiverId': 'seed_user_julien',
            'text': 'Hey, are you still on for the 17:30 ride?',
            'timestamp': Timestamp.fromDate(
              now.subtract(const Duration(hours: 2)),
            ),
            'isRead': true,
          },
          {
            'senderId': 'seed_user_julien',
            'receiverId': 'seed_user_amir',
            'text': 'Yes! I\'ll be there 5 minutes early.',
            'timestamp': Timestamp.fromDate(
              now.subtract(const Duration(hours: 1, minutes: 30)),
            ),
            'isRead': true,
          },
          {
            'senderId': 'seed_user_amir',
            'receiverId': 'seed_user_julien',
            'text': "Perfect, I'll wait for you at the entrance.",
            'timestamp': Timestamp.fromDate(
              now.subtract(const Duration(hours: 1, minutes: 15)),
            ),
            'isRead': false,
          },
        ],
      },
      {
        'id': 'seed_conv_2',
        'participantIds': ['seed_user_julien', 'seed_user_mayssem'],
        'lastMessage': 'Thanks for the ride! The car was very clean.',
        'lastMessageTime': Timestamp.fromDate(
          now.subtract(const Duration(days: 1)),
        ),
        'unreadCount': {'seed_user_julien': 0},
        'rideId': 'seed_ride_past_1',
        'messages': [
          {
            'senderId': 'seed_user_mayssem',
            'receiverId': 'seed_user_julien',
            'text': 'Thanks for the ride! The car was very clean.',
            'timestamp': Timestamp.fromDate(
              now.subtract(const Duration(days: 1)),
            ),
            'isRead': true,
          },
        ],
      },
      {
        'id': 'seed_conv_3',
        'participantIds': ['seed_user_julien', 'seed_user_aysser'],
        'lastMessage': 'Can we move the departure to 8:30?',
        'lastMessageTime': Timestamp.fromDate(
          now.subtract(const Duration(days: 2)),
        ),
        'unreadCount': {'seed_user_julien': 0},
        'messages': [
          {
            'senderId': 'seed_user_aysser',
            'receiverId': 'seed_user_julien',
            'text': 'Can we move the departure to 8:30?',
            'timestamp': Timestamp.fromDate(
              now.subtract(const Duration(days: 2)),
            ),
            'isRead': true,
          },
        ],
      },
      {
        'id': 'seed_conv_4',
        'participantIds': ['seed_user_julien', 'seed_user_yossra'],
        'lastMessage': 'Is there still room for one more passenger?',
        'lastMessageTime': Timestamp.fromDate(
          now.subtract(const Duration(days: 3)),
        ),
        'unreadCount': {'seed_user_julien': 1},
        'messages': [
          {
            'senderId': 'seed_user_yossra',
            'receiverId': 'seed_user_julien',
            'text': 'Is there still room for one more passenger?',
            'timestamp': Timestamp.fromDate(
              now.subtract(const Duration(days: 3)),
            ),
            'isRead': false,
          },
        ],
      },
    ];

    for (final conv in conversations) {
      final id = conv['id'] as String;
      final messages = conv['messages'] as List;
      final convData = Map<String, dynamic>.from(conv)
        ..remove('id')
        ..remove('messages');

      final convRef = _firestore.collection('conversations').doc(id);
      await convRef.set(convData, SetOptions(merge: true));

      for (final msg in messages) {
        final msgData = Map<String, dynamic>.from(msg as Map)
          ..['conversationId'] = id;
        await convRef.collection('messages').add(msgData);
      }
    }
    print('[SeedingService] Conversations seeded.');
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<void> _seedNotifications() async {
    final now = DateTime.now();
    const uid = 'seed_user_julien';

    final notifications = [
      {
        'userId': uid,
        'type': 'tripConfirmed',
        'title': 'Trip confirmed',
        'body': 'Your seat for the ride to downtown is locked in. Ready to go?',
        'timestamp': Timestamp.fromDate(
          now.subtract(const Duration(minutes: 2)),
        ),
        'isRead': false,
        'requiresAction': true,
        'relatedId': 'seed_ride_1',
      },
      {
        'userId': uid,
        'type': 'paymentReceived',
        'title': 'Payment received',
        'body':
            'Transaction for your carpool session with Sarah was successful.',
        'timestamp': Timestamp.fromDate(
          now.subtract(const Duration(minutes: 15)),
        ),
        'isRead': false,
        'requiresAction': false,
        'relatedId': 'seed_ride_past_1',
      },
      {
        'userId': uid,
        'type': 'systemUpdate',
        'title': 'System Update',
        'body': 'Your CO2 savings report for July is now ready.',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'isRead': true,
        'requiresAction': false,
        'relatedId': null,
      },
      {
        'userId': uid,
        'type': 'accountVerified',
        'title': 'Account verified',
        'body': 'Profile validation is complete.',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'isRead': true,
        'requiresAction': false,
        'relatedId': null,
      },
    ];

    final batch = _firestore.batch();
    for (final n in notifications) {
      final ref = _firestore.collection('notifications').doc();
      batch.set(ref, n);
    }
    await batch.commit();
    print('[SeedingService] Notifications seeded.');
  }

  // ── Realtime Driver Locations ─────────────────────────────────────────────

  Future<void> _seedDriverLocations() async {
    final driversRef = _realtimeDb.ref('active_drivers');

    // seed_ride_3: Tunis → Sidi Bou Said (Ahmed)
    // seed_ride_4: Sousse → Monastir     (Maher)
    // seed_ride_5: Nabeul → Sousse       (Mounir)
    final drivers = {
      'seed_user_ahmed': {
        'latitude': 36.8320,
        'longitude': 10.1750,
        'rideId': 'seed_ride_3',
        // route: Tunis center → Sidi Bou Said
        'departure': 'Tunis',
        'destination': 'Sidi Bou Said',
        'departureLat': 36.8190,
        'departureLng': 10.1658,
        'arrivalLat': 36.8685,
        'arrivalLng': 10.3453,
        'departureTime': '9:15 AM',
        'seatsLeft': 2,
        'pricePerSeat': 4,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      'seed_user_maher': {
        'latitude': 36.7980,
        'longitude': 10.1600,
        'rideId': 'seed_ride_4',
        // route: Sousse → Monastir
        'departure': 'Sousse',
        'destination': 'Monastir',
        'departureLat': 35.8245,
        'departureLng': 10.6346,
        'arrivalLat': 35.7643,
        'arrivalLng': 10.8113,
        'departureTime': '10:00 AM',
        'seatsLeft': 3,
        'pricePerSeat': 5,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      'seed_user_mounir': {
        'latitude': 36.8100,
        'longitude': 10.1900,
        'rideId': 'seed_ride_5',
        // route: Nabeul → Sousse
        'departure': 'Nabeul',
        'destination': 'Sousse',
        'departureLat': 36.4512,
        'departureLng': 10.7365,
        'arrivalLat': 35.8245,
        'arrivalLng': 10.6346,
        'departureTime': '8:45 AM',
        'seatsLeft': 2,
        'pricePerSeat': 16,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
    };

    await driversRef.set(drivers);
    print('[SeedingService] Driver locations seeded to Realtime DB.');
  }
}

/// Extension to make DateTime.copyWith available
extension _DateTimeCopyWith on DateTime {
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
    );
  }
}
