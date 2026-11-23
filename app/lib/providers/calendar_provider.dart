import 'package:flutter/foundation.dart';

import '../models/calendar_event.dart';
import '../models/chat_message.dart';
import '../services/n8n_service.dart';
import 'session_provider.dart';

/// Estado de la pantalla de calendario: listado + asistente de fechas.
class CalendarProvider extends ChangeNotifier {
  CalendarProvider(this._service, this._session);

  final N8nService _service;
  final SessionProvider _session;

  List<CalendarEvent> _events = <CalendarEvent>[];
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  String? _categoria;
  String _texto = '';

  final List<ChatMessage> _messages = <ChatMessage>[];
  bool _asking = false;

  List<CalendarEvent> get events => List<CalendarEvent>.unmodifiable(_events);
  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;
  String? get categoria => _categoria;
  String get texto => _texto;
  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);
  bool get asking => _asking;

  static const List<Map<String, String?>> filters = <Map<String, String?>>[
    <String, String?>{'label': 'Todos', 'value': null},
    <String, String?>{'label': 'Matrícula', 'value': 'matricula'},
    <String, String?>{'label': 'Exámenes', 'value': 'examenes'},
    <String, String?>{'label': 'Clases', 'value': 'clases'},
    <String, String?>{'label': 'Pagos', 'value': 'pagos'},
    <String, String?>{'label': 'Ceremonia', 'value': 'ceremonia'},
    <String, String?>{'label': 'General', 'value': 'general'},
  ];

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (_loaded && !force) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _service.fetchCalendarEvents(
        texto: _texto.trim().isEmpty ? null : _texto.trim(),
        categoria: _categoria,
      );
      _loaded = true;
    } on N8nException catch (error) {
      _error = error.message;
    } catch (error) {
      _error = 'No se pudo cargar el calendario: $error';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setCategoria(String? categoria) async {
    if (_categoria == categoria) return;
    _categoria = categoria;
    _loaded = false;
    notifyListeners();
    await load(force: true);
  }

  Future<void> search(String texto) async {
    _texto = texto;
    _loaded = false;
    notifyListeners();
    await load(force: true);
  }

  Future<void> ask(String pregunta) async {
    final String clean = pregunta.trim();
    if (clean.isEmpty || _asking) return;

    _messages.add(ChatMessage.user(clean));
    _asking = true;
    notifyListeners();

    try {
      final ChatReply reply = await _service.sendCalendarChat(
        sessionId: _session.sessionId,
        pregunta: clean,
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
      _messages.add(ChatMessage.error('Error inesperado: $error'));
    } finally {
      _asking = false;
      notifyListeners();
    }
  }

  void reset() {
    _events = <CalendarEvent>[];
    _messages.clear();
    _loading = false;
    _loaded = false;
    _error = null;
    _categoria = null;
    _texto = '';
    _asking = false;
    notifyListeners();
  }
}
