import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration for the Boiser app.
///
/// ════════════════════════════════════════════════════════════════
///  HOW TO FILL THIS IN
/// ════════════════════════════════════════════════════════════════
///
///  1. YOUR PERSONAL FIREBASE (Auth + TODO)
///     Go to: https://console.firebase.google.com
///     → Select YOUR project
///     → ⚙️ Project Settings → Your apps → Web app
///     → Copy the firebaseConfig values into [personalOptions] below.
///
///  2. INSTRUCTOR'S FIREBASE (Grades — read only)
///     Ask your instructor for their Firebase Web App config values.
///     Paste them into [instructorOptions] below.
///
/// ════════════════════════════════════════════════════════════════

class FirebaseConfigs {
  FirebaseConfigs._();

  /// ── YOUR personal Firebase project ──────────────────────────────
  /// Used for: Firebase Authentication + TODO Firestore data
  static const FirebaseOptions personal = FirebaseOptions(
    apiKey: 'AIzaSyDBeohq3Kl2A43iGG3akrkgwv8BEienDYo',
    appId: '1:392293669902:web:9bbe420509effd0a64305f',
    messagingSenderId: '392293669902',
    projectId: 'boiser-student-app',
    storageBucket: 'boiser-student-app.firebasestorage.app',
    authDomain: 'boiser-student-app.firebaseapp.com',
  );

  /// ── INSTRUCTOR'S Firebase project ───────────────────────────────
  /// Used for: Reading grade data (attendance, quizzes, exams, etc.)
  /// App only READS from this project — no writes.
  static const FirebaseOptions instructor = FirebaseOptions(
    apiKey: 'INSTRUCTOR_API_KEY',
    appId: 'INSTRUCTOR_APP_ID',
    messagingSenderId: 'INSTRUCTOR_MESSAGING_SENDER_ID',
    projectId: 'INSTRUCTOR_PROJECT_ID',
    storageBucket: 'INSTRUCTOR_STORAGE_BUCKET',
    authDomain: 'INSTRUCTOR_AUTH_DOMAIN',
  );
}
