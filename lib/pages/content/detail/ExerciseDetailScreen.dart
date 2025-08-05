import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../core/constants/api_constants.dart';
// Đảm bảo đường dẫn đúng

class ExerciseDetailScreen extends StatefulWidget {
  final int exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  Map<String, dynamic>? exercise;
  bool isLoading = true;
  VideoPlayerController? _videoPlayerController;
  String? userId;
  String? videoError;

  @override
  void initState() {
    super.initState();
    _fetchExercise();
    _decodeToken();
  }

  Future<void> _decodeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isNotEmpty) {
        final decoded = JwtDecoder.decode(token);
        setState(() {
          userId = decoded['userId']?.toString();
        });
      } else {
        print('❌ Token not found');
      }
    } catch (e) {
      print('❌ Token decoding error: $e');
    }
  }

  Future<void> _fetchExercise() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.getExercises}${widget.exerciseId}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          exercise = data;
          isLoading = false;
        });
        if (data['mediaType'] == 'video' &&
            data['mediaUrl'] != null &&
            data['mediaUrl'].isNotEmpty) {
          await _initializeVideoPlayer(data['mediaUrl']);
        }
      } else {
        print('❌ Failed to load exercise: ${response.statusCode} - ${response.body}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ API error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _initializeVideoPlayer(String url) async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoPlayerController!.initialize();
      setState(() {});
      _videoPlayerController!.addListener(() {
        if (_videoPlayerController!.value.hasError) {
          setState(() {
            videoError = _videoPlayerController!.value.errorDescription ??
                'Unknown video error';
          });
        }
      });
    } catch (e, stackTrace) {
      print('❌ Video init error: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        videoError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exercise Detail')),
        body: const Center(
          child: SpinKitCircle(
            color: Colors.blue,
            size: 50.0,
          ),
        ),
      );
    }

    if (exercise == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exercise Detail')),
        body: const Center(
          child: Text(
            'Failed to load exercise.',
            style: TextStyle(fontSize: 24, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise!['title'] ?? 'Exercise Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.headphones, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Exercise Introduction',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              exercise!['title'] ?? '',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '📋 ${exercise!['instruction'] ?? ''}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontFamily: 'Georgia',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '🎧 Exercise Content',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            if (exercise!['mediaType'] == 'audio' &&
                exercise!['mediaUrl'] != null)
              Column(
                children: [
                  AudioPlayerWidget(url: exercise!['mediaUrl']),
                  const SizedBox(height: 12),
                ],
              ),
            if (exercise!['mediaType'] == 'video' &&
                exercise!['mediaUrl'] != null)
              Column(
                children: [
                  if (_videoPlayerController != null &&
                      _videoPlayerController!.value.isInitialized)
                    AspectRatio(
                      aspectRatio: _videoPlayerController!.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          VideoPlayer(_videoPlayerController!),
                          VideoProgressIndicator(_videoPlayerController!,
                              allowScrubbing: true),
                          Positioned(
                            bottom: 10,
                            child: FloatingActionButton(
                              onPressed: () {
                                setState(() {
                                  _videoPlayerController!.value.isPlaying
                                      ? _videoPlayerController!.pause()
                                      : _videoPlayerController!.play();
                                });
                              },
                              child: Icon(
                                _videoPlayerController!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      videoError ??
                          'Video failed to load. Check your internet or contact support.',
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            if (exercise!['estimatedDuration'] != null)
              Text(
                '⏱️ Estimated time: ${exercise!['estimatedDuration']} seconds',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

class AudioPlayerWidget extends StatelessWidget {
  final String url;

  const AudioPlayerWidget({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            'Audio URL: $url',
            style: const TextStyle(fontSize: 16, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          const Text(
            'Note: Use packages like `just_audio` for real audio playback.',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }
}
