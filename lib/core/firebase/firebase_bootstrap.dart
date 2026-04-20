import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    final webOptions = _webOptionsFromDartDefine();
    if (kIsWeb && webOptions != null) {
      await Firebase.initializeApp(options: webOptions);
      return;
    }

    await Firebase.initializeApp();
  }

  static FirebaseOptions? _webOptionsFromDartDefine() {
    const apiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
    const messagingSenderId = String.fromEnvironment('FIREBASE_WEB_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_WEB_PROJECT_ID');
    const authDomain = String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN');
    const storageBucket = String.fromEnvironment('FIREBASE_WEB_STORAGE_BUCKET');
    const measurementId = String.fromEnvironment('FIREBASE_WEB_MEASUREMENT_ID');

    final resolvedApiKey = apiKey.isEmpty ? 'AIzaSyDMnDA_lUVXl8oqmmjTZAyNzNYSGKNmc8s' : apiKey;
    final resolvedAppId = appId.isEmpty ? '1:937705200109:web:8265f895c9ec2f7a46efe4' : appId;
    final resolvedMessagingSenderId =
        messagingSenderId.isEmpty ? '937705200109' : messagingSenderId;
    final resolvedProjectId = projectId.isEmpty ? 'hack-a10bb' : projectId;
    final resolvedAuthDomain = authDomain.isEmpty ? 'hack-a10bb.firebaseapp.com' : authDomain;
    final resolvedStorageBucket =
        storageBucket.isEmpty ? 'hack-a10bb.firebasestorage.app' : storageBucket;
    final resolvedMeasurementId = measurementId.isEmpty ? 'G-HWLRE3ZHDV' : measurementId;

    return FirebaseOptions(
      apiKey: resolvedApiKey,
      appId: resolvedAppId,
      messagingSenderId: resolvedMessagingSenderId,
      projectId: resolvedProjectId,
      authDomain: resolvedAuthDomain,
      storageBucket: resolvedStorageBucket,
      measurementId: resolvedMeasurementId,
    );
  }
}
