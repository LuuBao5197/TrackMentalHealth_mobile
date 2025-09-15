import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmentalhealth/core/constants/api_constants.dart';
import 'package:trackmentalhealth/main.dart';
import 'package:trackmentalhealth/models/User.dart' as model;
import 'package:trackmentalhealth/pages/login/ForgotPasswordPage.dart';
import 'package:trackmentalhealth/pages/login/RegisterPage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:image_picker/image_picker.dart';
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

  String? _saveEmail; // lưu email đã login trước đó
  bool _showFaceLogin = false; // true nếu có email đã lưu

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _saveEmail = prefs.getString('email'); // dùng username đã lưu trong login cũ
      _showFaceLogin = _saveEmail != null;
    });
  }

  Future<void> _loginWithFaceId() async {
    try {
      if (_saveEmail == null) {
        setState(() => _error = "No saved user for FaceID login.");
        return;
      }

      // --- 1. Chụp ảnh từ camera ---
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile == null) {
        setState(() => _error = "No image captured.");
        return;
      }

      // --- 2. Gửi ảnh sang Flask để lấy embedding ---
      final flaskUrl = "${ApiConstants.flaskBaseUrl}/generate-embedding";
      final request = http.MultipartRequest('POST', Uri.parse(flaskUrl))
        ..files.add(await http.MultipartFile.fromPath('image', pickedFile.path));

      final flaskResponse = await request.send();
      final flaskBody = await flaskResponse.stream.bytesToString();
      if (flaskResponse.statusCode != 200) {
        String msg;
        try {
          final data = jsonDecode(flaskBody);
          msg = data['error'] ?? "Face not recognized";
        } catch (_) {
          msg = "Face not recognized";
        }
        setState(() => _error = msg);
        return;
      }


      final flaskData = jsonDecode(flaskBody);
      final embedding = List<double>.from(flaskData); // Flask trả mảng

      // --- 3. Gửi email + embedding sang Spring Boot ---
      final response = await http.post(
        Uri.parse(ApiConstants.loginWithFaceId),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _saveEmail,
          'embedding': embedding,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        final decodedToken = JwtDecoder.decode(token);
        final userId = decodedToken['userId'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setInt('userId', userId);
        await prefs.setString('email', _saveEmail!);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        setState(() => _error = _getErrorMessage(response));
      }
    } catch (e) {
      setState(() => _error = "FaceID login failed: $e");
    }
  }

  void _switchToAnotherAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    setState(() {
      _saveEmail = null;
      _showFaceLogin = false;
    });
  }

  /// Extracts an error message safely from API responses.
  String _getErrorMessage(http.Response response) {
    try {
      final parsed = jsonDecode(response.body);
      if (parsed is Map<String, dynamic>) {
        for (final key in ['message', 'error', 'detail', 'msg']) {
          final value = parsed[key];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
      }
      if (parsed is String && parsed.trim().isNotEmpty) {
        return parsed.trim();
      }
    } catch (_) {
      // Ignore JSON parsing errors
    }
    return response.body.toString().trim();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final googleUser = await GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: "713857311495-mvg33eppl0s6rjiju5chh0rt02ho0ltb.apps.googleusercontent.com",
      ).signIn();

      if (googleUser == null) {
        setState(() {
          _isLoading = false;
          _error = "You cancelled Google sign in.";
        });
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        setState(() => _error = "Unable to get Google ID Token.");
        return;
      }

      // Gọi backend API thay vì Firebase
      final response = await http.post(
        Uri.parse(ApiConstants.loginWithGoogle),
        body: {'idToken': idToken},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        await prefs.setString('token', data['token']);
        await prefs.setInt('userId', user['id']);
        await prefs.setString('fullname', user['fullname']);
        await prefs.setString('avatar', user['avatar'] ?? '');
        await prefs.setString('role', user['role']);
        await prefs.setString('email', user['email']);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        final msg = _getErrorMessage(response);
        setState(() => _error = msg);

        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      }
    } catch (e) {
      print("Google login error: $e");
      setState(() => _error = "Google login failed. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void parseToken(String token) {
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
      setState(() => _error = "Please enter all required fields.");
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

        final decodedToken = JwtDecoder.decode(token);
        final userId = decodedToken['userId'];
        final emailFromToken = decodedToken['sub'];
        final role = decodedToken['role'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setInt('userId', userId);
        await prefs.setString('email', emailFromToken);
        await prefs.setString('role', role);
        await prefs.setString('username', emailFromToken);

        // Fetch user profile
        final profileResponse = await http.get(
          Uri.parse("${ApiConstants.baseUrl}/users/profile/$userId"),
          headers: {"Authorization": "Bearer $token"},
        );

        if (profileResponse.statusCode == 200) {
          final profileData = jsonDecode(profileResponse.body);

          if (profileData['fullname'] != null) {
            await prefs.setString('fullname', profileData['fullname']);
          }
          if (profileData['avatar'] != null) {
            await prefs.setString('avatar', profileData['avatar']);
          }
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        final msg = _getErrorMessage(response);
        setState(() => _error = msg);
      }
    } catch (e) {
      print('Login error: $e');
      setState(() => _error = "Unable to connect to server. Please try again.");
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

                  // ⚡ Nếu có saved username → FaceID login UI
                  if (_showFaceLogin) ...[
                    Text("Welcome back, $_saveEmail!"),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _isObscure = !_isObscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text("Login"),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.face),
                      onPressed: _loginWithFaceId,
                      label: const Text("Login with FaceID"),
                    ),
                    if (_error != null)   // 👈 thêm dòng này
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    TextButton(
                      onPressed: _switchToAnotherAccount,
                      child: const Text("Another Account"),
                    ),
                  ] else ...[
                    // ⚡ UI login cũ vẫn giữ nguyên
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
                            _isObscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() => _isObscure = !_isObscure);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 50),
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _signInWithGoogle,
                          icon: Image.asset(
                            'assets/images/google_logo.png',
                            height: 24,
                          ),
                          label: const Text("Sign in with Google"),
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
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage(),
                          ),
                        );
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
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

            ),
          ),
        ),
      ),
    );
  }
}
