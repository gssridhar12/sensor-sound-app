import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:sensors/sensors.dart';
import 'dart:convert';

import 'sensor_data_listener.dart';

class Sound {
  final int id; // Adjust based on actual API response properties
  final String name;
  final String username;
  final List tags;

  Sound({required this.id, required this.name, required this.username, required this.tags}); // Adjust constructor accordingly

  factory Sound.fromJson(Map<String, dynamic> json) {
    return Sound(id: json['id'], name: json['name'], username: json['username'], tags: json['tags']); 
  }
}

class SensorControlUI extends StatefulWidget {
  const SensorControlUI({Key? key}) : super(key: key);

  @override
  _SensorControlUIState createState() => _SensorControlUIState();
}

class _SensorControlUIState extends State<SensorControlUI> {
  late AudioPlayer audioPlayer;
  List<Sound> sounds = [];
  double currentTempo = 1.0;
  // Flag to track if the API call has been made
  bool _isDataFetched = false;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    _fetchSoundsIfNeeded();
  }

  Future<void> _fetchSoundsIfNeeded() async {
    if (!_isDataFetched) {
      _isDataFetched = true; // Mark as fetched before making the call
      sounds = await fetchSounds();
      setState(() {}); // Update the UI with the fetched sounds
    }
  }

  Future<List<Sound>> fetchSounds() async {
    final response = await http.get(Uri.parse('https://freesound.org/apiv2/search/text/?query=beat&token=ZO8Ny9tMBLKCQw3DOAIhYD8glC9IUTkh8gnDGuQW'));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final fetchedSounds = (responseData['results'] as List).map((soundData) => Sound.fromJson(soundData)).toList();
      // setState(() {
      //   sounds = fetchedSounds;
      // });
      return fetchedSounds;
    } else {
      // Handle error appropriately
      throw Exception('Failed to fetch sounds');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sensor Sound Control'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SensorDataListener(onData: _handleSensorData),
          Expanded(
            child: FutureBuilder<List<Sound>>(
              future: fetchSounds(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final sound = snapshot.data![index];

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(audioPlayer.state == PlayerState.playing
                                  ? Icons.pause
                                  : Icons.play_arrow),
                              onPressed: () {
                                _playSound(sound); 
                              },
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Text(
                                      sound.name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    '  @${sound.username}  ',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            // Wrap(
                            //   spacing: 8.0,
                            //   children: sound.tags
                            //       .map((tag) => Chip(
                            //             label: Text(tag),
                            //             backgroundColor: Colors.blueAccent[100],
                            //           ))
                            //       .toList(),
                            // ),
                          ],
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('Error fetching sounds: ${snapshot.error}');
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
    );
  }

void _playSound(Sound sound) async {
  await audioPlayer.stop(); // Stop any currently playing sound

  try {
    // Make the API call to fetch the sound URL
    final response = await http.get(Uri.parse('https://freesound.org/apiv2/sounds/${sound.id}/?token=ZO8Ny9tMBLKCQw3DOAIhYD8glC9IUTkh8gnDGuQW')); // Assuming the sound.url is an API endpoint
    final soundUrl = jsonDecode(response.body)['previews']['preview-hq-mp3']; // Extract actual sound URL from response

    // Create a Source object from the URL
    final source = UrlSource(soundUrl);
    await audioPlayer.setSource(source);
    await audioPlayer.setPlaybackRate(currentTempo);
    await audioPlayer.play(source);
  } catch (error) {
    // Handle any errors during the API call or playback
    debugPrint('Error playing sound: $error');
    // Display an error message to the user
  }
}



  void _updateTempo(double newTempo) {
    setState(() {
      currentTempo = newTempo;
      // Adjust audio playback rate if applicable
    });
  }

  void _startListeningToSensorData(context) {
    // Implement sensor data listening logic here
  }

   void _handleSensorData(AccelerometerEvent event) {
    // Access sensor data here and use it for UI updates or sound control
    debugPrint('Accelerometer data: ${event.x}, ${event.y}, ${event.z}');
  }
}
