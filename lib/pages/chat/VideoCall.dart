// lib/pages/chat/VideoCall.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class VideoCall extends StatefulWidget {
  final String sessionId;
  final String currentUserId;
  final String receiverId;
  final String receiverName;

  const VideoCall({
    super.key,
    required this.sessionId,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<VideoCall> createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  StompClient? _stompClient;
  bool _micEnabled = true;
  bool _cameraFront = true;

  // TODO: đổi IP/port nếu cần (phù hợp backend của bạn)
  static const String wsUrl = 'ws://192.168.1.5:9999/ws';

  @override
  void initState() {
    super.initState();
    _initEverything();
  }

  Future<void> _initEverything() async {
    await _requestPermissions();
    await _initRenderers();
    _connectSignaling();
  }

  Future<void> _requestPermissions() async {
    // xin quyền runtime
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera] != PermissionStatus.granted ||
        statuses[Permission.microphone] != PermissionStatus.granted) {
      // nếu không cho phép, thoát về trước
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera hoặc Microphone permission required')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _connectSignaling() {
    _stompClient = StompClient(
      config: StompConfig(
        // Nếu server dùng SockJS endpoint, dùng sockJS factory. Thường ws://... là ok.
        url: wsUrl,
        onConnect: (frame) {
          print('✅ STOMP connected');
          // subscribe topic for this session
          _stompClient?.subscribe(
            destination: '/topic/call/${widget.sessionId}',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                final data = jsonDecode(frame.body!);
                print('📩 Signaling message: $data');
                _onSignalReceived(data);
              }
            },
          );

          // khởi tạo PeerConnection + local stream sau khi STOMP connect xong
          _createPeerConnectionAndLocalStream();
        },
        beforeConnect: () async {
          print('🔄 STOMP connecting...');
          await Future.delayed(const Duration(milliseconds: 200));
        },
        onStompError: (frame) => print('STOMP error: ${frame.body}'),
        onWebSocketError: (dynamic error) => print('WebSocket error: $error'),
        onDisconnect: (frame) => print('🔌 STOMP disconnected'),
      ),
    );

    _stompClient?.activate();
  }

  Future<void> _createPeerConnectionAndLocalStream() async {
    // config ICE servers
    final Map<String, dynamic> config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(config);

    // nhận track remote
    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
        });
      }
    };

    // ICE candidate -> gửi qua signaling
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        _sendSignal({
          'type': 'candidate',
          'callerId': int.parse(widget.currentUserId),
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    // Lấy local stream (camera + mic)
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': _cameraFront ? 'user' : 'environment',
      }
    });

    // gán vào local renderer
    _localRenderer.srcObject = _localStream;

    // add local tracks to peerConnection
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    // Tự động tạo offer nếu bạn là caller (điều kiện: currentUserId != receiverId)
    // Điều này là 1 heuristic: bạn có thể bổ sung logic "bấm nút gọi" thay vì auto
    if (widget.currentUserId != widget.receiverId) {
      // tạo offer
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      _sendSignal({
        'type': 'offer',
        'callerId': int.parse(widget.currentUserId),
        'sdp': offer.sdp,
        'sdpType': offer.type,
      });
      print('📤 Sent offer');
    } else {
      // nếu là receiver (hiếm khi bằng nhau) thì chờ offer đến
      print('⏳ Waiting for offer (receiver)');
    }
  }

  void _onSignalReceived(Map<String, dynamic> data) async {
    try {
      final String type = data['type']?.toString() ?? '';
      final int? callerId = data['callerId'] is int ? data['callerId'] : (data['callerId'] != null ? int.tryParse(data['callerId'].toString()) : null);

      // optional: ignore messages sent by myself
      if (callerId != null && callerId.toString() == widget.currentUserId) {
        // ignore own signals (broadcast back)
        return;
      }

      if (type == 'offer') {
        final String? sdp = data['sdp'];
        if (sdp != null) {
          await _peerConnection?.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
          final answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);

          _sendSignal({
            'type': 'answer',
            'callerId': int.parse(widget.currentUserId),
            'sdp': answer.sdp,
            'sdpType': answer.type,
          });
          print('📤 Sent answer');
        }
      } else if (type == 'answer') {
        final String? sdp = data['sdp'];
        if (sdp != null) {
          await _peerConnection?.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
          print('✅ Remote answer set');
        }
      } else if (type == 'candidate') {
        final String? cand = data['candidate'];
        final String? sdpMid = data['sdpMid'];
        final dynamic sdpMLineIndex = data['sdpMLineIndex'];
        if (cand != null) {
          final candidate = RTCIceCandidate(cand, sdpMid, sdpMLineIndex is int ? sdpMLineIndex : int.tryParse(sdpMLineIndex.toString()));
          await _peerConnection?.addCandidate(candidate);
          print('✅ Candidate added');
        }
      } else {
        print('⚠️ Unknown signal type: $type');
      }
    } catch (e, st) {
      print('❌ Error handling signal: $e\n$st');
    }
  }

  void _sendSignal(Map<String, dynamic> payload) {
    if (_stompClient == null) {
      print('⚠️ STOMP not initialized yet');
      return;
    }
    final body = jsonEncode(payload);
    _stompClient?.send(destination: '/app/call/${widget.sessionId}', body: body);
    print('📤 Sent signal: $body');
  }

  Future<void> _switchCamera() async {
    final videoTrack = _localStream?.getVideoTracks().isNotEmpty == true ? _localStream!.getVideoTracks().first : null;
    if (videoTrack != null) {
      try {
        await Helper.switchCamera(videoTrack);
        setState(() {
          _cameraFront = !_cameraFront;
        });
      } catch (e) {
        print('Switch camera error: $e');
      }
    }
  }

  void _toggleMic() {
    final audioTracks = _localStream?.getAudioTracks() ?? [];
    if (audioTracks.isNotEmpty) {
      final enabled = !_micEnabled;
      for (var t in audioTracks) {
        t.enabled = enabled;
      }
      setState(() => _micEnabled = enabled);
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _localStream?.dispose();
    _peerConnection?.close();
    _stompClient?.deactivate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localView = RTCVideoView(_localRenderer, mirror: true);
    final remoteView = RTCVideoView(_remoteRenderer);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Video Call'),
        backgroundColor: Colors.teal,

      ),
      body: Stack(
        children: [
          Positioned.fill(child: remoteView),
          Positioned(
            right: 16,
            bottom: 100,
            width: 140,
            height: 200,
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.black87),
              child: ClipRRect(borderRadius: BorderRadius.circular(8), child: localView),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              FloatingActionButton(
                heroTag: 'mic',
                onPressed: _toggleMic,
                child: Icon(_micEnabled ? Icons.mic : Icons.mic_off),
              ),
              FloatingActionButton(
                heroTag: 'end',
                backgroundColor: Colors.red,
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(Icons.call_end),
              ),
              FloatingActionButton(
                heroTag: 'cam',
                onPressed: _switchCamera,
                child: const Icon(Icons.switch_camera),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
