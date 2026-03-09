import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class EditQuizScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;

  const EditQuizScreen({super.key, required this.quizId, required this.quizTitle});

  @override
  State<EditQuizScreen> createState() => _EditQuizScreenState();
}

class _EditQuizScreenState extends State<EditQuizScreen> {
  final _questionController = TextEditingController();
  final _optAController = TextEditingController();
  final _optBController = TextEditingController();
  String _correctOption = 'A';

  final Color _surfaceColor = const Color(0xFF1E293B);

  void _guardarPregunta() async {
    if (_questionController.text.isEmpty || _optAController.text.isEmpty) return;
    
    await FirebaseService.addQuestion(
      widget.quizId, _questionController.text, _optAController.text, _optBController.text, _correctOption,
    );

    _questionController.clear(); _optAController.clear(); _optBController.clear();
    setState(() => _correctOption = 'A');
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.quizTitle, style: const TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          // ZONA DE CREACIÓN
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _surfaceColor, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _questionController,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(hintText: '¿Cuál es la pregunta?', filled: true, fillColor: Colors.black12, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _optAController, decoration: InputDecoration(hintText: 'Opción A', filled: true, fillColor: const Color(0xFFEF4444).withOpacity(0.1), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _optBController, decoration: InputDecoration(hintText: 'Opción B', filled: true, fillColor: const Color(0xFF3B82F6).withOpacity(0.1), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)))),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Text('Correcta:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('A', style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: _correctOption == 'A',
                      selectedColor: const Color(0xFFEF4444),
                      onSelected: (val) => setState(() => _correctOption = 'A'),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('B', style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: _correctOption == 'B',
                      selectedColor: const Color(0xFF3B82F6),
                      onSelected: (val) => setState(() => _correctOption = 'B'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: _guardarPregunta,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Añadir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // ZONA DE LISTA
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.questionsStream(widget.quizId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('Aún no hay preguntas. ¡Crea la primera!', style: TextStyle(color: Colors.white54)));

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final q = docs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        title: Text(q['question'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('A: ${q['optionA']}\nB: ${q['optionB']}', style: const TextStyle(height: 1.5)),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => FirebaseService.deleteQuestion(widget.quizId, q.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}