//app's entry point

import 'package:flutter/material.dart';
import 'app.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/comparison_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // async allows asynchronous operations to complete without blocking the ui thread
  WidgetsFlutterBinding.ensureInitialized(); //make sure flutter engine is fully initialized

  await dotenv.load(fileName: ".env");

  runApp(
    //starts rendering ui
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => ComparisonProvider()),
      ],
      child: const Ghar360App(), //root widget of the entire application
    ),
  );
}
