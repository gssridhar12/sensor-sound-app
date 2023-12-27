import 'package:flutter/material.dart';

import 'sensor_control_ui.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor Sound App',
      routes: {
        '/': (context) => SensorControlUI()
      },
    );
  }
}
