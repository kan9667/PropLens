//app's entry point

import 'package:flutter/material.dart';
import 'app.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async{ // async allows asynchronous operations to complete without blocking the ui thread
  WidgetsFlutterBinding.ensureInitialized(); //make sure flutter engine is fully initialized

  
  await dotenv.load(fileName: ".env");

 


  runApp( //starts rendering ui
  ChangeNotifierProvider(
    create: (_) => AppProvider(), //makes provider accessible throughout the widget tree
    //create -> factory function that creates and provides an instance of app provider to the widget tree
    child: const Ghar360App(), //root widget of the entire application
  ),
);
}