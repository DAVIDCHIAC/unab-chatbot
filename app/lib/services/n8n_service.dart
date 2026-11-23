import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/academic_summary.dart';
import '../models/calendar_event.dart';
import '../models/chat_message.dart';
import '../models/news_item.dart';
import '../utils/json_utils.dart';

/// Error controlado de la capa HTTP.
class N8nException implements Exception {
  N8nException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Cliente HTTP que habla con los webhooks de n8n.
///
/// Todos los endpoints comparten el mismo formato: `POST` con JSON y
/// respuesta JSON codificada en UTF-8.
class N8nService {
  N8nService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _headers = <String, String>{
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
    Duration timeout,
  ) async {
    final Uri uri = AppConfig.uri(path);
    late http.Response response;

    try {
      response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(timeout);
    } on TimeoutException {
      throw N8nException(
        'El servidor tardó más de ${timeout.inSeconds} s en responder. '
        'Verifica que los workflows estén activos e intenta de nuevo.',
      );
    } on SocketException {
      throw N8nException(
        'No se pudo conectar con n8n. Revisa tu conexión a internet y la URL '
        'configurada con --dart-define=N8N_BASE_URL.',
      );
    } on http.ClientException {
      throw N8nException('Error de red al contactar n8n. Intenta nuevamente.');
    }

    final String raw = utf8.decode(response.bodyBytes, allowMalformed: true);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String hint = '';
      if (response.statusCode == 404) {
        hint = ' El workflow no está activo o la ruta no existe.';
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        hint = ' Revisa la autenticación del webhook en n8n.';
      }
      throw N8nException(
        'n8n respondió ${response.statusCode}.$hint',
        statusCode: response.statusCode,
      );
    }

    if (raw.trim().isEmpty) {
      throw N8nException(
        'n8n devolvió una respuesta vacía. Revisa el nodo Respond to Webhook.',
      );
    }

    dynamic decoded = const <String, dynamic>{};
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw N8nException(
        'La respuesta de n8n no es JSON válido. ¿Activaste el workflow correcto?',
      );
    }

    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map(
        (dynamic key, dynamic value) => MapEntry(key.toString(), value),
      );
    }
    if (decoded is List) return <String, dynamic>{'data': decoded};

    throw N8nException('Formato de respuesta inesperado de n8n.');
  }

  // -------------------------------------------------------------------------
  // Conversación
  // -------------------------------------------------------------------------

  /// WF01 · Asistente RAG institucional.
  Future<ChatReply> sendRagChat({
    required String sessionId,
    required String pregunta,
    String? idEstudiante,
  }) async {
    final Map<String, dynamic> json = await _postJson(
      AppConfig.ragPath,
      <String, dynamic>{
        'session_id': sessionId,
        'pregunta': pregunta,
        if (idEstudiante != null && idEstudiante.isNotEmpty)
          'id_estudiante': idEstudiante,
        'canal': 'android',
      },
      AppConfig.chatTimeout,
    );
    return _reply(json);
  }

  /// WF02 · Asistente de calendario.
  Future<ChatReply> sendCalendarChat({
    required String sessionId,
    required String pregunta,
  }) async {
    final Map<String, dynamic> json = await _postJson(
      AppConfig.calendarPath,
      <String, dynamic>{
        'session_id': sessionId,
        'pregunta': pregunta,
        'canal': 'android',
      },
      AppConfig.chatTimeout,
    );
    return _reply(json);
  }

  /// WF03 · Asistente académico.
  Future<ChatReply> sendAcademicChat({
    required String sessionId,
    required String idEstudiante,
    required String pregunta,
  }) async {
    final Map<String, dynamic> json = await _postJson(
      AppConfig.academicPath,
      <String, dynamic>{
        'session_id': sessionId,
        'id_estudiante': idEstudiante,
        'pregunta': pregunta,
        'canal': 'android',
      },
      AppConfig.chatTimeout,
    );
    return _reply(json);
  }

  ChatReply _reply(Map<String, dynamic> json) {
    final ChatReply reply = ChatReply.fromJson(json);
    if (reply.respuesta.isEmpty) {
      throw N8nException(
        'El asistente no devolvió una respuesta. Intenta reformular tu pregunta.',
      );
    }
    return reply;
  }

  // -------------------------------------------------------------------------
  // Datos estructurados para los tableros
  // -------------------------------------------------------------------------

  /// WF02 · Listado de eventos del calendario.
  Future<List<CalendarEvent>> fetchCalendarEvents({
    String? texto,
    String? categoria,
  }) async {
    final Map<String, dynamic> json = await _postJson(
      AppConfig.calendarListPath,
      <String, dynamic>{
        if (texto != null && texto.trim().isNotEmpty) 'texto': texto.trim(),
        if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
      },
      AppConfig.listTimeout,
    );

    return asList(json['eventos'])
        .map((dynamic item) => CalendarEvent.fromJson(asMap(item)))
        .where((CalendarEvent item) => item.evento.isNotEmpty)
        .toList(growable: false);
  }

  /// WF03 · Resumen académico completo.
  Future<AcademicSummary> fetchAcademicSummary(String idEstudiante) async {
    final Map<String, dynamic> json = await _postJson(
      AppConfig.academicSummaryPath,
      <String, dynamic>{'id_estudiante': idEstudiante},
      AppConfig.listTimeout,
    );
    return AcademicSummary.fromJson(json);
  }

  /// WF04 · Noticias y convocatorias.
  Future<List<NewsItem>> fetchNews({
    String? texto,
    String? categoria,
  }) async {
    final Map<String, dynamic> json = await _postJson(
      AppConfig.newsPath,
      <String, dynamic>{
        if (texto != null && texto.trim().isNotEmpty) 'texto': texto.trim(),
        if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
        'canal': 'android',
      },
      AppConfig.listTimeout,
    );

    if (!asBool(json['ok']) && json['noticias'] == null) {
      throw N8nException(
        asString(json['error']) ?? 'No se pudieron cargar las noticias.',
      );
    }

    return asList(json['noticias'])
        .map((dynamic item) => NewsItem.fromJson(asMap(item)))
        .where((NewsItem item) => item.titulo.isNotEmpty)
        .toList(growable: false);
  }
}
