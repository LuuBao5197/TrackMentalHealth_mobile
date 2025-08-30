import 'package:flutter/material.dart';
import 'package:trackmentalhealth/utils/showToast.dart';
import '../../../core/constants/chat_api.dart';
import '../../../helper/UserSession.dart';
import '../../../utils/showConfirm.dart';

class AppointmentPage extends StatefulWidget {
  final int userId;
  const AppointmentPage({super.key, required this.userId});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  List<dynamic> appointments = [];
  bool loading = true;

  // Review modal states
  bool showReviewModal = false;
  dynamic selectedAppointment;
  double rating = 0;
  String comment = '';
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    setState(() => loading = true);
    try {
      final userId = await UserSession.getUserId(); // ✅ await thay vì ép kiểu
      if (userId == null) {
        showToast("Không tìm thấy userId", "error");
        return;
      }

      final res = await getAppointmentByUserId(userId);
      final data = res is List ? res : [];
      setState(() => appointments = data);
    } catch (e) {
      showToast("Không thể tải lịch hẹn.", "error");
      setState(() => appointments = []);
    } finally {
      setState(() => loading = false);
    }
  }

  void handleAdd() {
    Navigator.pushNamed(context, '/user/appointment/create/${widget.userId}');
  }

  void handleEdit(int id) {
    Navigator.pushNamed(context, '/user/appointment/edit/$id');
  }

  Future<void> handleDelete(int id) async {
    final confirm = await showConfirm(context, "Are you sure?");
    if (confirm) {
      try {
        await deleteAppointment(id);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Delete appointment successfully")));
        fetchAppointments();
      } catch (e) {
        showToast("Lỗi khi xóa lịch hẹn.", "error");
      }
    }
  }

  void handleDone(dynamic appointment) {
    setState(() {
      selectedAppointment = appointment;
      rating = 0;
      comment = '';
      showReviewModal = true;
    });
  }

  Widget renderTable(List<dynamic> data, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, // ✅ tránh overflow
          child: DataTable(
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Full name')),
              DataColumn(label: Text('Time Start')),
              DataColumn(label: Text('Note')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: List.generate(data.length, (index) {
              final item = data[index];
              final status = item['status'];
              final review = item['review'];
              return DataRow(cells: [
                DataCell(Text('${index + 1}')),
                DataCell(Text(item['user']?['fullname'] ?? 'Ẩn danh',
                    style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(DateTime.tryParse(item['timeStart'] ?? '')
                    ?.toLocal()
                    .toString() ??
                    '')),
                DataCell(Text(item['note'] ?? 'Không có')),
                DataCell(Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'PENDING'
                        ? Colors.yellow[700]
                        : status == 'ACCEPTED'
                        ? Colors.green
                        : status == 'DECLINED'
                        ? Colors.red
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                  Text(status, style: const TextStyle(color: Colors.white)),
                )),
                DataCell(
                  Row(
                    children: [
                      if (status == 'PENDING')
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => handleEdit(item['id']),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit'),
                            ),
                            const SizedBox(width: 4),
                            OutlinedButton.icon(
                              onPressed: () => handleDelete(item['id']),
                              icon: const Icon(Icons.delete, size: 16),
                              label: const Text('Delete'),
                            ),
                          ],
                        )
                      else if (status == 'ACCEPTED' && review == null)
                        OutlinedButton(
                          onPressed: () => handleDone(item),
                          child: const Text('Done'),
                        )
                      else
                        const Text('Processed',
                            style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ]);
            }),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Quay lại màn hình trước
          },
        ),
        title: const Text(
          'My Appointments',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: handleAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add new appointment'),
            ),
            renderTable(
                appointments
                    .where((a) => a['status'] == 'PENDING')
                    .toList(),
                'Pending Appointments'),
            renderTable(
                appointments
                    .where((a) => a['status'] != 'PENDING')
                    .toList(),
                'Processed Appointments'),
            if (appointments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No appointments yet.',
                    style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      floatingActionButton: showReviewModal
          ? FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.rate_review),
      )
          : null,
    );
  }
}
