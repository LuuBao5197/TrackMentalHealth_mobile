import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String fullname = "";
  String address = "";
  String dob = "";
  String gender = "Male";
  String email = "";
  String role = "";
  String? avatarUrl;

  File? _avatarFile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final userId = prefs.getInt("userId");

    if (token == null || userId == null) return;

    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/users/profile/$userId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        fullname = data['fullname'] ?? "";
        address = data['address'] ?? "";
        dob = data['dob'] ?? "";
        gender = data['gender'] ?? "Male";
        email = data['email'] ?? "";
        role = data['role'] ?? "";
        avatarUrl = data['avatar'];
        _loading = false;
      });
    } else {
      debugPrint("Failed to load profile: ${response.body}");
      setState(() => _loading = false);
    }
  }

  Future<void> _registerFaceId() async {
    try {
      // 1. Mở camera chụp ảnh
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera);
      if (picked == null) return;

      File imageFile = File(picked.path);

      // 2. Gửi ảnh sang Flask để tạo embedding
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiConstants.flaskBaseUrl}/generate-embedding"),
      );
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      var response = await request.send();
      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Không tạo được embedding từ ảnh")),
        );
        return;
      }

      final respStr = await response.stream.bytesToString();
      final embedding = List<double>.from(jsonDecode(respStr));

      // 3. Gửi embedding + email sang Spring Boot để lưu
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final saveResponse = await http.post(
        Uri.parse(ApiConstants.baseUrl + "/users/register-faceid"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "embedding": embedding, // List<double>
        }),
      );


      if (saveResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ FaceID registered successfully!")),
        );
      } else {
        debugPrint("FaceID register failed: ${saveResponse.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ FaceID register failed")),
        );
      }
    } catch (e) {
      debugPrint("⚠️ Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error: $e")),
      );
    }
  }


  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) return;

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("${ApiConstants.baseUrl}/users/edit-profile"),
    );

    request.headers['Authorization'] = "Bearer $token";
    request.fields['fullname'] = fullname;
    request.fields['address'] = address;
    request.fields['dob'] = dob;
    request.fields['gender'] = gender;

    if (_avatarFile != null) {
      request.files.add(await http.MultipartFile.fromPath('avatar', _avatarFile!.path));
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Update Successfully!")),
        );
        _loadProfile(); // reload profile sau khi save
        Navigator.pop(context, true);
      }
    } else {
      debugPrint("Update failed: ${response.statusCode}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Update failed!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _avatarFile != null
                      ? FileImage(_avatarFile!)
                      : (avatarUrl != null ? NetworkImage(avatarUrl!) : null) as ImageProvider?,
                  child: (_avatarFile == null && avatarUrl == null)
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: fullname,
                decoration: const InputDecoration(labelText: "Full Name"),
                onChanged: (val) => fullname = val,
              ),
              TextFormField(
                initialValue: address,
                decoration: const InputDecoration(labelText: "Address"),
                onChanged: (val) => address = val,
              ),
              TextFormField(
                controller: TextEditingController(text: dob), // dùng controller để hiển thị dob
                readOnly: true, // không cho gõ tay
                decoration: const InputDecoration(
                  labelText: "Date of Birth",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: dob.isNotEmpty ? DateTime.parse(dob) : DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      dob = pickedDate.toIso8601String().split("T")[0];
                      // format yyyy-MM-dd để gửi API
                    });
                  }
                },
              ),
              DropdownButtonFormField(
                value: gender,
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("Male")),
                  DropdownMenuItem(value: "Female", child: Text("Female")),
                ],
                onChanged: (val) => setState(() => gender = val.toString()),
                decoration: const InputDecoration(labelText: "Gender"),
              ),
              TextFormField(
                initialValue: email,
                decoration: const InputDecoration(labelText: "Email"),
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.teal,
                ),
                child: const Text("Save Changes"),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.face, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.deepPurple,
                ),
                onPressed: _registerFaceId,
                label: const Text("Register FaceID"),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
