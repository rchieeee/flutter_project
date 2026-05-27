import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/screens.dart';
import 'services/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Default App (Personal Firebase Auth & TODOs)
  await Firebase.initializeApp(
    options: FirebaseConfigs.personal,
  );

  // 2. Initialize Named App (Instructor's Firebase for Grades)
  // TODO: Uncomment this when you have the instructor's API keys
  // await Firebase.initializeApp(
  //   name: 'instructor',
  //   options: FirebaseConfigs.instructor,
  // );

  runApp(const BoiserApp());
}

class BoiserApp extends StatelessWidget {
  const BoiserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Boiser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4FC3F7),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0D1B2A),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF4FC3F7)),
              ),
            );
          }
          
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          
          return const LoginScreen();
        },
      ),
    );
  }
}
