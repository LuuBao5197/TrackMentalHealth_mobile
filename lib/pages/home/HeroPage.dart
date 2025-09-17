import 'package:flutter/material.dart';
import '../../core/constants/mood_api.dart';
import 'mood_history_page.dart';

class HeroPage extends StatefulWidget {
  const HeroPage({super.key});

  @override
  State<HeroPage> createState() => _HeroPageState();
}

class _HeroPageState extends State<HeroPage> {
  List<dynamic> moodLevels = [];
  int? selectedMoodId;
  String note = '';
  bool loading = false;
  Map<String, dynamic>? todayMood;
  String aiSuggestion = '';

  final TextEditingController _noteController = TextEditingController();

  /// 🧠 Map mood name to emoji icon
  final Map<String, String> moodIcons = {
    "Very bad": "😢",
    "Bad": "😟",
    "Normal": "😐",
    "Happy": "😊",
    "Very happy": "😄",
  };

  @override
  void initState() {
    super.initState();
    loadMoodLevels();
    loadTodayMood();
  }

  Future<void> loadMoodLevels() async {
    try {
      final levels = await getMoodLevels();
      setState(() {
        moodLevels = levels;
      });
    } catch (e) {
      print("❌ Error fetching mood levels: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading mood levels: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> loadTodayMood() async {
    try {
      final mood = await getTodayMood();
      if (mood != null) {
        setState(() {
          todayMood = mood;
          selectedMoodId = mood['moodLevel']['id'];
          note = mood['note'] ?? '';
          aiSuggestion = mood['aiSuggestion'] ?? '';
          _noteController.text = note;
        });
      }
    } catch (e) {
      print("❌ Error fetching today’s mood: $e");
    }
  }

  Future<void> handleSubmit() async {
    if (selectedMoodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a mood')),
      );
      return;
    }

    note = _noteController.text.trim();

    // ✅ Check if no changes
    if (todayMood != null &&
        todayMood!['moodLevel']['id'] == selectedMoodId &&
        todayMood!['note'] == note) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes detected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => loading = true);

    final moodLevel = moodLevels.firstWhere((m) => m['id'] == selectedMoodId);
    final body = {
      "note": note,
      "date": DateTime.now().toIso8601String().split("T")[0],
      "moodLevel": {"id": selectedMoodId, "name": moodLevel['name']}
    };

    try {
      final result = todayMood != null
          ? await updateMood(todayMood!['id'], body)
          : await createMood(body);

      // Nếu backend trả message (ví dụ lỗi mâu thuẫn), ném exception
      if (result.containsKey('message')) {
        throw Exception(result['message']);
      }

      setState(() {
        aiSuggestion = result["aiSuggestion"] ?? "✅ Update successful";
        todayMood = result;
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Suggestion"),
          content: Text(aiSuggestion),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } catch (e) {
      print("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.deepOrangeAccent,
        ),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Record Mood"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: moodLevels.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              Text(
                todayMood != null
                    ? "💬 Your mood today"
                    : "💬 How do you feel today?",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: moodLevels.map((m) {
                  final name = m['name'] as String;
                  final icon = moodIcons[name] ?? '❔';
                  final isSelected = selectedMoodId == m['id'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedMoodId = m['id'];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 90,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.teal.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.teal
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.teal.shade800
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                onChanged: (val) => note = val,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "📝 Add notes about your mood today...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(loading
                    ? "Saving..."
                    : todayMood != null
                    ? "📤 Update mood"
                    : "💾 Save mood"),
                onPressed: loading ? null : handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MoodHistoryPage()),
                  );
                },
                child: const Text("📅 View Mood History"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
