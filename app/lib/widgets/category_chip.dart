import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Chip de categoría usado como filtro en calendario y noticias.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;

  static Color colorFor(String? categoria) {
    switch ((categoria ?? '').toLowerCase()) {
      case 'matricula':
        return AppColors.red;
      case 'examenes':
        return const Color(0xFF7C3AED);
      case 'clases':
        return AppColors.blue;
      case 'pagos':
        return AppColors.amber;
      case 'ceremonia':
        return const Color(0xFF0F766E);
      case 'beca':
        return AppColors.green;
      case 'convocatoria':
        return const Color(0xFF7C3AED);
      case 'evento':
        return AppColors.blue;
      case 'curso':
        return const Color(0xFF0F766E);
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color base = color ?? colorFor(label);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? base : Colors.white,
          border: Border.all(color: selected ? base : AppColors.border),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
