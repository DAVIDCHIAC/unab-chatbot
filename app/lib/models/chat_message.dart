import '../utils/json_utils.dart';

/// Rol del autor de un mensaje del chat.
enum MessageRole { user, assistant }

/// Mensaje mostrado en las pantallas de conversación.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isError = false,
    this.tipo,
    this.latencyMs,
  });

  final String id;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final bool isError;
  final String? tipo;
  final int? latencyMs;

  bool get isUser => role == MessageRole.user;

  static int _sequence = 0;

  static String _newId() {
    _sequence += 1;
    return 'msg-${DateTime.now().microsecondsSinceEpoch}-$_sequence';
  }

  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: _newId(),
      role: MessageRole.user,
      content: content,
      createdAt: DateTime.now(),
    );
  }

  factory ChatMessage.assistant(
    String content, {
    String? tipo,
    int? latencyMs,
  }) {
    return ChatMessage(
      id: _newId(),
      role: MessageRole.assistant,
      content: content,
      createdAt: DateTime.now(),
      tipo: tipo,
      latencyMs: latencyMs,
    );
  }

  factory ChatMessage.error(String content) {
    return ChatMessage(
      id: _newId(),
      role: MessageRole.assistant,
      content: content,
      createdAt: DateTime.now(),
      isError: true,
    );
  }
}

/// Respuesta normalizada de los webhooks conversacionales de n8n.
class ChatReply {
  const ChatReply({
    required this.sessionId,
    required this.tipo,
    required this.respuesta,
    required this.latencyMs,
  });

  final String sessionId;
  final String tipo;
  final String respuesta;
  final int latencyMs;

  factory ChatReply.fromJson(Map<String, dynamic> json) {
    return ChatReply(
      sessionId: asString(json['session_id']) ?? '',
      tipo: asString(json['tipo']) ?? 'rag',
      respuesta: asString(json['respuesta']) ?? '',
      latencyMs: asInt(json['latencia_ms']) ?? 0,
    );
  }
}
