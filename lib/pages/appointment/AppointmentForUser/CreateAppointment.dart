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
    final now = DateTime.now();
    final local = now.toLocal();
    timeStartController.text = DateFormat("yyyy-MM-dd HH:mm").format(local);
  }

  Future<void> fetchPsychologists() async {
    try {
      final res = await getPsychologists();
      setState(() {
        psychologists = res;
      });
    } catch (e) {
      print("Error fetchPsychologists: $e");
      showToast("Không tải được danh sách psychologist", "error");
    }
  }

  Future<void> handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUserId = await UserSession.getUserId();
    if (currentUserId == null) {
      showToast("Không tìm thấy userId", "error");
      return;
    }

    final payload = {
      "timeStart": timeStartController.text,
      "status": "PENDING",
      "note": noteController.text,
      "user": {"id": currentUserId},
      "psychologist": {"id": int.parse(selectedPsychologistId!)},
    };

    try {
      setState(() => loading = true);

      await saveAppointment(payload);
      showToast("Create appointment successfully", "success");

      // Gửi notification
      final notUser = NotDTO(
        currentUserId,
        "New appointment created successfully",
      );
      final notPsy = NotDTO(
        selectedPsyUserId!,
        "You have a new appointment invitation with user $currentUserId at ${timeStartController.text}",
      );

      await Future.wait([saveNotification(notUser), saveNotification(notPsy)]);

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          "/user/appointment/$currentUserId",
        );
      }
    } catch (e) {
      print("Submit error: $e");
      showToast("Không thể tạo lịch hẹn", "error");
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
                  // Thời gian
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
                              DateFormat("yyyy-MM-dd HH:mm")
                                  .format(selected);
                        }
                      }
                    },
                    validator: (v) =>
                    v == null || v.isEmpty ? "Chọn thời gian" : null,
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
                        child:
                        Text(p.usersID.fullName ?? "Unknown"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPsychologistId = value;
                        final selected =
                        psychologists.firstWhere(
                              (p) => p.id.toString() == value,
                          orElse: () => null,
                        );
                        selectedPsyUserId = selected?.usersID?.id;
                      });
                    },
                    validator: (v) => v == null
                        ? "Please select psychologist"
                        : null,
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
