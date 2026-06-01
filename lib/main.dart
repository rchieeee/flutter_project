import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/screens.dart';
import 'services/services.dart';
import 'database/database_helper.dart';
import 'provider/provider.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Set up sqflite for web (WASM) before opening any database
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }

    // 2. Initialise SQLite (creates/opens the local .db file)
    await DatabaseHelper.initialise();

    // 3. Initialise Firebase
    await Firebase.initializeApp(
      options: FirebaseConfigs.personal,
    );

    // 4. Start the offline→Firebase sync listener
    SyncService.instance.startListening();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const BoiserApp(),
      ),
    );
  } catch (e, stack) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'CRASH DURING STARTUP:\n\n$e\n\n$stack',
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BoiserApp extends StatelessWidget {
  const BoiserApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Context Management via Provider (fulfilling requirement #4)
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Boiser',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4FC3F7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4FC3F7),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        fontFamily: 'Roboto',
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0A0A0A),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'BOISER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    SizedBox(height: 32),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation(Colors.white54),
                      ),
                    ),
                  ],
                ),
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
