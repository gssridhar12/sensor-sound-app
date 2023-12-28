import 'package:flutter/material.dart';
import 'package:sensor_sound_app/sensor_control_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor Sound App',
      home: const SensorControlUI(),
    );
  }
}
