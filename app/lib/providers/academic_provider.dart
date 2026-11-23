import 'package:flutter/foundation.dart';

import '../models/academic_summary.dart';
import '../models/chat_message.dart';
import '../services/n8n_service.dart';
import 'session_provider.dart';

/// Estado de la pantalla académica: resumen + asistente de historial.
class AcademicProvider extends ChangeNotifier {
  AcademicProvider(this._service, this._session);

  final N8nService _service;
  final SessionProvider _session;

  AcademicSummary? _summary;
  bool _loading = false;
  String? _error;

  final List<ChatMessage> _messages = <ChatMessage>[];
  bool _asking = false;

  AcademicSummary? get summary => _summary;
  bool get loading => _loading;
  String? get error => _error;
  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);
  bool get asking => _asking;

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (_summary != null && !force) return;

    final String? id = _session.studentId;
    if (id == null || id.isEmpty) {
      _error = 'Inicia sesión con tu código UNAB para ver tu avance.';
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final AcademicSummary summary = await _service.fetchAcademicSummary(id);
      if (!summary.ok || summary.isEmpty) {
        _summary = null;
        _error = summary.error ??
            'No se encontró información académica para el código $id.';
      } else {
        _summary = summary;
        final String? name = summary.estado?.nombreCompleto;
        if (name != null && name.isNotEmpty) {
          await _session.updateName(name);
        }
      }
    } on N8nException catch (error) {
      _error = error.message;
    } catch (error) {
      _error = 'No se pudo cargar el resumen académico: $error';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> ask(String pregunta) async {
    final String clean = pregunta.trim();
    if (clean.isEmpty || _asking) return;

    final String? id = _session.studentId;
    if (id == null || id.isEmpty) {
      _messages.add(
        ChatMessage.error('Necesito tu código UNAB para consultar tus datos.'),
      );
      notifyListeners();
      return;
    }

    _messages.add(ChatMessage.user(clean));
    _asking = true;
    notifyListeners();

    try {
      final ChatReply reply = await _service.sendAcademicChat(
        sessionId: _session.sessionId,
        idEstudiante: id,
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
    _summary = null;
    _messages.clear();
    _loading = false;
    _error = null;
    _asking = false;
    notifyListeners();
  }
}
