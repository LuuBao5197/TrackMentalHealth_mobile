import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmentalhealth/core/constants/api_constants.dart';
import 'package:trackmentalhealth/main.dart';
import 'package:trackmentalhealth/models/User.dart' as model;
import 'package:trackmentalhealth/pages/login/RegisterPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        scopes: ['email', 'profile'],
      ).signIn();

      if (googleUser == null) {
        // Người dùng hủy đăng nhập
        setState(() {
          _isLoading = false;
          _error = "Bạn đã hủy đăng nhập.";
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fullname', user.displayName ?? '');
        await prefs.setString('email', user.email ?? '');
        await prefs.setString('token', await user.getIdToken() ?? '');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        setState(() {
          _error = "Không lấy được thông tin người dùng.";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Đăng nhập Google thất bại: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void parseToken(String token) {
    // Giải mã token
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

    int userId = decodedToken['userId'];
    String email = decodedToken['sub'];
    String role = decodedToken['role'];

    print('User ID: $userId');
    print('Email: $email');
    print('Role: $role');
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = "Vui lòng nhập đầy đủ thông tin.");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      print('Login API raw response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;

        // ✅ Giải mã token
        final decodedToken = JwtDecoder.decode(token);
        final userId = decodedToken['userId'];
        final emailFromToken = decodedToken['sub'];
        final role = decodedToken['role'];

        print('Decoded userId: $userId');
        print('Decoded email: $emailFromToken');
        print('Decoded role: $role');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setInt('id', userId);
        await prefs.setString('email', emailFromToken);

        // ✅ Gọi API lấy fullname từ userId
        final profileResponse = await http.get(
          Uri.parse(ApiConstants.getProfileById(userId)),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (profileResponse.statusCode == 200) {
          final profileData = jsonDecode(profileResponse.body);
          final fullName = profileData['fullname'];

          if (fullName != null) {
            await prefs.setString('fullname', fullName);
          }
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
      else {
        final errorData = jsonDecode(response.body);
        setState(() => _error = errorData['error'] ?? 'Đăng nhập thất bại.');
      }
    } catch (e) {
      print('Login error: $e');
      setState(() => _error = "Lỗi kết nối đến máy chủ.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        backgroundColor: Colors.red[50],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 180,
                    child: Center(
                      child: Image.network(
                        'https://res.cloudinary.com/dsj4lnlkh/image/upload/v1754325524/LogoTMH_cr3rs0.png',
                        width: 500,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _isObscure = !_isObscure);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _signInWithGoogle, // ✅ Gọi hàm ở đây
                        icon: const Icon(Icons.email_outlined, color: Colors.blue),
                        iconSize: 40,
                        tooltip: 'Login with Google',
                      ),
                      const SizedBox(width: 18),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.facebook_outlined, color: Colors.blue),
                        iconSize: 40,
                        tooltip: 'Login with Facebook',
                      ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Text('Login'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      // TODO: Forgot password
                    },
                    child: const Text('Forgot password?'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterPage()),
                          );
                        },
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
