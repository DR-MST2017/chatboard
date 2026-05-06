// lib/models/message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle de données représentant un message dans ChatBoard.
/// Chaque message est stocké comme un Document dans la collection Firestore 'messages'.
class Message {
  final String id;           // ID auto-généré par Firestore
  final String text;         // Contenu du message
  final String uid;          // UID Firebase Auth de l'auteur
  final String displayName;  // Pseudo de l'auteur
  final Timestamp createdAt; // Horodatage serveur Firebase

  const Message({
    required this.id,
    required this.text,
    required this.uid,
    required this.displayName,
    required this.createdAt,
  });

  /// Constructeur factory : Document Firestore → objet Message Dart
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      text: data['text'] as String,
      uid: data['uid'] as String,
      displayName: data['displayName'] as String,
      createdAt: data['createdAt'] as Timestamp,
    );
  }

  /// Sérialisation : objet Message Dart → Map pour Firestore
  Map<String, dynamic> toMap() => {
        'text': text,
        'uid': uid,
        'displayName': displayName,
        'createdAt': createdAt,
      };
}
