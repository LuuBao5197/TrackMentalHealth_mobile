import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trackmentalhealth/pages/notification/DTO/NotDTO.dart';

import '../../../core/constants/chat_api.dart';
import '../../../helper/UserSession.dart';
import '../../../utils/showToast.dart';

class CreateAppointment extends StatefulWidget {
  const CreateAppointment({Key? key}) : super(key: key);

  @override
  State<CreateAppointment> createState() => _CreateAppointmentPageState();
}

class _CreateAppointmentPageState extends State<CreateAppointment> {
  final _formKey = GlobalKey<FormState>();

  List<dynamic> psychologists = [];
  String? selectedPsychologistId;
  int? selectedPsyUserId;

  TextEditingController timeStartController = TextEditingController();
  TextEditingController noteController = TextEditingController();

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _setInitialDateTime();
    fetchPsychologists();
  }

  void _setInitialDateTime() {
    final now = DateTime.now().toLocal();
    timeStartController.text = DateFormat("yyyy-MM-dd'T'HH:mm").format(now);
  }

  Future<void> fetchPsychologists() async {
    try {
      final res = await getPsychologists();
      setState(() {
        psychologists = res;
      });
    } catch (e) {
      print("Error fetchPsychologists: $e");
      showToast("Failed to load psychologists list", "error");
    }
  }

  Future<void> handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUserId = await UserSession.getUserId();
    if (currentUserId == null) {
      showToast("UserId not found", "error");
      return;
    }

    final payload = {
      "timeStart": timeStartController.text,
      "status": "PENDING",
      "note": noteController.text.toString(),
      "user": {"id": currentUserId},
      "psychologist": {"id": int.parse(selectedPsychologistId!)},
    };

    try {
      setState(() => loading = true);

      print("Payload JSON: ${jsonEncode(payload)}");

      await saveAppointment(payload);
      showToast("Appointment created successfully", "success");

      // Send notifications
      final notUser = NotDTO(
        currentUserId,
        "New appointment created successfully",
      );
      final notPsy = NotDTO(
        selectedPsyUserId!,
        "You have a new appointment invitation from user $currentUserId at ${timeStartController.text}",
      );
      await Future.wait([saveNotification(notUser), saveNotification(notPsy)]);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (e.toString().contains("CONFLICT")) {
        showToast("This appointment already exists", "error");
      }
      print("Submit error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Create Appointment",
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Start Time
                  TextFormField(
                    controller: timeStartController,
                    decoration: InputDecoration(
                      labelText: "Start Time",
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: now.add(
                          const Duration(days: 365),
                        ),
                      );
                      if (picked != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          final selected = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            time.hour,
                            time.minute,
                          );
                          
                          // Kiểm tra nếu thời gian được chọn nhỏ hơn thời gian hiện tại
                          if (selected.isBefore(now)) {
                            showToast("Cannot select time in the past", "error");
                            return;
                          }
                          
                          timeStartController.text =
                              DateFormat("yyyy-MM-dd'T'HH:mm")
                                  .format(selected);
                        }
                      }
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Please select time";
                      }
                      
                      try {
                        final selectedTime = DateTime.parse(v);
                        if (selectedTime.isBefore(DateTime.now())) {
                          return "Cannot select time in the past";
                        }
                      } catch (e) {
                        return "Invalid time format";
                      }
                      
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Note
                  TextFormField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Note",
                      prefixIcon: const Icon(Icons.note_alt_outlined),
                      hintText: "Enter your note here...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Psychologist dropdown
                  DropdownButtonFormField<String>(
                    value: selectedPsychologistId,
                    decoration: InputDecoration(
                      labelText: "Psychologist",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: psychologists
                        .map<DropdownMenuItem<String>>((p) {
                      return DropdownMenuItem<String>(
                        value: p.id.toString(),
                        child: Text(p.usersID.fullName ?? "Unknown"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPsychologistId = value;
                        final selected = psychologists.firstWhere(
                              (p) => p.id.toString() == value,
                          orElse: () => null,
                        );
                        selectedPsyUserId = selected?.usersID?.id;
                      });
                    },
                    validator: (v) =>
                    v == null ? "Please select a psychologist" : null,
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: handleSubmit,
                          child: Text(
                            "Create",
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
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
