import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trackmentalhealth/utils/showToast.dart';
import '../../../core/constants/chat_api.dart';
import '../../../models/Appointment.dart';
import '../../../models/User.dart';
import '../../../utils/showConfirm.dart';
import '../../notification/DTO/NotDTO.dart';

class AppointmentManagementPage extends StatefulWidget {
  final User currentUser;

  const AppointmentManagementPage({super.key, required this.currentUser});

  @override
  State<AppointmentManagementPage> createState() => _AppointmentManagementPageState();
}

class _AppointmentManagementPageState extends State<AppointmentManagementPage> {
  List<Appointment> appointments = [];
  bool loading = true;
  String? error;
  int? psyId;

  int currentPage = 1;
  final int itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _findPsyId();
  }
  
  Future<void> _findPsyId() async {
    try {
      print("Finding psyId for user: ${widget.currentUser.id}, ${widget.currentUser.fullName}");
      // Lấy danh sách psychologists và tìm psyId từ userId
      final psychologists = await getPsychologists();
      print("Found ${psychologists.length} psychologists");
      
      final psy = psychologists.firstWhere(
        (p) => p.usersID?.id == widget.currentUser.id,
        orElse: () => throw Exception('Psychologist not found for userId: ${widget.currentUser.id}'),
      );
      
      if (psy.id == null) {
        throw Exception('Psychologist ID is null');
      }
      
      setState(() {
        psyId = psy.id;
      });
      
      print("Found psyId: $psyId");
      // Sau khi tìm được psyId, mới fetch appointments
      fetchAppointments();
    } catch (e) {
      setState(() {
        error = "Failed to find psychologist ID: $e";
        loading = false;
      });
    }
  }

  Future<void> fetchAppointments() async {
    if (psyId == null) {
      setState(() {
        error = "Psychologist ID not found";
        loading = false;
      });
      return;
    }
    
    setState(() => loading = true);
    try {
      final res = await getAppointmentByPsyId(psyId!);
      final data = res is List<Appointment> ? res : [];

      // Sắp xếp: pending trước, mới nhất trước
      final sorted = [...data]..sort((a, b) => b.timeStart.compareTo(a.timeStart));
      final pending = sorted.where((a) => a.status == 'PENDING').toList();
      final others = sorted.where((a) => a.status != 'PENDING').toList();

      setState(() {
        appointments = [...pending, ...others];
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = "Failed to load appointments.";
        loading = false;
      });
    }
  }

  String formatDateTime(DateTime dt) {
    return DateFormat('MM/dd/yyyy hh:mm a').format(dt);
  }

  Widget renderStatusBadge(String status) {
    Color bgColor;
    switch (status) {
      case 'ACCEPTED':
        bgColor = Colors.green;
        break;
      case 'DECLINED':
        bgColor = Colors.red;
        break;
      case 'PENDING':
      default:
        bgColor = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: status == 'PENDING' ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> handleAccept(Appointment appt) async {
    final confirmed = await showConfirm(context, "Do you want to accept this appointment?");
    if (!confirmed) return;

    try {
      appt.status = 'ACCEPTED';
      if (appt.id == null) {
        showToast("Appointment ID is null!", "error");
        return;
      }
      await updateAppointment(appt.id!, appt as Map<String, dynamic>);

      // Tạo notification cho user
      if (appt.user!.id != null) {
        final noti = NotDTO(appt.user!.id!, 'The expert has accepted your invitation.');
        await saveNotification(noti);
      }

      showToast("Appointment accepted!", "success");
      fetchAppointments();
    } catch (e) {
      showToast("Error accepting appointment!", "error");
    }
  }

  Future<void> handleDecline(Appointment appt) async {
    final confirmed = await showConfirm(context, "Are you sure you want to decline this appointment?");
    if (!confirmed) return;

    try {
      appt.status = 'DECLINED';
      await updateAppointment(appt.id!, appt as Map<String, dynamic>);

      if (appt.user!.id != null) {
        final noti = NotDTO(appt.user!.id!, 'The expert has declined your invitation.');
        await saveNotification(noti);
      }
      showToast("Appointment declined.", "error");
      fetchAppointments();
    } catch (e) {
      showToast("Error declining appointment!", "error");
    }
  }


  @override
  Widget build(BuildContext context) {
    final totalPages = (appointments.length / itemsPerPage).ceil();
    final startIndex = (currentPage - 1) * itemsPerPage;
    final currentItems = appointments.skip(startIndex).take(itemsPerPage).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Appointment Management"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(child: Text(error!))
            : appointments.isEmpty
            ? const Center(child: Text("No appointments found."))
            : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("#")),
                    DataColumn(label: Text("Full Name")),
                    DataColumn(label: Text("Time")),
                    DataColumn(label: Text("Note")),
                    DataColumn(label: Text("Status")),
                    DataColumn(label: Text("Actions")),
                  ],
                  rows: currentItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(Text('${startIndex + index + 1}')),
                        DataCell(Text(item.user!.fullName ?? 'Anonymous')),
                        DataCell(Text(formatDateTime(item.timeStart!))),
                        DataCell(Text(item.note ?? 'None')),
                        DataCell(renderStatusBadge(item.status!)),
                        DataCell(
                          item.status == 'PENDING'
                              ? Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => handleAccept(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => handleDecline(item),
                              ),
                            ],
                          )
                              : const Text("Processed", style: TextStyle(fontStyle: FontStyle.italic)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
                  child: const Text("Previous"),
                ),
                Text("Page $currentPage of $totalPages"),
                ElevatedButton(
                  onPressed: currentPage < totalPages ? () => setState(() => currentPage++) : null,
                  child: const Text("Next"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}