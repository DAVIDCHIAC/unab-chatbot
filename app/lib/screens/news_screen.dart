import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/news_item.dart';
import '../providers/news_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/category_chip.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/surface_card.dart';

/// Noticias, becas y convocatorias (WF04).
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NewsProvider>().load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(NewsItem item) async {
    final String? url = item.url;
    if (url == null || url.isEmpty) return;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return;
    final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final NewsProvider provider = context.watch<NewsProvider>();

    return RefreshIndicator(
      onRefresh: () => provider.load(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          _NewsHeader(total: provider.items.length),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NewsProvider.filters.map((Map<String, String?> filter) {
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
              hintText: 'Buscar beca, convocatoria o evento',
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
          if (provider.loading && provider.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (provider.error != null && provider.items.isEmpty)
            ErrorState(
              message: provider.error!,
              onRetry: () => provider.load(force: true),
            ),
          if (provider.error != null && provider.items.isNotEmpty)
            _InlineError(message: provider.error!),
          if (!provider.loading &&
              provider.error == null &&
              provider.items.isEmpty)
            EmptyState(
              icon: Icons.campaign_outlined,
              title: 'No hay publicaciones para este filtro',
              message:
                  'El workflow WF04 carga noticias cada 6 horas. También puedes '
                  'ejecutarlo manualmente desde n8n.',
              action: OutlinedButton.icon(
                onPressed: () {
                  _search.clear();
                  provider.setCategoria(null);
                },
                icon: const Icon(Icons.filter_alt_off, size: 18),
                label: const Text('Quitar filtros'),
              ),
            ),
          ...provider.items.map(
            (NewsItem item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NewsCard(item: item, onOpen: () => _open(item)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsHeader extends StatelessWidget {
  const _NewsHeader({required this.total});

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
              Icons.campaign,
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
                  'Noticias y convocatorias',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  total == 1 ? '1 publicación activa' : '$total publicaciones activas',
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

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item, required this.onOpen});

  final NewsItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final Color color = CategoryChip.colorFor(item.categoria);
    final String date = Formatters.date(item.fechaPublicacion);
    final String ago = Formatters.publishedAgo(item.diasPublicada);

    return SurfaceCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CategoryChip(
                label: item.categoriaLabel,
                color: color,
                selected: true,
              ),
              const Spacer(),
              if (ago.isNotEmpty)
                Text(
                  ago,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.titulo,
            style: const TextStyle(
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          if (item.resumen != null) ...<Widget>[
            const SizedBox(height: 7),
            Text(
              item.resumen!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.muted,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppColors.muted,
              ),
              const SizedBox(width: 4),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.muted,
                ),
              ),
              if (item.fuente != null) ...<Widget>[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    item.fuente!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (item.url != null && item.url!.isNotEmpty)
                TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Abrir'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 34),
                  ),
                ),
            ],
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
