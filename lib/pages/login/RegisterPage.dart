import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmentalhealth/core/constants/api_constants.dart';
import 'package:trackmentalhealth/main.dart';
import 'package:trackmentalhealth/pages/login/LoginPage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isSendingOtp = false;
  bool _showOtpField = false;
  bool _isVerifying = false;
  bool _otpVerified = false;
  bool _isRegistering = false;
  bool _canResend = false;
  Timer? _countdownTimer;
  int _secondsRemaining = 120;
  bool _emailExists = false;
  bool _checkingEmail = false;

  // ======== Check Email Exist ========
  Future<void> _checkEmailExists(String email) async {
    setState(() {
      _checkingEmail = true;
      _emailExists = false;
    });

    final uri = Uri.parse(ApiConstants.checkEmailExists)
        .replace(queryParameters: {'email': email.trim()});
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _emailExists = result['exists'] == true;
        });
      }
    } catch (_) {
      setState(() => _emailExists = false);
    } finally {
      setState(() => _checkingEmail = false);
    }
  }

  // ======== Send OTP ========
  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showDialog('Error', 'Please enter a valid email before sending OTP');
      return;
    }

    setState(() => _isSendingOtp = true);

    final uri = Uri.parse(ApiConstants.sendOtp)
        .replace(queryParameters: {'email': email});
    final response = await http.post(uri);

    setState(() => _isSendingOtp = false);

    if (response.statusCode == 200) {
      setState(() {
        _showOtpField = true;
        _otpVerified = false;
      });
      _startTimer();
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to send OTP';
      _showDialog('Error', error);
    }
  }

  // ======== Verify OTP ========
  Future<void> _verifyOtp() async {
    setState(() => _isVerifying = true);

    final uri = Uri.parse(ApiConstants.verifyOtp)
        .replace(queryParameters: {
      'email': _emailController.text.trim(),
      'otp': _otpController.text.trim()
    });

    final response = await http.post(uri);
    setState(() => _isVerifying = false);

    if (response.statusCode == 200) {
      setState(() => _otpVerified = true);
      _showDialog('Success', 'OTP verified. You can now complete registration.');
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Invalid OTP';
      _showDialog('Error', error);
    }
  }

  // ======== Register After OTP ========
  Future<void> _register() async {
    if (!_otpVerified) {
      _showDialog('Error', 'Please verify OTP first.');
      return;
    }

    setState(() => _isRegistering = true);

    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.register));
      request.fields['fullName'] = _fullNameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['password'] = _passwordController.text;
      request.fields['confirmPassword'] = _confirmPasswordController.text;
      request.fields['roleId'] = '5';

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      setState(() => _isRegistering = false);

      if (response.statusCode == 200) {
        final parsed = json.decode(responseBody);
        print('Response parsed: $parsed');

        final token = parsed['token'];
        final roleId = parsed['roleId'];
        final fullName = parsed['fullName']; // hoặc 'fullname' tùy backend

        setState(() {
          _isRegistering = false;
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Registration successful!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        print('Response status: ${response.statusCode}');
        print('Response body: $responseBody');
        setState(() {
          _isRegistering = false;
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('An error occurred during registration.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isRegistering = false);
      _showDialog('Error', 'An error occurred: $e');
    }
  }


  // ======== Helpers ========
  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startTimer() {
    _secondsRemaining = 120;
    _canResend = false;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() => _canResend = true);
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'))
            ],
          ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ======== UI ========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                  ),
                  onChanged: (value) {
                    if (value.contains('@')) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (value == _emailController.text) {
                          _checkEmailExists(value);
                        }
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) return 'Invalid format';
                    if (_emailExists) return 'Email already exists';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) =>
                  value != null && value.length < 6 ? 'Min 6 chars' : null,
                ),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  validator: (value) =>
                  value != _passwordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: 20),
                _isSendingOtp
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _sendOtp,
                  child: const Text('Send OTP'),
                ),
                if (_showOtpField) ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _otpController,
                    decoration: const InputDecoration(labelText: 'Enter OTP'),
                  ),
                  const SizedBox(height: 10),
                  _isVerifying
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: _verifyOtp,
                    child: const Text('Verify OTP'),
                  ),
                  const SizedBox(height: 10),
                  _canResend
                      ? ElevatedButton(
                    onPressed: _sendOtp,
                    child: const Text('Resend OTP'),
                  )
                      : Text('Resend in $_formattedTime'),
                ],
                const SizedBox(height: 20),
                _isRegistering
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: () async {
                    await _register(); // gọi đăng ký và tự xử lý chuyển trang bên trong
                  },
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
