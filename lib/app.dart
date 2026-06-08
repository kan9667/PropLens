import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/property_details_screen.dart';
import 'data/types.dart';

class Ghar360App extends StatelessWidget {
  const Ghar360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '360 Ghar', //app name
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomeScreen(),
      routes: {
        '/property': (context) {
          final property = ModalRoute.of(context)!.settings.arguments as PropertyModel;
          return PropertyDetailsScreen(property: property);
        },
      },
    );
  }
}