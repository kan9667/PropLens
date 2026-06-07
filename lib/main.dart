//app's entry point

import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); //make sure flutter engine is fully initialized

  runApp( //starts rendering ui
    const Ghar360App(), //root widget of the entire application
  );
}