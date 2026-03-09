import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<void> login() async {
    if (_auth.currentUser == null) await _auth.signInAnonymously();
  }

  static Future<int> generateUniqueCode() async {
    int code;
    bool exists;
    do {
      code = Random().nextInt(900000) + 100000;
      final query = await _db.collection('games').where('code', isEqualTo: code).get();
      exists = query.docs.isNotEmpty;
    } while (exists);
    return code;
  }

  static Future<String> createGame(String quizId) async {
    await login();
    // Averiguamos cuántas preguntas tiene este Kahoot antes de empezar
    final questionsQuery = await _db.collection('quizzes').doc(quizId).collection('questions').get();
    
    final code = await generateUniqueCode();
    final doc = await _db.collection('games').add({
      'code': code,
      'quizId': quizId,
      'status': 'waiting', // Estados: waiting, playing, finished
      'currentQuestion': 0,
      'totalQuestions': questionsQuery.docs.length,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // Avanzar a la siguiente pregunta (o terminar si ya no hay más)
  static Future<void> setGameState(String gameId, String status, int questionIndex) async {
    await _db.collection('games').doc(gameId).update({
      'status': status,
      'currentQuestion': questionIndex,
    });
  }

  // Obtener preguntas
  static Future<List<QueryDocumentSnapshot>> getQuestions(String quizId) async {
    final query = await _db.collection('quizzes').doc(quizId).collection('questions').get();
    return query.docs;
  }

  // Podio: Obtener jugadores ordenados por puntuación
  static Stream<QuerySnapshot> podiumStream(String gameId) {
    return _db.collection('games').doc(gameId).collection('players').orderBy('score', descending: true).snapshots();
  }

  static Future<String> createQuiz(String title) async {
    await login();
    final doc = await _db.collection('quizzes').add({
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  static Future<void> addQuestion(String quizId, String question, String optA, String optB, String correct) async {
    await _db.collection('quizzes').doc(quizId).collection('questions').add({
      'question': question, 'optionA': optA, 'optionB': optB, 'correctOption': correct,
    });
  }

  static Stream<QuerySnapshot> getQuizzesStream() {
    return _db.collection('quizzes').orderBy('createdAt', descending: true).snapshots();
  }

  static Stream<QuerySnapshot> playersStream(String gameId) {
    return _db.collection('games').doc(gameId).collection('players').snapshots();
  }

  // Escuchar las preguntas en tiempo real para la pantalla de edición
  static Stream<QuerySnapshot> questionsStream(String quizId) {
    return _db.collection('quizzes').doc(quizId).collection('questions').snapshots();
  }

  // Borrar una pregunta específica
  static Future<void> deleteQuestion(String quizId, String questionId) async {
    await _db.collection('quizzes').doc(quizId).collection('questions').doc(questionId).delete();
  }

  static Future<void> deleteQuiz(String quizId) async {
    await _db.collection('quizzes').doc(quizId).delete();
  }
}