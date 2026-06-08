import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

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
    );
  }
}