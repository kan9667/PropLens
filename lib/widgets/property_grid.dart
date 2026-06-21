import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'property_card.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class _GridLayout {
  final int crossAxisCount;
  final double mainAxisExtent;

  const _GridLayout({
    required this.crossAxisCount,
    required this.mainAxisExtent,
  });
}

class PropertyGrid extends StatelessWidget {
  final int? maxItems;

  const PropertyGrid({super.key, this.maxItems});

  _GridLayout _layoutForWidth(double width, double textScale) {
    final scale = textScale.clamp(1.0, 1.35);

    int crossAxisCount = 2;
    if (width > 1200) {
      crossAxisCount = 4;
    } else if (width > 800) {
      crossAxisCount = 3;
    } else if (width < 360) {
      crossAxisCount = 1;
    }

    const gridPadding = 24.0;
    const crossAxisSpacing = 10.0;
    final itemWidth =
        (width - gridPadding - crossAxisSpacing * (crossAxisCount - 1)) /
        crossAxisCount;
    final imageHeight = itemWidth / 1.5;
    final metaHeight = 96.0 * scale + (scale > 1.05 ? 12.0 : 0.0);

    return _GridLayout(
      crossAxisCount: crossAxisCount,
      mainAxisExtent: imageHeight + metaHeight + 16,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final layout = _layoutForWidth(width, textScale);

    final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: layout.crossAxisCount,
      mainAxisExtent: layout.mainAxisExtent,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
    );

    if (provider.isLoading) {
      return Shimmer.fromColors(
        baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: gridDelegate,
          itemBuilder: (context, index) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: EdgeInsets.zero,
              child: const SizedBox.expand(),
            );
          },
        ),
      );
    }

    final visibleItemCount =
        maxItems == null || provider.results.length <= maxItems!
        ? provider.results.length
        : maxItems!;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleItemCount,
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) {
        return PropertyCard(property: provider.results[index]);
      },
    );
  }
}
