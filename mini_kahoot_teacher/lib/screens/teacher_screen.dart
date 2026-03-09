import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'edit_quiz_screen.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});
  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  String? gameId;
  int? gameCode;
  String gameStatus = 'none';

  int currentQuestionIndex = 0;
  int totalQuestions = 0;
  int timeLeft = 15;
  Timer? _timer;
  List<QueryDocumentSnapshot> _questions = [];

  final Color _surfaceColor = const Color(0xFF1E293B);
  final Color _primaryColor = const Color(0xFF8B5CF6); // Morado vibrante

  void _startQuestionTimer() {
    timeLeft = 15;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          timer.cancel();
          if (currentQuestionIndex + 1 < totalQuestions) {
            currentQuestionIndex++;
            FirebaseService.setGameState(gameId!, 'playing', currentQuestionIndex);
            _startQuestionTimer();
          } else {
            gameStatus = 'finished';
            FirebaseService.setGameState(gameId!, 'finished', currentQuestionIndex);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kahoot GarRen Profes', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Padding(
          key: ValueKey<String>(gameStatus),
          padding: const EdgeInsets.all(20),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (gameStatus == 'none') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
            ),
            icon: const Icon(Icons.add_circle_outline, size: 28),
            label: const Text('Crear nuevo Kahoot', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            onPressed: () {
              final titleController = TextEditingController();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: _surfaceColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Nuevo Kahoot'),
                  content: TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Ej: Examen de Historia',
                      filled: true,
                      fillColor: Colors.black12,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        if (titleController.text.isNotEmpty) {
                          final quizId = await FirebaseService.createQuiz(titleController.text);
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => EditQuizScreen(quizId: quizId, quizTitle: titleController.text)));
                        }
                      },
                      child: const Text('Crear', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          const Text('Kahoots disponibles', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 15),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.getQuizzesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('Aún no hay Kahoots. ¡Anímate a crear uno!', style: TextStyle(color: Colors.white54)));

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final quiz = docs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: _surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        title: Text(quiz['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: _surfaceColor,
                                    title: const Text('¿Borrar Kahoot?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                        onPressed: () { FirebaseService.deleteQuiz(quiz.id); Navigator.pop(context); },
                                        child: const Text('Borrar', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note, color: Colors.amberAccent, size: 28),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditQuizScreen(quizId: quiz.id, quizTitle: quiz['title']))),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                              child: const Text('Jugar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              onPressed: () async {
                                final id = await FirebaseService.createGame(quiz.id);
                                final doc = await FirebaseFirestore.instance.collection('games').doc(id).get();
                                _questions = await FirebaseService.getQuestions(quiz.id);
                                setState(() { gameId = id; gameCode = doc['code']; totalQuestions = doc['totalQuestions']; gameStatus = 'waiting'; });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    } 
    
    if (gameStatus == 'waiting') {
      return Column(
        children: [
          const Text('Únete con el PIN', style: TextStyle(fontSize: 20, color: Colors.white54)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(30), border: Border.all(color: _primaryColor, width: 2)),
            child: Text('$gameCode', style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 5)),
          ),
          const SizedBox(height: 40),
          const Text('Jugadores', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.playersStream(gameId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final players = snapshot.data!.docs;
                if (players.isEmpty) return const Center(child: Text('Esperando héroes...', style: TextStyle(color: Colors.white54, fontSize: 18)));
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: players.map((doc) => Chip(
                    label: Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: _primaryColor.withOpacity(0.2),
                    side: BorderSide(color: _primaryColor),
                  )).toList(),
                );
              },
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), minimumSize: const Size(double.infinity, 70), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
            onPressed: () {
              if (totalQuestions == 0) return;
              setState(() => gameStatus = 'playing');
              FirebaseService.setGameState(gameId!, 'playing', 0);
              _startQuestionTimer();
            },
            child: const Text('¡EMPEZAR JUEGO!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      );
    }

    if (gameStatus == 'playing') {
      final q = _questions[currentQuestionIndex];
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(color: _primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Text('Pregunta ${currentQuestionIndex + 1} de $totalQuestions', style: TextStyle(fontSize: 18, color: _primaryColor, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
            Text(q['question'], style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, height: 1.3), textAlign: TextAlign.center),
            const SizedBox(height: 60),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120, height: 120,
                  child: CircularProgressIndicator(value: timeLeft / 15, strokeWidth: 10, backgroundColor: _surfaceColor, color: timeLeft > 5 ? const Color(0xFF10B981) : Colors.redAccent),
                ),
                Text('$timeLeft', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      );
    }

    if (gameStatus == 'finished') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
          const SizedBox(height: 10),
          const Text('PODIO FINAL', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.amber, letterSpacing: 2)),
          const SizedBox(height: 40),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.podiumStream(gameId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final player = docs[index];
                    final isTop3 = index < 3;
                    final colors = [Colors.amber, Colors.blueGrey[300]!, const Color(0xFFCD7F32)]; // Oro, Plata, Bronce
                    final medalColor = isTop3 ? colors[index] : Colors.white24;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: medalColor, child: Text('${index + 1}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                        title: Text(player['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        trailing: Text('${player['score']} pts', style: const TextStyle(fontSize: 22, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      );
    }
    return const SizedBox();
  }
}