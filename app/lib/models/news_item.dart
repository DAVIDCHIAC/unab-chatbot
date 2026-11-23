import '../utils/json_utils.dart';

/// Noticia o convocatoria (`unab.v_noticias_recientes`).
class NewsItem {
  const NewsItem({
    this.id,
    required this.titulo,
    this.resumen,
    this.url,
    this.fuente,
    this.categoria,
    this.fechaPublicacion,
    this.diasPublicada,
  });

  final int? id;
  final String titulo;
  final String? resumen;
  final String? url;
  final String? fuente;
  final String? categoria;
  final DateTime? fechaPublicacion;
  final int? diasPublicada;

  String get categoriaLabel {
    switch ((categoria ?? '').toLowerCase()) {
      case 'beca':
        return 'Beca';
      case 'convocatoria':
        return 'Convocatoria';
      case 'evento':
        return 'Evento';
      case 'curso':
        return 'Curso';
      default:
        return 'Noticia';
    }
  }

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: asInt(json['id']),
      titulo: asString(json['titulo']) ?? 'Publicación sin título',
      resumen: asString(json['resumen']),
      url: asString(json['url']),
      fuente: asString(json['fuente']),
      categoria: asString(json['categoria']),
      fechaPublicacion: asDate(json['fecha_publicacion']),
      diasPublicada: asInt(json['dias_publicada']),
    );
  }
}
