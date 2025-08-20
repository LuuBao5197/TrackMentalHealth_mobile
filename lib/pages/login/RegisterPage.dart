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
  int _secondsRemaining = 300;
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

    final uri = Uri.parse(ApiConstants.verifyOtp).replace(queryParameters: {
      'email': _emailController.text.trim(),
      'otp': _otpController.text.trim()
    });

    final response = await http.post(uri);
    setState(() => _isVerifying = false);

    if (response.statusCode == 200) {
      setState(() => _otpVerified = true);
      await _register();
      setState(() => _otpVerified = true);

      // Hiển thị thông báo thành công và chuyển về Login
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Registration Successfully!'),
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
      final request =
      http.MultipartRequest('POST', Uri.parse(ApiConstants.register));
      request.fields['fullName'] = _fullNameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['password'] = _passwordController.text;
      request.fields['confirmPassword'] = _confirmPasswordController.text;
      request.fields['roleId'] = '5';
      request.fields['isApproved'] = 'True';

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      setState(() => _isRegistering = false);

      if (response.statusCode == 200) {
        final parsed = json.decode(responseBody);
        print('Response parsed: $parsed');
        // giữ nguyên logic parse token/roleId nếu cần
      } else {
        print('Response status: ${response.statusCode}');
        print('Response body: $responseBody');
        _showDialog('Error', 'An error occurred during registration.');
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
    _secondsRemaining = 300;
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
      builder: (_) => AlertDialog(
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
      appBar: AppBar(
        title: const Text("Create Account"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // --- Title
                Text(
                  "Register",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Fill in your details to create an account",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // --- Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    if (value == null || value.isEmpty) return "Required";
                    final emailRegex =
                    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) return "Invalid format";
                    if (_emailExists) return "Email already exists";
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),

                // --- Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) =>
                  value != null && value.length < 6 ? "Min 6 chars" : null,
                ),
                const SizedBox(height: 16),

                // --- Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => value != _passwordController.text
                      ? "Passwords do not match"
                      : null,
                ),
                const SizedBox(height: 24),

                // --- Send OTP
                _isSendingOtp
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  onPressed: _sendOtp,
                  icon: const Icon(Icons.send_to_mobile),
                  label: const Text("Send OTP"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                if (_showOtpField) ...[
                  const SizedBox(height: 24),

                  // --- OTP Field
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Enter OTP",
                      prefixIcon: const Icon(Icons.password_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Verify OTP
                  _isVerifying
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                    onPressed: _verifyOtp,
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text("Verify OTP"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // --- Resend OTP
                  _canResend
                      ? TextButton.icon(
                    onPressed: _sendOtp,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Resend OTP"),
                  )
                      : Text(
                    "Resend in $_formattedTime",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // --- Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text("Login"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
