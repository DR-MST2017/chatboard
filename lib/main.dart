// lib/main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // généré par flutterfire configure
import 'screens/auth_screen.dart';
import 'screens/chat_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ChatBoardApp());
}

class ChatBoardApp extends StatelessWidget {
  const ChatBoardApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ChatBoard',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      );
}

/// AuthGate — redirige vers ChatScreen ou AuthScreen selon l'état de connexion.
/// authStateChanges() est un Stream persistant : la session est conservée
/// même après fermeture de l'app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // User non-null = connecté → ChatScreen
        // null = déconnecté → AuthScreen
        return snapshot.data != null
            ? const ChatScreen()
            : const AuthScreen();
      },
    );
  }
}
