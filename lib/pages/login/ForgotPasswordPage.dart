import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trackmentalhealth/core/constants/api_constants.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  int _step = 1;
  String? _message;
  String? _error;
  bool _showPassword = false;
  int _countdown = 300;
  Timer? _timer;

  void _startCountdown() {
    _countdown = 300;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = "Please enter your email.");
      return;
    }
    try {
      final res = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/users/forgot-password"),
        body: {"email": email},
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          _step = 2;
          _message = data['message'];
          _error = null;
        });
        _startCountdown();
      } else {
        setState(() => _error = data['error'] ?? "Failed to send OTP.");
      }
    } catch (e) {
      setState(() => _error = "Network error: $e");
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => _error = "Please enter OTP code.");
      return;
    }
    try {
      final res = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/users/verify-otp"),
        body: {"email": _emailController.text.trim(), "otp": otp},
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          _step = 3;
          _message = data['message'];
          _error = null;
        });
      } else {
        setState(() => _error = data['error'] ?? "OTP verification failed.");
      }
    } catch (e) {
      setState(() => _error = "Network error: $e");
    }
  }

  Future<void> _resetPassword() async {
    final newPass = _newPasswordController.text.trim();
    if (newPass.length < 6) {
      setState(() => _error = "Password must be at least 6 characters.");
      return;
    }
    try {
      final res = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/users/reset-password"),
        body: {"email": _emailController.text.trim(), "newPassword": newPass},
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          _message = "Password reset successfully!";
          _error = null;
          _step = 4;
        });
      } else {
        setState(() => _error = data['error'] ?? "Reset password failed.");
      }
    } catch (e) {
      setState(() => _error = "Network error: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure && !_showPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: obscure
            ? IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: onToggle,
        )
            : null,
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Forgot Password",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Enter your email to receive an OTP code.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _emailController,
              label: "Email",
              icon: Icons.email,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendOtp,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Send OTP"),
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Verify OTP",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Enter the OTP sent to your email."),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _otpController,
              label: "OTP Code",
              icon: Icons.lock,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                "Time remaining: ${(_countdown ~/ 60).toString().padLeft(2, '0')}:${(_countdown % 60).toString().padLeft(2, '0')}",
                style: TextStyle(
                  color: _countdown <= 0 ? Colors.red : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _countdown > 0 ? _verifyOtp : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Verify OTP"),
            ),
          ],
        );

      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Reset Password",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Enter your new password."),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _newPasswordController,
              label: "New Password",
              icon: Icons.lock,
              obscure: true,
              onToggle: () {
                setState(() => _showPassword = !_showPassword);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPassword,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Reset Password"),
            ),
          ],
        );

      case 4:
        return Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              "Password Reset Successful!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("You can now login with your new password."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Back to Login"),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_message != null)
                    Text(_message!,
                        style: const TextStyle(color: Colors.green)),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  _buildStepContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
