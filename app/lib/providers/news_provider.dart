import 'package:flutter/foundation.dart';

import '../models/news_item.dart';
import '../services/n8n_service.dart';

/// Estado de la pantalla de noticias y convocatorias (WF04).
class NewsProvider extends ChangeNotifier {
  NewsProvider(this._service);

  final N8nService _service;

  List<NewsItem> _items = <NewsItem>[];
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  String? _categoria;
  String _texto = '';

  List<NewsItem> get items => List<NewsItem>.unmodifiable(_items);
  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;
  String? get categoria => _categoria;
  String get texto => _texto;

  static const List<Map<String, String?>> filters = <Map<String, String?>>[
    <String, String?>{'label': 'Todas', 'value': null},
    <String, String?>{'label': 'Convocatorias', 'value': 'convocatoria'},
    <String, String?>{'label': 'Becas', 'value': 'beca'},
    <String, String?>{'label': 'Eventos', 'value': 'evento'},
    <String, String?>{'label': 'Cursos', 'value': 'curso'},
    <String, String?>{'label': 'Noticias', 'value': 'noticia'},
  ];

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (_loaded && !force) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _service.fetchNews(
        texto: _texto.trim().isEmpty ? null : _texto.trim(),
        categoria: _categoria,
      );
      _loaded = true;
    } on N8nException catch (error) {
      _error = error.message;
    } catch (error) {
      _error = 'No se pudieron cargar las noticias: $error';
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

  void reset() {
    _items = <NewsItem>[];
    _loading = false;
    _loaded = false;
    _error = null;
    _categoria = null;
    _texto = '';
    notifyListeners();
  }
}
