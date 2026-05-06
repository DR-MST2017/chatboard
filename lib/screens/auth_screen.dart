// lib/screens/auth_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Écran d'authentification unique gérant deux modes :
/// - Connexion (email + mot de passe)
/// - Inscription (email + mot de passe + pseudo)
/// L'utilisateur bascule entre les deux modes avec un TextButton.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthService();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isRegistering = false; // false = mode connexion par défaut
  bool _isLoading = false;
  String? _error;

  /// Soumet le formulaire selon le mode actif (inscription ou connexion).
  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() {
      _error = null;
      _isLoading = true;
    });
    try {
      if (_isRegistering) {
        await _auth.register(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          displayName: _nameCtrl.text.trim(),
        );
      } else {
        await _auth.login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
      }
      // AuthGate détecte automatiquement le changement d'état → navigation
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _translateError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Traduit les codes d'erreur Firebase en messages lisibles.
  String _translateError(String code) => switch (code) {
        'email-already-in-use' => 'Email déjà utilisé.',
        'wrong-password' => 'Mot de passe incorrect.',
        'user-not-found' => 'Aucun compte avec cet email.',
        'weak-password' => 'Mot de passe trop faible (6 caractères min).',
        'invalid-email' => 'Format d\'email invalide.',
        'too-many-requests' => 'Trop de tentatives. Réessayez plus tard.',
        _ => 'Erreur : $code',
      };

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegistering ? 'Inscription' : 'Connexion'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            // Logo / Titre de l'app
            const Icon(Icons.chat_bubble_rounded,
                size: 64, color: Colors.orange),
            const SizedBox(height: 8),
            const Text(
              'ChatBoard',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // Champ pseudo — affiché uniquement en mode inscription
            if (_isRegistering) ...[
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pseudo *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Champ email
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            // Champ mot de passe
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 14),

            // Message d'erreur
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            // Bouton principal
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(_isRegistering ? 'Créer le compte' : 'Se connecter'),
            ),
            const SizedBox(height: 12),

            // Basculer entre inscription et connexion
            TextButton(
              onPressed: () => setState(() {
                _isRegistering = !_isRegistering;
                _error = null;
              }),
              child: Text(_isRegistering
                  ? 'Déjà un compte ? Se connecter'
                  : 'Pas de compte ? S\'inscrire'),
            ),
          ],
        ),
      ),
    );
  }
}
