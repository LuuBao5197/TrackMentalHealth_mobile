import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


import 'package:trackmentalhealth/pages/blog/BlogScreen.dart';
import 'package:trackmentalhealth/pages/chat/ChatScreen.dart';
import 'package:trackmentalhealth/pages/content/permissions.dart';

import 'package:trackmentalhealth/core/constants/api_constants.dart';
import 'package:trackmentalhealth/pages/blog/BlogScreen.dart';
import 'package:trackmentalhealth/pages/diary/DiaryScreen.dart';
import 'package:trackmentalhealth/pages/home/HeroPage.dart';
import 'package:trackmentalhealth/pages/home/HomeScreen.dart';
import 'package:trackmentalhealth/pages/login/LoginPage.dart';
import 'package:trackmentalhealth/pages/profile/ProfileScreen.dart';
import 'package:trackmentalhealth/pages/test/TestScreen.dart';
import 'package:trackmentalhealth/pages/content/ContentTabScreen.dart';

import 'core/constants/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Gọi xin quyền trước khi vào app
  await requestAppPermissions();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const TrackMentalHealthApp(),
    ),
  );
}

class TrackMentalHealthApp extends StatelessWidget {
  const TrackMentalHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Track Mental Health',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.teal,
          elevation: 2,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.teal,
          secondary: Colors.tealAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.tealAccent,
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    HeroPage(),
    const TestScreen(),
    const DiaryScreen(),
    const BlogScreen(),
    const ChatScreen(),
    const ProfileScreen(),
    const ContentTabScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String? fullname;
  String? avatarUrl;
  bool _loadingProfile = true;
  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('userId');

      if (userId == null || token == null) {
        debugPrint("userId hoặc token bị null");
        setState(() => _loadingProfile = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/users/profile/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String? avatar = data['avatar'];
        // Nếu backend trả về filename, ghép thành URL
        if (avatar != null && !avatar.startsWith('http')) {
          avatar = '${ApiConstants.baseUrl}/uploads/$avatar';
        }

        setState(() {
          fullname = data['fullname'] ?? "User";
          avatarUrl = data['avatar']; // trực tiếp lấy URL Cloudinary
          _loadingProfile = false;
        });

        if (avatarUrl != null) {
          await prefs.setString('avatarUrl', avatarUrl!);
        }
      } else {
        debugPrint("Failed to load profile: ${response.body}");
        setState(() => _loadingProfile = false);
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      setState(() => _loadingProfile = false);
    }
  }


  Widget _buildNavigation(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    if (isWideScreen) {
      return NavigationRail(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabTapped,
        labelType: NavigationRailLabelType.selected,
        destinations: const [
          NavigationRailDestination(icon: Icon(Icons.home), label: Text("Home")),
          NavigationRailDestination(icon: Icon(Icons.emoji_emotions), label: Text("Mood")),
          NavigationRailDestination(icon: Icon(Icons.quiz), label: Text("Test")),
          NavigationRailDestination(icon: Icon(Icons.mood), label: Text("Diary")),
          NavigationRailDestination(icon: Icon(Icons.article), label: Text("Blog")),
          NavigationRailDestination(icon: Icon(Icons.messenger_outline_rounded), label: Text("Chat")),
          NavigationRailDestination(icon: Icon(Icons.person), label: Text("Profile")),
          NavigationRailDestination(icon: Icon(Icons.menu_book), label: Text("Content")),
        ],
      );
    }

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onTabTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.teal[700],
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      elevation: 10,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.emoji_emotions), label: 'Mood'),
        BottomNavigationBarItem(icon: Icon(Icons.quiz_rounded), label: 'Test'),
        BottomNavigationBarItem(icon: Icon(Icons.mood), label: 'Diary'),
        BottomNavigationBarItem(icon: Icon(Icons.article_rounded), label: 'Blog'),
        BottomNavigationBarItem(icon: Icon(Icons.messenger_outline_rounded), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Content'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        shadowColor: Colors.teal.withOpacity(0.3),
        title: Text(
          'Track Mental Health',
          style: TextStyle(
            color: Colors.teal[800],
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.teal[800]),
        actions: [
          Switch(
            value: isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: (avatarUrl == null || avatarUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _loadingProfile ? 'Loading...' : 'Hello, ${fullname ?? "User"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                if (result == true) {
                  _loadProfile(); // reload dữ liệu fullname/avatar
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings Page chưa được tạo.')),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                await FirebaseAuth.instance.signOut();
                final googleSignIn = GoogleSignIn();
                if (await googleSignIn.isSignedIn()) {
                  await googleSignIn.signOut();
                }
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          if (isWideScreen) _buildNavigation(context),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: isWideScreen ? null : _buildNavigation(context),
    );
  }
}
