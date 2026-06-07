//cards

import 'package:flutter/material.dart';
import '../data/types.dart';

class PropertyCard extends StatelessWidget {
  final Property property; //dependency injection- parents provide data instead of card fetching data itself

  const PropertyCard({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    return Card(         // material widget used to group related info inside a visually distinct container
      elevation: 3,
      margin: const EdgeInsets.all(8),
      child: Padding(     // adds spacing inside widgets
        padding: const EdgeInsets.all(12),
        child: Column(    //places children vertically
          crossAxisAlignment: CrossAxisAlignment.start, //aligns content to left
          children: [
            Container( //general purpose box widget 
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.home,
                size: 50,
              ),
            ),

            const SizedBox(height: 12), //creates spacing

            Text(
              '${property.bhk} BHK • ${property.area} sq ft',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 6),

            Text(property.location),

            const SizedBox(height: 6),

            Text(
              '₹${property.price}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}