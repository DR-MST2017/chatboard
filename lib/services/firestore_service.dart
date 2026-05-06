// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

/// Service Firestore — gère toutes les opérations CRUD sur la collection 'messages'.
/// Fournit des streams temps réel (snapshots) et des méthodes de requête.
class FirestoreService {
  final _db = FirebaseFirestore.instance;

  /// Référence à la collection Firestore 'messages'.
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('messages');

  // ─────────────────────────────────────────────────────────────
  // READ — Streams temps réel
  // ─────────────────────────────────────────────────────────────

  /// Tous les messages, triés par date décroissante, limités à 50.
  /// .snapshots() → Stream<QuerySnapshot> émis à chaque changement Firestore.
  /// .map() transforme chaque snapshot en List<Message> typée.
  Stream<List<Message>> getMessages() {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => Message.fromFirestore(d)).toList());
  }

  /// Uniquement les messages de l'utilisateur connecté (filtre par uid).
  /// ⚠️ Nécessite un index composite Firestore sur (uid, createdAt).
  /// Au premier lancement, l'erreur console fournit le lien pour créer l'index.
  Stream<List<Message>> getMyMessages(String uid) {
    return _col
        .where('uid', isEqualTo: uid) // filtre par auteur
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => Message.fromFirestore(d)).toList());
  }

  // ─────────────────────────────────────────────────────────────
  // CREATE — Envoi d'un message
  // ─────────────────────────────────────────────────────────────

  /// Ajoute un nouveau message dans Firestore.
  /// FieldValue.serverTimestamp() → horodatage côté serveur Firebase (fiable).
  /// À préférer à DateTime.now() (horloge locale potentiellement incorrecte).
  Future<void> sendMessage({
    required String text,
    required String uid,
    required String displayName,
  }) async {
    await _col.add({
      'text': text,
      'uid': uid,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE — Modification d'un message
  // ─────────────────────────────────────────────────────────────

  /// Met à jour uniquement le champ 'text' d'un message existant.
  /// .update() modifie seulement les champs spécifiés — les autres restent intacts.
  Future<void> updateMessage(String docId, String newText) async {
    await _col.doc(docId).update({'text': newText});
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE — Suppression d'un message
  // ─────────────────────────────────────────────────────────────

  /// Supprime un message de Firestore.
  /// StreamBuilder re-émet automatiquement la liste mise à jour.
  Future<void> deleteMessage(String docId) async {
    await _col.doc(docId).delete();
  }
}
