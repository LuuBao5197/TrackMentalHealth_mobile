import 'package:flutter/material.dart';
import 'package:trackmentalhealth/pages/appointment/AppointmentForUser/CreateAppointment.dart';
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
      final userId = await UserSession.getUserId();
      if (userId == null) {
        showToast("Không tìm thấy userId", "error");
        return;
      }
      final res = await getAppointmentByUserId(userId);
      final data = res is List ? res : [];
      setState(() => appointments = data);
    } catch (e) {
      showToast("Không thể tải lịch hẹn", "error");
      setState(() => appointments = []);
    } finally {
      setState(() => loading = false);
    }
  }

  void handleAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateAppointment()),
    );
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
          const SnackBar(content: Text("Delete appointment successfully")),
        );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),

        Card(
          elevation: 2,
          color: theme.cardColor,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    colorScheme.primary.withOpacity(0.1),
                  ),
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                  border: TableBorder.all(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                  columnSpacing: 24,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 64,
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

                    Color statusColor;
                    switch (status) {
                      case 'PENDING':
                        statusColor = Colors.orange;
                        break;
                      case 'ACCEPTED':
                        statusColor = Colors.green;
                        break;
                      case 'DECLINED':
                        statusColor = Colors.red;
                        break;
                      default:
                        statusColor = Colors.grey;
                    }

                    return DataRow(
                      color: MaterialStateProperty.resolveWith<Color?>(
                            (states) => index.isEven
                            ? theme.colorScheme.surfaceVariant.withOpacity(0.2)
                            : null,
                      ),
                      cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(
                          item['user']?['fullname'] ?? 'Ẩn danh',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        )),
                        DataCell(Text(
                          DateTime.tryParse(item['timeStart'] ?? '')
                              ?.toLocal()
                              .toString() ??
                              '',
                        )),
                        DataCell(Text(item['note'] ?? 'Không có')),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        )),
                        DataCell(Row(
                          children: [
                            if (status == 'PENDING') ...[
                              ElevatedButton.icon(
                                onPressed: () => handleEdit(item['id']),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton.icon(
                                onPressed: () => handleDelete(item['id']),
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Delete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.error,
                                  foregroundColor: colorScheme.onError,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ] else if (status == 'ACCEPTED' && review == null)
                              OutlinedButton(
                                onPressed: () => handleDone(item),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                  side: BorderSide(color: colorScheme.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Done'),
                              )
                            else
                              const Text(
                                'Processed',
                                style: TextStyle(color: Colors.grey),
                              ),
                          ],
                        )),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Appointments',
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 2,
        shadowColor: Colors.black45,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Add button
            ElevatedButton.icon(
              onPressed: handleAdd,
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add New Appointment',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
              ),
            ),
            const SizedBox(height: 20),

            // Pending
            renderTable(
              appointments
                  .where((a) => a['status'] == 'PENDING')
                  .toList(),
              'Pending Appointments',
            ),
            const SizedBox(height: 16),

            // Processed
            renderTable(
              appointments
                  .where((a) => a['status'] != 'PENDING')
                  .toList(),
              'Processed Appointments',
            ),

            if (appointments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No appointments yet.',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: showReviewModal
          ? FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.rate_review, color: Colors.white),
      )
          : null,
    );
  }
}
