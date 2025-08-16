import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class CameraExercisePage extends StatefulWidget {
final String exerciseId;
const CameraExercisePage({super.key, required this.exerciseId});

@override
State<CameraExercisePage> createState() => _CameraExercisePageState();
}

class _CameraExercisePageState extends State<CameraExercisePage> {
CameraController? _controller;
Future<void>? _initCameraFuture;

List<dynamic> _conditions = [];
int _currentStepIndex = 0;
bool _exerciseDone = false;
int _countdown = 0;
Map<String, dynamic>? _condition;

Timer? _timer;
DateTime? _actionStartTime;
bool _actionDetected = false; // Đây bạn sẽ xử lý logic detect action

@override
void initState() {
super.initState();
_initCamera();
_fetchConditions();
}

// INIT CAMERA
Future<void> _initCamera() async {
final status = await Permission.camera.status;
if (!status.isGranted) {
final result = await Permission.camera.request();
if (!result.isGranted) {
debugPrint("Camera permission denied");
return;
}
}

try {
final cameras = await availableCameras();
if (cameras.isEmpty) {
debugPrint("No cameras found");
return;
}

final frontCam = cameras.firstWhere(
(cam) => cam.lensDirection == CameraLensDirection.front,
orElse: () => cameras.first,
);

_controller = CameraController(
frontCam,
ResolutionPreset.medium,
enableAudio: false,
);

_initCameraFuture = _controller!.initialize();
setState(() {});
} catch (e) {
debugPrint("Failed to initialize camera: $e");
}
}

// FETCH EXERCISE CONDITIONS
Future<void> _fetchConditions() async {
try {
final res = await http.get(
Uri.parse("http://10.0.2.2:9999/api/exercises/${widget.exerciseId}/conditions"),
);
if (res.statusCode == 200) {
final data = jsonDecode(res.body);
if (data != null && data.isNotEmpty) {
setState(() {
_conditions = data;
_condition = {
"id": data[0]["id"],
"actionType": data[0]["type"],
"description": data[0]["description"],
"durationSeconds": int.tryParse(data[0]["duration"].toString()) ?? 3,
};
_countdown = _condition!["durationSeconds"];
});
_startTimer();
}
}
} catch (e) {
debugPrint("Failed to load conditions: $e");
}
}

// TIMER LOGIC
void _startTimer() {
_timer = Timer.periodic(const Duration(seconds: 1), (timer) {
if (_exerciseDone || _condition == null) return;

if (_actionDetected) {
if (_actionStartTime == null) {
_actionStartTime = DateTime.now();
_countdown = _condition!["durationSeconds"];
} else {
final elapsed = DateTime.now().difference(_actionStartTime!).inSeconds;
final timeLeft = (_condition!["durationSeconds"] - elapsed).clamp(0, _condition!["durationSeconds"]);
setState(() => _countdown = timeLeft);

if (elapsed >= _condition!["durationSeconds"]) {
if (_currentStepIndex < _conditions.length - 1) {
final nextIndex = _currentStepIndex + 1;
final next = _conditions[nextIndex];
setState(() {
_currentStepIndex = nextIndex;
_condition = {
"id": next["id"],
"actionType": next["type"],
"description": next["description"],
"durationSeconds": int.tryParse(next["duration"].toString()) ?? 3,
};
_countdown = _condition!["durationSeconds"];
});
_actionStartTime = null;
_actionDetected = false;
} else {
setState(() => _exerciseDone = true);
_showSuccessDialog();
}
}
}
} else {
_actionStartTime = null;
setState(() {
_countdown = _condition!["durationSeconds"];
});
}
});
}

// SUCCESS DIALOG
void _showSuccessDialog() {
showDialog(
context: context,
builder: (_) => AlertDialog(
title: const Text("Great job!"),
content: const Text("You finished the whole exercise!"),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text("OK"),
),
],
),
);
}

@override
void dispose() {
_timer?.cancel();
_controller?.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
if (_controller == null || _initCameraFuture == null) {
return const Scaffold(
body: Center(child: CircularProgressIndicator()),
);
}

if (_condition == null) {
return const Scaffold(
body: Center(child: Text("Loading exercise...")),
);
}

return Scaffold(
appBar: AppBar(title: const Text("Camera Exercise")),
body: Column(
children: [
Padding(
padding: const EdgeInsets.all(8.0),
child: Text(
"Step ${_currentStepIndex + 1} / ${_conditions.length}: ${_condition!["description"]} "
"(${_condition!["durationSeconds"]} seconds)",
style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
),
Expanded(
child: Stack(
children: [
FutureBuilder(
future: _initCameraFuture,
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.done) {
return CameraPreview(_controller!);
} else {
return const Center(child: CircularProgressIndicator());
}
},
),
Positioned(
top: 10,
left: 10,
child: Container(
padding: const EdgeInsets.all(8),
color: Colors.black54,
child: Text(
!_exerciseDone ? "⏳ $_countdown s" : "✔ Done!",
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: !_exerciseDone ? Colors.yellow : Colors.green,
),
),
),
),
],
),
),
],
),
);
}
}
