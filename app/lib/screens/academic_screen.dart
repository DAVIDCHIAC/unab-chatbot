import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/academic_summary.dart';
import '../providers/academic_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/ask_panel.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/section_title.dart';
import '../widgets/surface_card.dart';

/// Historial y avance académico (WF03).
class AcademicScreen extends StatefulWidget {
  const AcademicScreen({super.key});

  @override
  State<AcademicScreen> createState() => _AcademicScreenState();
}

class _AcademicScreenState extends State<AcademicScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AcademicProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AcademicProvider provider = context.watch<AcademicProvider>();
    final AcademicSummary? summary = provider.summary;

    return RefreshIndicator(
      onRefresh: () => provider.load(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          if (provider.loading && summary == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.error != null && summary == null)
            ErrorState(
              message: provider.error!,
              onRetry: () => provider.load(force: true),
            )
          else if (summary == null)
            EmptyState(
              icon: Icons.school_outlined,
              title: 'Sin información académica',
              message: 'No encontramos datos para tu código UNAB.',
              action: OutlinedButton.icon(
                onPressed: () => provider.load(force: true),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            )
          else ...<Widget>[
            if (summary.estado != null)
              _StudentHeader(
                state: summary.estado!,
                progress: summary.avance,
              ),
            const SizedBox(height: 14),
            _StatsGrid(summary: summary),
            if (summary.alertas?.hasAlerts ?? false) ...<Widget>[
              const SizedBox(height: 14),
              _AlertsCard(alert: summary.alertas!),
            ],
            if (summary.bloqueados.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              _BlockedCard(blocked: summary.bloqueados),
            ],
            if (summary.proyeccion != null) ...<Widget>[
              const SizedBox(height: 14),
              _ProjectionCard(projection: summary.proyeccion!),
            ],
            const SizedBox(height: 14),
            _HistoryCard(entries: summary.historial),
            const SizedBox(height: 18),
            const SectionTitle(
              title: 'Asistente académico',
              subtitle: 'Pregunta por notas, bloqueos o matrícula',
            ),
            AskPanel(
              title: 'UNAB Académico',
              hint: 'Ej. ¿Qué cursos puedo matricular?',
              icon: Icons.psychology_alt,
              messages: provider.messages,
              sending: provider.asking,
              onSend: provider.ask,
              suggestions: const <String>[
                '¿Cuál es mi avance?',
                '¿Qué cursos tengo bloqueados?',
                '¿Qué puedo matricular el próximo semestre?',
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({required this.state, this.progress});

  final AcademicState state;
  final AcademicProgress? progress;

  String get _initials {
    final List<String> parts = state.nombreCompleto
        .split(' ')
        .where((String part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final double avance =
        ((progress?.porcentajeAvance ?? 0) / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppColors.red, AppColors.darkRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      state.nombreCompleto,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.programa,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              _HeroMetric(
                label: 'Semestre',
                value: Formatters.integer(state.semestreActual),
              ),
              _HeroMetric(
                label: 'Promedio',
                value: Formatters.decimal(state.promedioAcumulado, digits: 2),
              ),
              _HeroMetric(
                label: 'Avance',
                value: Formatters.percent(progress?.porcentajeAvance),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: avance,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${Formatters.integer(progress?.creditosAprobados)} de '
            '${Formatters.integer(progress?.creditosTotales)} créditos aprobados',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.summary});

  final AcademicSummary summary;

  @override
  Widget build(BuildContext context) {
    final double width = (MediaQuery.of(context).size.width - 44) / 2;
    final AcademicState? state = summary.estado;
    final AcademicProgress? progress = summary.avance;
    final AcademicProjection? projection = summary.proyeccion;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        SizedBox(
          width: width,
          child: _StatCard(
            icon: Icons.check_circle_outline,
            color: AppColors.green,
            label: 'Créditos aprobados',
            value: Formatters.integer(
              progress?.creditosAprobados ?? state?.creditosAprobados,
            ),
          ),
        ),
        SizedBox(
          width: width,
          child: _StatCard(
            icon: Icons.pending_actions,
            color: AppColors.amber,
            label: 'Créditos pendientes',
            value: Formatters.integer(
              progress?.creditosPendientes ?? projection?.creditosRestantes,
            ),
          ),
        ),
        SizedBox(
          width: width,
          child: _StatCard(
            icon: Icons.menu_book_outlined,
            color: AppColors.blue,
            label: 'Cursos aprobados',
            value: Formatters.integer(state?.cursosAprobados),
          ),
        ),
        SizedBox(
          width: width,
          child: _StatCard(
            icon: Icons.timelapse,
            color: const Color(0xFF7C3AED),
            label: 'Semestres restantes',
            value: Formatters.integer(projection?.semestresRestantesEstimados),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.alert});

  final AcademicAlert alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3D9A4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.amber),
              SizedBox(width: 8),
              Text(
                'Alertas académicas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...alert.mensajes.map(
            (String message) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('•  ', style: TextStyle(color: AppColors.amber)),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedCard extends StatelessWidget {
  const _BlockedCard({required this.blocked});

  final List<BlockedCourse> blocked;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.lock_outline, size: 20, color: AppColors.red),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Cursos bloqueados por prerrequisito',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${blocked.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...blocked.map(
            (BlockedCourse course) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${course.cursoBloqueado} · ${course.nombreCurso}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Requiere ${course.codigoPrerequisito} · '
                    '${course.nombrePrerequisito} '
                    '(${course.estadoPrerequisito}'
                    '${course.notaPrerequisito != null ? ' · nota ${Formatters.decimal(course.notaPrerequisito)}' : ''})',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.darkRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({required this.projection});

  final AcademicProjection projection;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.trending_up, size: 20, color: AppColors.blue),
              SizedBox(width: 8),
              Text(
                'Proyección de grado',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProjectionRow(
            label: 'Ritmo actual',
            value:
                '${Formatters.decimal(projection.ritmoCreditosSemestre)} créditos/semestre',
          ),
          _ProjectionRow(
            label: 'Créditos restantes',
            value: Formatters.integer(projection.creditosRestantes),
          ),
          _ProjectionRow(
            label: 'Semestres estimados',
            value: Formatters.integer(projection.semestresRestantesEstimados),
          ),
          _ProjectionRow(
            label: 'Grado proyectado',
            value: projection.semestreProyectadoGrado == null
                ? '—'
                : 'Semestre ${projection.semestreProyectadoGrado}',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _ProjectionRow extends StatelessWidget {
  const _ProjectionRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entries});

  final List<HistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionTitle(
            title: 'Historial reciente',
            subtitle: entries.isEmpty
                ? 'Sin registros'
                : '${entries.length} registros más recientes',
          ),
          if (entries.isEmpty)
            const Text(
              'Aún no hay cursos registrados en tu historial.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            )
          else
            ...List<Widget>.generate(entries.length, (int index) {
              final HistoryEntry entry = entries[index];
              return Column(
                children: <Widget>[
                  _HistoryRow(entry: entry),
                  if (index < entries.length - 1)
                    const Divider(height: 1, color: AppColors.border),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final HistoryEntry entry;

  Color get _color {
    switch (entry.estado) {
      case 'aprobado':
      case 'homologado':
        return AppColors.green;
      case 'reprobado':
        return AppColors.red;
      case 'en_curso':
        return AppColors.blue;
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${entry.codigoCurso} · ${entry.curso}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${entry.periodo} · ${entry.creditos} créditos'
                  '${entry.intento > 1 ? ' · intento ${entry.intento}' : ''}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                entry.nota == null
                    ? entry.estadoLabel
                    : Formatters.decimal(entry.nota, digits: 2),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _color,
                ),
              ),
              Text(
                entry.estadoLabel,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
