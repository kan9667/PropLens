//defines theme, route, navigation, global app setting


import 'package:flutter/material.dart';
import 'data/properties.dart';
import 'widgets/property_card.dart';
import 'widgets/property_grid.dart';
import 'widgets/search_bar.dart';

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
  body: Column(
  children: [
    const SearchBarWidget(),

    Expanded( //allows child widget to occupy the remaining available space inside a flex widget such as row or column
      child: PropertyGrid(),
    ),
  ],
),
),
    );
  }
}