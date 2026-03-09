import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<void> login() async {
    if (_auth.currentUser == null) await _auth.signInAnonymously();
  }

  // Ahora devolvemos un Map con gameId y playerId
  static Future<Map<String, String>?> joinGame(int code, String name) async {
    await login();
    final query = await _db.collection('games').where('code', isEqualTo: code).where('status', isEqualTo: 'waiting').get();
    if (query.docs.isEmpty) return null;

    final gameId = query.docs.first.id;
    // Añadimos el campo score: 0 al entrar
    final playerDoc = await _db.collection('games').doc(gameId).collection('players').add({
      'name': name,
      'score': 0, 
      'joinedAt': FieldValue.serverTimestamp(),
    });

    return {'gameId': gameId, 'playerId': playerDoc.id};
  }

  static Stream<DocumentSnapshot> gameStream(String gameId) {
    return _db.collection('games').doc(gameId).snapshots();
  }

  static Future<List<QueryDocumentSnapshot>> getQuestions(String quizId) async {
    final query = await _db.collection('quizzes').doc(quizId).collection('questions').get();
    return query.docs;
  }

  // Función para sumar 100 puntos si acierta
  static Future<void> addScore(String gameId, String playerId) async {
    await _db.collection('games').doc(gameId).collection('players').doc(playerId).update({
      'score': FieldValue.increment(100)
    });
  }
}