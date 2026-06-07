//shows search results

import 'package:flutter/material.dart';
import '../data/properties.dart';
import 'property_card.dart';

class PropertyGrid extends StatelessWidget {
  const PropertyGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder( //creates item only when needed - lazy loading
      padding: const EdgeInsets.all(12),

      itemCount: mockProperties.length, 

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount( //controls layout
        crossAxisCount: 2,
        childAspectRatio: 0.75, //controls card space
        crossAxisSpacing: 10, //horizontal spacing
        mainAxisSpacing: 10, //vertical spacing
      ),

      itemBuilder: (context, index) { 
        return PropertyCard(
          property: mockProperties[index],
        );
      },
    );
  }
}