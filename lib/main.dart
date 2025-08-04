import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmentalhealth/pages/blog/BlogScreen.dart';
import 'package:trackmentalhealth/pages/diary/DiaryScreen.dart';
import 'package:trackmentalhealth/pages/home/HeroPage.dart';
import 'package:trackmentalhealth/pages/home/HomeScreen.dart';
import 'package:trackmentalhealth/pages/login/LoginPage.dart';
import 'package:trackmentalhealth/pages/profile/ProfileScreen.dart';
import 'package:trackmentalhealth/pages/test/TestScreen.dart';
import 'package:trackmentalhealth/pages/content/ContentTabScreen.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/theme_provider.dart';

void main() {
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
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    HeroPage(),
    const TestScreen(),
    const DiaryScreen(),
    const BlogScreen(),
    const ProfileScreen(),
    const ContentTabScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
              decoration: BoxDecoration(
                color: Colors.teal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.person, size: 50, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Hello, User!',
                    style: TextStyle(
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
              onTap: () {
                _onTabTapped(5);
                Navigator.pop(context);
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
                await prefs.remove('token');

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
