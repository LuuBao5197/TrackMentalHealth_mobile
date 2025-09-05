// ExerciseDetailScreen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../core/constants/api_constants.dart';
import 'CameraExercisePage.dart'; // Import trang camera

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseId;

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
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _initializeVideoPlayer(String url) async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoPlayerController!.initialize();
    setState(() {});
    _videoPlayerController!.addListener(() {
      if (_videoPlayerController!.value.hasError) {
        setState(() {
          videoError =
              _videoPlayerController!.value.errorDescription ?? 'Unknown video error';
        });
      }
    });
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
          child: SpinKitCircle(color: Colors.blue, size: 50.0),
        ),
      );
    }

    if (exercise == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exercise Detail')),
        body: const Center(
          child: Text('Failed to load exercise.', style: TextStyle(color: Colors.red)),
        ),
      );
    }

    // Nếu mediaType là camera => mở CameraExercisePage
    if (exercise!['mediaType'] == 'camera') {
      return CameraExercisePage(exerciseId: widget.exerciseId);
    }

    return Scaffold(
      appBar: AppBar(title: Text(exercise!['title'] ?? 'Exercise Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise!['title'] ?? '',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              exercise!['instruction'] ?? '',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (exercise!['mediaType'] == 'audio' && exercise!['mediaUrl'] != null)
              AudioPlayerWidget(url: exercise!['mediaUrl']),
            if (exercise!['mediaType'] == 'video' &&
                exercise!['mediaUrl'] != null &&
                _videoPlayerController != null &&
                _videoPlayerController!.value.isInitialized)
              AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController!),
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
    return Column(
      children: [
        Text('Audio URL: $url'),
        const SizedBox(height: 8),
      ],
    );
  }
}
