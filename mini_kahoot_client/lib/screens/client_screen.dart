import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});
  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  
  String? _gameId;
  String? _playerId;
  int _answeredQuestionIndex = -1; 
  
  final Color _surfaceColor = const Color(0xFF1E293B);

  void _join() async {
    final code = int.tryParse(_codeController.text.trim());
    if (code == null) return;

    final ids = await FirebaseService.joinGame(code, _nameController.text.trim());
    if (ids != null) {
      setState(() {
        _gameId = ids['gameId'];
        _playerId = ids['playerId'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _gameId == null ? _buildJoinForm() : _buildGameStream(),
        ),
      ),
    );
  }

  Widget _buildJoinForm() {
    return Center(
      key: const ValueKey('join'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gamepad_rounded, size: 80, color: Color(0xFF8B5CF6)),
            const SizedBox(height: 20),
            const Text('Kahoot GarRen', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15)]),
              child: Column(
                children: [
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(hintText: 'PIN del juego', filled: true, fillColor: Colors.black12, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20),
                    decoration: InputDecoration(hintText: 'Tu apodo', filled: true, fillColor: Colors.black12, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: _join,
                    child: const Text('Entrar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameStream() {
    return StreamBuilder<DocumentSnapshot>(
      key: const ValueKey('stream'),
      stream: FirebaseService.gameStream(_gameId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final gameData = snapshot.data!.data() as Map<String, dynamic>?;
        if (gameData == null) return const Center(child: Text('Error de conexión'));

        final status = gameData['status'];
        final quizId = gameData['quizId'];
        final currentQuestion = gameData['currentQuestion'];

        if (status == 'waiting') {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              SizedBox(height: 30),
              Text('¡Estás dentro!\nMira la pantalla principal', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ));
        } 
        
        if (status == 'finished') {
          return const Center(child: Text('¡FIN DEL JUEGO!\nMira el podio 🏆', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.amber)));
        }

        return FutureBuilder<List<QueryDocumentSnapshot>>(
          future: FirebaseService.getQuestions(quizId),
          builder: (context, qSnapshot) {
            if (!qSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final q = qSnapshot.data![currentQuestion];

            if (_answeredQuestionIndex == currentQuestion) {
              return const Center(child: Text('Respuesta enviada.\nEsperando al resto...', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white54)));
            }

            // BOTONERA ESTILO KAHOOT
            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 5),
                    child: Material(
                      color: const Color(0xFFEF4444), // Rojo
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _responder('A', q['correctOption'], currentQuestion),
                        child: Center(child: Text(q['optionA'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 10),
                    child: Material(
                      color: const Color(0xFF3B82F6), // Azul
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _responder('B', q['correctOption'], currentQuestion),
                        child: Center(child: Text(q['optionB'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _responder(String elegida, String correcta, int questionIndex) {
    setState(() => _answeredQuestionIndex = questionIndex); 
    
    final acierto = elegida == correcta;
    if (acierto) FirebaseService.addScore(_gameId!, _playerId!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(acierto ? '¡CORRECTO! 🔥 +100pts' : '¡FALLASTE! 🧊', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
        backgroundColor: acierto ? const Color(0xFF10B981) : const Color(0xFFEF4444), 
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}