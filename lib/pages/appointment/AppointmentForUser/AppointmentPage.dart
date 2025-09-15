import 'package:flutter/material.dart';
import 'package:trackmentalhealth/pages/appointment/AppointmentForUser/CreateAppointment.dart';
import 'package:trackmentalhealth/pages/notification/DTO/NotDTO.dart';
import 'package:trackmentalhealth/utils/showToast.dart';
import '../../../core/constants/chat_api.dart';
import '../../../helper/UserSession.dart';
import '../../../utils/showConfirm.dart';
import 'UpdateAppointment.dart';

class AppointmentPage extends StatefulWidget {
  final int userId;

  const AppointmentPage({super.key, required this.userId});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  List<dynamic> appointments = [];
  bool loading = true;

  int pendingPage = 1;
  int processedPage = 1;
  final int pageSize = 5;

  bool showReviewModal = false;
  dynamic selectedAppointment;
  double rating = 0;
  String comment = '';

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
      setState(() {
        appointments = data;
        pendingPage = 1;
        processedPage = 1;
      });
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateAppointment(appointmentId: id),
      ),
    );
  }

  Future<void> handleDelete(int id) async {
    final confirm = await showConfirm(context, "Are you sure?");
    if (confirm) {
      try {
        await deleteAppointment(id);
        showToast("Delete appointment successfully", "success");
        fetchAppointments();
      } catch (e) {
        showToast("Lỗi khi xóa lịch hẹn.", "error");
        print(e);
      }
    }
  }

  void handleDone(dynamic appointment) {
    selectedAppointment = appointment;
    rating = 0;
    comment = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.55,
              minChildSize: 0.35,
              maxChildSize: 0.75,
              builder: (_, controller) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Rate Your Appointment',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starIndex = index + 1;
                          return IconButton(
                            onPressed: () {
                              setModalState(() {
                                rating = starIndex.toDouble();
                              });
                            },
                            icon: Icon(
                              starIndex <= rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 36,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Write your comment...',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onChanged: (val) => comment = val,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submitReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrangeAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 6,
                          ),
                          child: const Text(
                            'Submit Review',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> submitReview() async {
    if (rating == 0) {
      showToast("Please provide rating", "warning");
      return;
    }

    setState(() => showReviewModal = true);
    try {
      final userId = widget.userId;
      if (userId == null) {
        showToast("User not found", "error");
        return;
      }

      final psyId = selectedAppointment['psychologist']?['id'];
      if (psyId == null) {
        showToast("Psychologist not found", "error");
        return;
      }

      final payload = {
        'rating': rating,
        'comment': comment,
        'psychologistCode': psyId,
        'user': {'id': userId},
      };

      await createReviewByAppointmentId(selectedAppointment['id'], payload);

      final notificationToPsy = NotDTO(
        selectedAppointment['psychologist']?['usersID']?['id'],
        'New review submitted by ${selectedAppointment['user']?['fullname'] ?? 'a user'}: $rating/5 stars',
      );
      await saveNotification(notificationToPsy);

      setState(() {
        appointments = appointments.map((a) {
          if (a['id'] == selectedAppointment['id']) {
            a['review'] = {'rating': rating, 'comment': comment};
          }
          return a;
        }).toList();
        showReviewModal = false;
      });

      showToast("Review submitted successfully!", "success");
    } catch (err) {
      showToast("Error submitting review", "error");
      print(err);
    } finally {
      setState(() => showReviewModal = false);
    }
  }

  Widget renderTable(List<dynamic> data, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (data.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary)),
          const SizedBox(height: 8),
          Card(
            elevation: 3,
            color: theme.cardColor,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text('No Data',
                    style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                        fontStyle: FontStyle.italic)),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary)),
        const SizedBox(height: 8),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: Colors.black26,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(colorScheme.primary.withOpacity(0.1)),
              headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
              border: TableBorder.all(color: theme.dividerColor, width: 1),
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
                    statusColor = Colors.orangeAccent;
                    break;
                  case 'ACCEPTED':
                    statusColor = Colors.green;
                    break;
                  case 'DECLINED':
                    statusColor = Colors.redAccent;
                    break;
                  default:
                    statusColor = Colors.grey;
                }

                return DataRow(
                  color: MaterialStateProperty.resolveWith<Color?>(
                          (states) => index.isEven ? theme.colorScheme.surfaceVariant.withOpacity(0.15) : null),
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(item['user']?['fullname'] ?? 'Ẩn danh')),
                    DataCell(Text(DateTime.tryParse(item['timeStart'] ?? '')?.toLocal().toString() ?? '')),
                    DataCell(Text(item['note'] ?? 'Không có')),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                      child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    )),
                    DataCell(Row(
                      children: [
                        if (status == 'PENDING') ...[
                          ElevatedButton.icon(
                              onPressed: () => handleEdit(item['id']),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit')),
                          const SizedBox(width: 6),
                          ElevatedButton.icon(
                              onPressed: () => handleDelete(item['id']),
                              icon: const Icon(Icons.delete, size: 16),
                              label: const Text('Delete')),
                        ] else if (status == 'ACCEPTED' && review == null)
                          OutlinedButton(onPressed: () => handleDone(item), child: const Text('Done'))
                        else
                          const Text('Processed'),
                      ],
                    )),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget paginationControls(int currentPage, int totalPages, Function(int) onPageChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        Text(
          'Page $currentPage / $totalPages',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        IconButton(
          onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          icon: const Icon(Icons.arrow_forward_ios),
        ),
      ],
    );
  }

  List<dynamic> getPaginatedList(List<dynamic> data, int page) {
    final start = (page - 1) * pageSize;
    final end = start + pageSize;
    return data.sublist(start, end > data.length ? data.length : end);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final pendingList = appointments.where((a) => a['status'] == 'PENDING').toList();
    final processedList = appointments.where((a) => a['status'] != 'PENDING').toList();

    final pendingTotalPages = (pendingList.length / pageSize).ceil();
    final processedTotalPages = (processedList.length / pageSize).ceil();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Appointments',
            style: TextStyle(
                color: colorScheme.onPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.primary,
        elevation: 2,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: handleAdd,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add New Appointment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 4,
              ),
            ),
            const SizedBox(height: 20),
            renderTable(getPaginatedList(pendingList, pendingPage), 'Pending Appointments'),
            paginationControls(pendingPage, pendingTotalPages, (page) => setState(() => pendingPage = page)),
            const SizedBox(height: 16),
            renderTable(getPaginatedList(processedList, processedPage), 'Processed Appointments'),
            paginationControls(processedPage, processedTotalPages, (page) => setState(() => processedPage = page)),
            if (appointments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No appointments yet.',
                  style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
