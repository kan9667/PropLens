//defines theme, route, navigation, global app setting


import 'package:flutter/material.dart';
import 'data/properties.dart';
import 'widgets/property_card.dart';

class Ghar360App extends StatelessWidget {
  const Ghar360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '360 Ghar', //app name
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: Scaffold(
  appBar: AppBar(
    title: const Text('360 Ghar'),
  ),
  body: Center(
    child: PropertyCard(
      property: mockProperties.first,
    ),
  ),
),
    );
  }
}