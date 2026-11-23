import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../services/n8n_service.dart';
import 'session_provider.dart';

/// Estado del chat general (WF01 · RAG institucional).
class ChatProvider extends ChangeNotifier {
  ChatProvider(this._service, this._session);

  final N8nService _service;
  final SessionProvider _session;

  final List<ChatMessage> _messages = <ChatMessage>[];
  bool _sending = false;

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);
  bool get sending => _sending;

  static const String welcome =
      '¡Hola! Soy **UNAB Bot**, tu asistente académico virtual. 👋\n\n'
      'Puedo ayudarte con:\n'
      '- Trámites, reglamento estudiantil y servicios\n'
      '- Fechas del calendario académico\n'
      '- Tu historial, avance y recomendación de matrícula\n'
      '- Noticias, becas y convocatorias\n\n'
      '¿Qué necesitas saber hoy?';

  static const List<String> suggestions = <String>[
    '¿Cuáles son los requisitos de grado?',
    '¿Cuándo es la matrícula del próximo semestre?',
    '¿Qué becas ofrece la UNAB?',
    '¿Cuál es mi avance académico?',
  ];

  void seedWelcome() {
    if (_messages.isNotEmpty) return;
    _messages.add(ChatMessage.assistant(welcome, tipo: 'menu'));
    notifyListeners();
  }

  Future<void> send(String text) async {
    final String pregunta = text.trim();
    if (pregunta.isEmpty || _sending) return;

    _messages.add(ChatMessage.user(pregunta));
    _sending = true;
    notifyListeners();

    try {
      final ChatReply reply = await _service.sendRagChat(
        sessionId: _session.sessionId,
        pregunta: pregunta,
        idEstudiante: _session.studentId,
      );
      _messages.add(
        ChatMessage.assistant(
          reply.respuesta,
          tipo: reply.tipo,
          latencyMs: reply.latencyMs,
        ),
      );
    } on N8nException catch (error) {
      _messages.add(ChatMessage.error(error.message));
    } catch (error) {
      _messages.add(
        ChatMessage.error('Ocurrió un error inesperado: $error'),
      );
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<void> clear() async {
    _messages.clear();
    await _session.newSession();
    seedWelcome();
    notifyListeners();
  }

  void reset() {
    _messages.clear();
    _sending = false;
    notifyListeners();
  }
}
