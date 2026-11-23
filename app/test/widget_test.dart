import 'package:flutter_test/flutter_test.dart';
import 'package:unab_chatbot/models/academic_summary.dart';
import 'package:unab_chatbot/models/calendar_event.dart';
import 'package:unab_chatbot/models/news_item.dart';
import 'package:unab_chatbot/utils/json_utils.dart';

void main() {
  group('json_utils', () {
    test('normaliza números y fechas con tipos mixtos', () {
      expect(asInt('12'), 12);
      expect(asInt(3.6), 4);
      expect(asDouble('3.69'), 3.69);
      expect(asDate('2026-02-09T00:00:00.000Z'), isNotNull);
      expect(asBool('sí'), isTrue);
      expect(asBool(0), isFalse);
      expect(asString('  '), isNull);
    });

    test('tolera mapas y listas que no son del tipo esperado', () {
      expect(asMap(null), isEmpty);
      expect(asMap(<dynamic, dynamic>{'a': 1})['a'], 1);
      expect(asList('no-es-lista'), isEmpty);
    });
  });

  group('AcademicSummary', () {
    test('parsea el payload real de WF03', () {
      final AcademicSummary summary = AcademicSummary.fromJson(
        <String, dynamic>{
          'ok': true,
          'estado': <String, dynamic>{
            'id_estudiante': '10045234',
            'nombre_completo': 'Jhon García',
            'programa': 'Ingeniería de Sistemas',
            'semestre_actual': 3,
            'estado_estudiante': 'activo',
            'promedio_acumulado': '3.69',
            'cursos_registrados': 9,
            'cursos_aprobados': 6,
            'cursos_en_curso': 2,
            'cursos_reprobados': 1,
            'creditos_aprobados': 30,
            'creditos_en_curso': 8,
          },
          'avance': <String, dynamic>{
            'programa': 'Ingeniería de Sistemas',
            'creditos_totales': 160,
            'semestres_totales': 9,
            'semestre_actual': 3,
            'creditos_aprobados': 30,
            'creditos_pendientes': 130,
            'porcentaje_avance': '18.8',
            'promedio_acumulado': 3.69,
          },
          'proyeccion': <String, dynamic>{
            'creditos_totales': 160,
            'creditos_aprobados': 30,
            'creditos_en_curso': 8,
            'creditos_restantes': 122,
            'ritmo_creditos_semestre': 15.0,
            'semestres_restantes_estimados': 8,
            'semestre_proyectado_grado': 11,
            'porcentaje_avance': 18.8,
          },
          // `v_alertas_academicas` llega como json_agg (arreglo de una fila).
          'alertas': <dynamic>[
            <String, dynamic>{
              'cursos_reprobados': 1,
              'cursos_bloqueados': 6,
              'cursos_en_curso': 2,
              'alertas': <String>[
                'Tienes IS201 Cálculo Integral reprobado.',
                'IS301 Cálculo Multivariado está bloqueado.',
              ],
            },
          ],
          'bloqueados': <dynamic>[
            <String, dynamic>{
              'curso_bloqueado': 'IS301',
              'nombre_curso': 'Cálculo Multivariado',
              'semestre_sugerido': 4,
              'codigo_prerequisito': 'IS201',
              'nombre_prerequisito': 'Cálculo Integral',
              'estado_prerequisito': 'reprobado',
              'tipo_bloqueo': 'prerrequisito_reprobado',
              'nota_prerequisito': '2.4',
            },
          ],
          'historial': <dynamic>[
            <String, dynamic>{
              'codigo_curso': 'IS201',
              'curso': 'Cálculo Integral',
              'creditos': 4,
              'semestre_sugerido': 2,
              'area': 'Ciencias Básicas',
              'periodo': '2025-20',
              'nota': 2.4,
              'estado': 'reprobado',
              'intento': 1,
            },
          ],
        },
      );

      expect(summary.ok, isTrue);
      expect(summary.estado?.nombreCompleto, 'Jhon García');
      expect(summary.estado?.promedioAcumulado, 3.69);
      expect(summary.avance?.porcentajeAvance, 18.8);
      expect(summary.proyeccion?.semestreProyectadoGrado, 11);
      expect(summary.alertas?.hasAlerts, isTrue);
      expect(summary.alertas?.mensajes, hasLength(2));
      expect(summary.bloqueados, hasLength(1));
      expect(summary.bloqueados.first.tipoBloqueoLabel,
          'Prerrequisito reprobado');
      expect(summary.historial.single.aprobado, isFalse);
      expect(summary.historial.single.estadoLabel, 'Reprobado');
    });

    test('acepta alertas como objeto plano y descarta filas vacías', () {
      final AcademicSummary summary = AcademicSummary.fromJson(
        <String, dynamic>{
          'ok': true,
          'estado': <String, dynamic>{'id_estudiante': '1'},
          'alertas': <String, dynamic>{
            'cursos_reprobados': 0,
            'cursos_bloqueados': 0,
            'cursos_en_curso': 0,
            'alertas': <String>[],
          },
          'bloqueados': <dynamic>[
            <String, dynamic>{'curso_bloqueado': ''},
          ],
          'historial': <dynamic>[
            <String, dynamic>{'codigo_curso': ''},
          ],
        },
      );

      expect(summary.alertas?.hasAlerts, isFalse);
      expect(summary.bloqueados, isEmpty);
      expect(summary.historial, isEmpty);
    });

    test('marca ok=false cuando no hay estado', () {
      final AcademicSummary summary = AcademicSummary.fromJson(
        <String, dynamic>{'ok': true},
      );
      expect(summary.ok, isFalse);
      expect(summary.isEmpty, isTrue);
    });
  });

  group('modelos de listas', () {
    test('NewsItem etiqueta la categoría', () {
      final NewsItem item = NewsItem.fromJson(<String, dynamic>{
        'titulo': 'Beca de excelencia 2026-10',
        'categoria': 'beca',
        'fecha_publicacion': '2026-11-01',
        'dias_publicada': 3,
      });
      expect(item.titulo, 'Beca de excelencia 2026-10');
      expect(item.categoriaLabel, 'Beca');
      expect(item.diasPublicada, 3);
    });

    test('CalendarEvent detecta rangos de fechas', () {
      final CalendarEvent event = CalendarEvent.fromJson(<String, dynamic>{
        'evento': 'Semana de exámenes finales',
        'categoria': 'examenes',
        'fecha_inicio': '2026-11-23',
        'fecha_fin': '2026-11-28',
        'dias_faltantes': 6,
      });
      expect(event.categoriaLabel, 'Exámenes');
      expect(event.hasRange, isTrue);
      expect(event.diasFaltantes, 6);
    });
  });
}
