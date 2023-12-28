import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:sensors/sensors.dart';

import 'dart:convert';

import 'package:sensor_sound_app/sensor_data_listener.dart';
import 'package:sensor_sound_app/models/sound.dart';

class SensorControlUI extends StatefulWidget {
  const SensorControlUI({Key? key}) : super(key: key);

  @override
  _SensorControlUIState createState() => _SensorControlUIState();
}

class _SensorControlUIState extends State<SensorControlUI>
    with SingleTickerProviderStateMixin {
  late AudioPlayer audioPlayer;
  List<Sound> sounds = [];
  late final AnimationController _tempoController;
  double _currentTempo = 1.0; // Initial tempo
  // Flag to track if the API call has been made
  bool _isDataFetched = false;
  Map<int, bool> isSettings = {};
  int currentIndex = -1;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    _fetchSoundsIfNeeded();
    _tempoController = AnimationController(
      vsync: this,
      duration:
          Duration(milliseconds: 200), // Adjust transition duration as needed
    );
    _tempoController.addListener(() {
      audioPlayer.setPlaybackRate(_tempoController.value);
    });

    audioPlayer.onPlayerStateChanged.listen((state) {
      if (state.name == 'completed') {
        // Music is done! Handle it here.
        _onMusicDone();
        if (currentIndex > -1) {
          setState(() {
            isSettings[currentIndex] =
                isSettings.update(currentIndex, (value) => !value);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _tempoController.dispose();
    super.dispose();
  }

  Future<void> _fetchSoundsIfNeeded() async {
    if (!_isDataFetched) {
      _isDataFetched = true; // Mark as fetched before making the call
      sounds = await fetchSounds();
    }
  }

  Future<List<Sound>> fetchSounds() async {
    final response = await http.get(Uri.parse(
        'https://freesound.org/apiv2/search/text/?query=beat&token=ZO8Ny9tMBLKCQw3DOAIhYD8glC9IUTkh8gnDGuQW'));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final fetchedSounds = (responseData['results'] as List)
          .map((soundData) => Sound.fromJson(soundData))
          .toList();
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
          SensorDataListener(onData: _updateTempoFromSensor),
          Expanded(
            child: FutureBuilder<List<Sound>>(
              future: fetchSounds(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      isSettings.putIfAbsent(index, () => false);
                      final sound = snapshot.data![index];

                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 1.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                  audioPlayer.state == PlayerState.playing &&
                                          isSettings[index]!
                                      ? Icons.pause
                                      : Icons.play_arrow),
                              onPressed: () {
                                _playSound(sound, index);
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
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    '  @${sound.username}  ',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
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

  void _playSound(Sound sound, int index) async {
    // Make the API call to fetch the sound URL
    final response = await http.get(Uri.parse(
        'https://freesound.org/apiv2/sounds/${sound.id}/?token=ZO8Ny9tMBLKCQw3DOAIhYD8glC9IUTkh8gnDGuQW')); // Assuming the sound.url is an API endpoint
    final soundUrl = jsonDecode(response.body)['previews']
        ['preview-hq-mp3']; // Extract actual sound URL from response

    // Create a Source object from the URL
    final source = UrlSource(soundUrl);
    await audioPlayer.setSource(source);
    await audioPlayer.setPlaybackRate(_currentTempo);
    try {
      if (audioPlayer.state == PlayerState.playing) {
        audioPlayer.pause();
      } else if (audioPlayer.state == PlayerState.paused) {
        audioPlayer.resume();
      } else {
        await audioPlayer.stop(); // Stop any currently playing sound
        await audioPlayer.play(source);
      }

      setState(() {
        isSettings[index] = isSettings.update(index, (value) => !value);
        currentIndex = index;
      });
    } catch (error) {
      // Handle any errors during the API call or playback
      debugPrint('Error playing sound: $error');
      // Display an error message to the user
    }
  }

  void _updateTempoFromSensor(AccelerometerEvent event) {
    final combinedSensorValue =
        (event.x + event.y + event.z) / 3; // Simple averaging
    final newTempo = _mapSensorValueToTempo(combinedSensorValue);
    _tempoController.animateTo(newTempo);
  }

  double _mapSensorValueToTempo(double sensorValue) {
    // Clamp sensor value to -1 to 1 range
    sensorValue = sensorValue.clamp(-1.0, 1.0);

    // Apply a linear mapping for unbiased tempo response
    final adjustedSensorValue = (sensorValue + 1) / 2; // Shift to 0 to 1 range
    const tempoRange = 7.75; // 8.0 - 0.25
    return 0.25 + tempoRange * adjustedSensorValue;
  }

  void _onMusicDone() {
    _tempoController.stop();
    _tempoController.value = 1.0;

    // Show a "Music Finished" message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Music Finished!")),
    );
  }
}
