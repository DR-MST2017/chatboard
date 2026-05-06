// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // flutter pub add intl
import '../models/message.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Écran principal de ChatBoard — affiche les messages en temps réel,
/// permet d'envoyer, modifier et supprimer ses propres messages,
/// et filtrer entre "Tous les messages" et "Mes messages".
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = AuthService();
  final _firestore = FirestoreService();
  final _msgCtrl = TextEditingController();

  // État du filtre : false = tous les messages, true = seulement les miens
  bool _myMessagesOnly = false;

  /// Envoie un message dans Firestore avec l'identité de l'utilisateur connecté.
  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    _msgCtrl.clear(); // Vide le champ avant l'envoi (UX fluide)

    final user = _auth.currentUser!;
    await _firestore.sendMessage(
      text: text,
      uid: user.uid,
      displayName: user.displayName ?? 'Anonyme',
    );
  }

  /// Affiche un dialog pour modifier le texte d'un message existant.
  void _showEditDialog(BuildContext context, Message msg) {
    final ctrl = TextEditingController(text: msg.text);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier le message'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = ctrl.text.trim();
              if (newText.isNotEmpty) {
                _firestore.updateMessage(msg.id, newText);
              }
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  /// Affiche une confirmation avant suppression.
  void _confirmDelete(BuildContext context, Message msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce message ?'),
        content: Text('"${msg.text}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _firestore.deleteMessage(msg.id);
              Navigator.pop(context);
            },
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: Text(
          _myMessagesOnly
              ? 'Mes messages'
              : 'ChatBoard — ${_auth.currentUser?.displayName ?? ''}',
        ),
        actions: [
          // Bouton filtre "Mes messages / Tous les messages"
          IconButton(
            icon: Icon(_myMessagesOnly ? Icons.people : Icons.person),
            tooltip: _myMessagesOnly ? 'Tous les messages' : 'Mes messages',
            onPressed: () =>
                setState(() => _myMessagesOnly = !_myMessagesOnly),
          ),
          // Bouton déconnexion
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () => _auth.logout(),
          ),
        ],
      ),

      // Liste des messages — StreamBuilder écoute Firestore en temps réel
      body: StreamBuilder<List<Message>>(
        stream: _myMessagesOnly
            ? _firestore.getMyMessages(currentUid!)
            : _firestore.getMessages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final messages = snapshot.data ?? [];

          if (messages.isEmpty) {
            return const Center(
              child: Text(
                'Soyez le premier à écrire !',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            reverse: true, // Messages récents en bas de la liste
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isMe = msg.uid == currentUid;
              // Formater l'heure : HH:mm
              final time =
                  DateFormat('HH:mm').format(msg.createdAt.toDate());

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isMe ? Colors.orange : Colors.blueGrey,
                  child: Text(
                    msg.displayName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      msg.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.orange : Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                subtitle: Text(msg.text),
                // Boutons Modifier/Supprimer — UNIQUEMENT pour ses propres messages
                trailing: isMe
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon:
                                const Icon(Icons.edit, size: 18),
                            onPressed: () => _showEditDialog(context, msg),
                            tooltip: 'Modifier',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 18, color: Colors.red),
                            onPressed: () => _confirmDelete(context, msg),
                            tooltip: 'Supprimer',
                          ),
                        ],
                      )
                    : null,
              );
            },
          );
        },
      ),

      // Champ d'envoi de message en bas de l'écran
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Votre message...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.orange),
                onPressed: _send,
                tooltip: 'Envoyer',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
