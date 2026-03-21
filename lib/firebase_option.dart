
// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/*
📋 INSTRUCTIONS POUR LES ÉTUDIANTS:

1. Récupérez vos clés Firebase sur https://console.firebase.google.com/
2. Remplacez les valeurs ci-dessous par VOS propres clés
3. NE COMMITTEZ PAS ce fichier avec vos vraies clés sur Git!
4. Ajoutez-le dans .gitignore pour la sécurité

📍 Où trouver les valeurs:

• apiKey → google-services.json → client → api_key → current_key
• appId → google-services.json → client → client_info → mobilesdk_app_id  
• messagingSenderId → google-services.json → project_info → project_number
• projectId → google-services.json → project_info → project_id
• storageBucket → google-services.json → project_info → storage_bucket
*/

/// CONFIGURATION FIREBASE POUR TOUTES LES PLATEFORMES
class DefaultFirebaseOptions {
  
  /// CONFIGURATION ANDROID
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyATedivlrgOl0O-33wj7oCIudQBGq-J4kc',
    appId: '870807006129:android:34295f2072e3c2a8572b90',
    messagingSenderId: '870807006129',
    projectId: 'devmob-covoitlocal-55dbc',
    storageBucket: 'devmob-covoitlocal-55dbc.firebasestorage.app',
  );

  /// CONFIGURATION iOS (À décommenter si nécessaire)
  /*
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA1B2C3d4E5f6G7H8I9J0K1L2M3N4O5P6Q',
    appId: '1:835574812736:ios:abc123def456ghi789',
    messagingSenderId: '835574812736',
    projectId: 'gestion-bibliotheque-7ed2f',
    storageBucket: 'gestion-bibliotheque-7ed2f.firebasestorage.app',
    iosBundleId: 'com.example.gestionBibliotheque',
  );
  */

  /// CONFIGURATION WEB (À décommenter si nécessaire)
  /*
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA1B2C3d4E5f6G7H8I9J0K1L2M3N4O5P6Q',
    appId: '1:835574812736:web:abc123def456ghi789',
    messagingSenderId: '835574812736',
    projectId: 'gestion-bibliotheque-7ed2f',
    authDomain: 'gestion-bibliotheque-7ed2f.firebaseapp.com',
    storageBucket: 'gestion-bibliotheque-7ed2f.firebasestorage.app',
  );
  */

  /// 🔧 DÉTECTION AUTOMATIQUE DE LA PLATEFORME
  static FirebaseOptions get currentPlatform {
    // Si on est sur le web
    if (kIsWeb) {
      // return web; // Décommenter quand web est configuré
      throw UnsupportedError(
        'Configuration Web non encore configurée. '
        'Veuillez décommenter et configurer la section web ci-dessus.',
      );
    }
    
    // Si on est sur mobile
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        // return ios; // Décommenter quand iOS est configuré
        throw UnsupportedError(
          'Configuration iOS non encore configurée. '
          'Veuillez décommenter et configurer la section iOS ci-dessus.',
        );
      default:
        throw UnsupportedError(
          'Plateforme non supportée: ${defaultTargetPlatform}. '
          'Seul Android est configuré pour le moment.',
        );
    }
  }
}