// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

/// Service d'authentification — encapsule Firebase Auth.
/// Fournit : inscription avec pseudo, connexion, déconnexion,
/// stream de l'état de connexion, et accès à l'utilisateur courant.
class AuthService {
  final _auth = FirebaseAuth.instance;

  /// Stream de l'état de connexion — utilisé par AuthGate.
  /// Émet User non-null si connecté, null si déconnecté.
  /// La session est persistée automatiquement par Firebase.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Utilisateur actuellement connecté (null si déconnecté).
  User? get currentUser => _auth.currentUser;

  /// Inscription : crée le compte Firebase + définit le pseudo (displayName).
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Définit le pseudo immédiatement après la création du compte
    await credential.user!.updateDisplayName(displayName);
    // Recharge le profil pour que currentUser.displayName soit à jour
    await _auth.currentUser!.reload();
  }

  /// Connexion avec email et mot de passe.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Déconnexion — le stream authStateChanges émettra null.
  Future<void> logout() async {
    await _auth.signOut();
  }
}
