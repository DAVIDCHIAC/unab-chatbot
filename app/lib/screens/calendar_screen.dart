import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/calendar_event.dart';
import '../providers/calendar_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/ask_panel.dart';
import '../widgets/category_chip.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/section_title.dart';
import '../widgets/surface_card.dart';

/// Calendario académico: listado filtrable + asistente de fechas (WF02).
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CalendarProvider>().load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CalendarProvider provider = context.watch<CalendarProvider>();

    return RefreshIndicator(
      onRefresh: () => provider.load(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          _CalendarHeader(total: provider.events.length),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CalendarProvider.filters.map((Map<String, String?> filter) {
              final String? value = filter['value'];
              return CategoryChip(
                label: filter['label'] ?? '',
                selected: provider.categoria == value,
                color: CategoryChip.colorFor(value),
                onTap: () => provider.setCategoria(value),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: provider.search,
            onChanged: (String value) {
              if (value.isEmpty) provider.search('');
            },
            decoration: InputDecoration(
              hintText: 'Buscar evento (ej. matrícula, examen)',
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: IconButton(
                tooltip: 'Limpiar',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _search.clear();
                  provider.search('');
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (provider.loading && provider.events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (provider.error != null && provider.events.isEmpty)
            ErrorState(
              message: provider.error!,
              onRetry: () => provider.load(force: true),
            ),
          if (provider.error != null && provider.events.isNotEmpty)
            _InlineError(message: provider.error!),
          if (!provider.loading &&
              provider.error == null &&
              provider.events.isEmpty)
            EmptyState(
              icon: Icons.event_available,
              title: 'No hay eventos para este filtro',
              message: 'Prueba con otra categoría o limpia la búsqueda.',
              action: OutlinedButton.icon(
                onPressed: () {
                  _search.clear();
                  provider.setCategoria(null);
                },
                icon: const Icon(Icons.filter_alt_off, size: 18),
                label: const Text('Quitar filtros'),
              ),
            ),
          ...provider.events.map(
            (CalendarEvent event) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EventCard(event: event),
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle(
            title: 'Asistente de fechas',
            subtitle: 'Pregunta en lenguaje natural por cualquier fecha',
          ),
          AskPanel(
            title: 'UNAB Calendario',
            hint: 'Ej. ¿Cuándo son los exámenes finales?',
            icon: Icons.event_note,
            messages: provider.messages,
            sending: provider.asking,
            onSend: provider.ask,
            suggestions: const <String>[
              '¿Cuándo es la matrícula?',
              '¿Cuándo empiezan las clases?',
              '¿Cuándo son los exámenes finales?',
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Calendario académico',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  total == 1
                      ? '1 evento próximo'
                      : '$total eventos próximos',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final Color categoryColor = CategoryChip.colorFor(event.categoria);
    final int? days = event.diasFaltantes;
    final Color daysColor = days == null
        ? AppColors.muted
        : days <= 3
            ? AppColors.red
            : days <= 7
                ? AppColors.amber
                : AppColors.green;

    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  Formatters.dayNumber(event.fechaInicio),
                  style: TextStyle(
                    fontSize: 21,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    color: categoryColor,
                  ),
                ),
                Text(
                  Formatters.monthShort(event.fechaInicio).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: categoryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  event.evento,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    CategoryChip(
                      label: event.categoriaLabel,
                      color: categoryColor,
                      selected: true,
                    ),
                    if (days != null)
                      Text(
                        Formatters.relativeDays(days),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: daysColor,
                        ),
                      ),
                  ],
                ),
                if (event.hasRange) ...<Widget>[
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.date_range,
                        size: 14,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Del ${Formatters.date(event.fechaInicio)} '
                          'al ${Formatters.date(event.fechaFin)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (event.descripcion != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    event.descripcion!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.muted,
                    ),
                  ),
                ],
                if (event.periodo != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    'Periodo ${event.periodo}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline, size: 18, color: AppColors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.darkRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
