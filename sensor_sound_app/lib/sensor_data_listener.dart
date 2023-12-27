import 'package:flutter/material.dart';
import 'package:sensors/sensors.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

import 'dart:async';
import 'dart:convert';

class SensorDataListener extends StatefulWidget {
  final Function(AccelerometerEvent) onData;

  const SensorDataListener({Key? key, required this.onData}) : super(key: key);

  @override
  _SensorDataListenerState createState() => _SensorDataListenerState();
}

class _SensorDataListenerState extends State<SensorDataListener> {
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  double x = 0.0, y = 0.0, z = 0.0; // Store sensor values for display

  @override
  void initState() {
    super.initState();
    _accelerometerSubscription = accelerometerEvents.listen(_handleSensorData);
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    super.dispose();
  }

  void _handleSensorData(AccelerometerEvent event) {
    widget.onData(event); // Pass data to parent widget
    setState(() {
      x = event.x;
      y = event.y;
      z = event.z;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Accelerometer Data:'),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('X: ${x.toStringAsFixed(2)}'),
              Text('Y: ${y.toStringAsFixed(2)}'),
              Text('Z: ${z.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }
}
