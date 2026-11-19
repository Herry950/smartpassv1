import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class ModuleTileData {
  const ModuleTileData({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Grille responsive de tuiles de modules :
/// 4 colonnes (< 480 px), 6 colonnes (480–900 px), 8 colonnes (> 900 px,
/// largeur limitée à 1100 px).
class ModuleTileGrid extends StatelessWidget {
  const ModuleTileGrid({super.key, required this.tiles});

  final List<ModuleTileData> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width < 480
            ? 4
            : width <= 900
                ? 6
                : 8;

        final grid = GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tiles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) => ModuleTile(data: tiles[index]),
        );

        if (width > 900) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: grid,
            ),
          );
        }

        return grid;
      },
    );
  }
}

class ModuleTile extends StatelessWidget {
  const ModuleTile({super.key, required this.data});

  final ModuleTileData data;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: data.onTap,
      child: LayoutBuilder(
        builder: (context, cell) {
          // Réserve la place du label (2 lignes) pour éviter
          // tout débordement, quelle que soit la largeur d'écran.
          const labelSpace = 8.0 + 34.0;
          final side = cell.maxHeight.isFinite
              ? (cell.maxHeight - labelSpace).clamp(24.0, cell.maxWidth)
              : cell.maxWidth;

          return _buildContent(isDark, side);
        },
      ),
    );
  }

  Widget _buildContent(bool isDark, double side) {
    return Column(
        children: [
          SizedBox(
            width: side,
            height: side,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, box) {
                  final diameter = box.maxWidth * 0.55;

                  return Center(
                    child: Container(
                      width: diameter,
                      height: diameter,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white10
                            : AppColors.brandNavy.withValues(alpha: .08),
                      ),
                      child: Icon(
                        data.icon,
                        size: diameter * 0.5,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : AppColors.brandNavy,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
    );
  }
}
