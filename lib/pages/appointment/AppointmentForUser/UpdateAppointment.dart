import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trackmentalhealth/pages/notification/DTO/NotDTO.dart';

import '../../../core/constants/chat_api.dart';
import '../../../helper/UserSession.dart';
import '../../../utils/showToast.dart';

class UpdateAppointment extends StatefulWidget {
  final int appointmentId;
  const UpdateAppointment({Key? key, required this.appointmentId})
      : super(key: key);

  @override
  State<UpdateAppointment> createState() => _UpdateAppointmentPageState();
}

class _UpdateAppointmentPageState extends State<UpdateAppointment> {
  final _formKey = GlobalKey<FormState>();

  List<dynamic> psychologists = [];
  String? selectedPsychologistId;
  int? selectedPsyUserId;

  TextEditingController timeStartController = TextEditingController();
  TextEditingController noteController = TextEditingController();

  bool loading = false;
  bool initialLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPsychologists();
    fetchAppointmentDetail();
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

  Future<void> fetchAppointmentDetail() async {
    try {
      final res = await getAppointmentById(widget.appointmentId);
      // assuming response contains: id, timeStart, note, psychologist{id}, etc.
      setState(() {
        timeStartController.text = res["timeStart"] ?? "";
        noteController.text = res["note"] ?? "";
        selectedPsychologistId = res["psychologist"]["id"].toString();
        selectedPsyUserId = res["psychologist"]["usersID"]["id"];
        initialLoading = false;
      });
    } catch (e) {
      print("Error fetchAppointmentDetail: $e");
      showToast("Failed to load appointment details", "error");
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUserId = await UserSession.getUserId();
    if (currentUserId == null) {
      showToast("UserId not found", "error");
      return;
    }

    final payload = {
      "id": widget.appointmentId,
      "timeStart": timeStartController.text,
      "status": "PENDING", // can be kept or changed depending on your flow
      "note": noteController.text.toString(),
      "user": {"id": currentUserId},
      "psychologist": {"id": int.parse(selectedPsychologistId!)},
    };

    try {
      setState(() => loading = true);

      print("Update Payload JSON: ${jsonEncode(payload)}");

      await updateAppointment(widget.appointmentId, payload);
      showToast("Appointment updated successfully", "success");

      // Send notifications
      final notUser = NotDTO(
        currentUserId,
        "Your appointment has been updated successfully",
      );
      final notPsy = NotDTO(
        selectedPsyUserId!,
        "User $currentUserId updated an appointment at ${timeStartController.text}",
      );
      await Future.wait([saveNotification(notUser), saveNotification(notPsy)]);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (e.toString().contains("CONFLICT")) {
        showToast("This appointment already exists", "error");
      }
      print("Update error: $e");
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
          "Update Appointment",
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
      ),
      body: initialLoading
          ? const Center(child: CircularProgressIndicator())
          : loading
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
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
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
                          timeStartController.text =
                              DateFormat("yyyy-MM-dd'T'HH:mm")
                                  .format(selected);
                        }
                      }
                    },
                    validator: (v) => v == null || v.isEmpty
                        ? "Please select time"
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Note
                  TextFormField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Note",
                      prefixIcon:
                      const Icon(Icons.note_alt_outlined),
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
                  onChanged: null,
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
                          onPressed: handleUpdate,
                          child: Text(
                            "Update",
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
