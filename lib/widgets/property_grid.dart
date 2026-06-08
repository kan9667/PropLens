//shows search results

import 'package:flutter/material.dart';
import 'property_card.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class PropertyGrid extends StatelessWidget {
  const PropertyGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>(); //listen for changes
    return GridView.builder( //creates item only when needed - lazy loading
      padding: const EdgeInsets.all(12),

      itemCount: provider.results.length, 

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount( //controls layout
        crossAxisCount: 2,
        childAspectRatio: 0.75, //controls card space
        crossAxisSpacing: 10, //horizontal spacing
        mainAxisSpacing: 10, //vertical spacing
      ),

      itemBuilder: (context, index) { 
        return PropertyCard(
          property: provider.results[index],
        );
      },
    );
  }
}