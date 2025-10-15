import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  final AppointmentService _appointmentService = AppointmentService.instance;

  late TabController _tabController;
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _recommendations = [];
  bool _isGracePeriodActive = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Load appointments
      _appointments = await _appointmentService.getUserAppointments(user!.uid);

      // Check for active recommendations
      _isGracePeriodActive = await _appointmentService.isGracePeriodActive(user!.uid);
      
      if (_isGracePeriodActive) {
        _recommendations = await _appointmentService.getActiveRecommendations(user!.uid);
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showBookAppointmentDialog() async {
    final doctors = await _appointmentService.getAllDoctors();
    
    Map<String, dynamic>? selectedDoctor;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String? selectedTimeSlot;
    final reasonController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Book Appointment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Doctor selection
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: selectedDoctor,
                  decoration: const InputDecoration(
                    labelText: 'Select Doctor',
                    border: OutlineInputBorder(),
                  ),
                  items: doctors.map((doc) {
                    return DropdownMenuItem(
                      value: doc,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${doc['specialization']} - Rs.${doc['consultation_fee']}', 
                               style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setStateDialog(() => selectedDoctor = val),
                ),
                const SizedBox(height: 15),

                // Date picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Appointment Date'),
                  subtitle: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) {
                      setStateDialog(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 10),

                // Time slot
                if (selectedDoctor != null)
                  DropdownButtonFormField<String>(
                    value: selectedTimeSlot,
                    decoration: const InputDecoration(
                      labelText: 'Time Slot',
                      border: OutlineInputBorder(),
                    ),
                    items: (selectedDoctor!['available_time_slots'] as List)
                        .map((slot) => DropdownMenuItem(
                              value: slot.toString(),
                              child: Text(slot.toString()),
                            ))
                        .toList(),
                    onChanged: (val) => setStateDialog(() => selectedTimeSlot = val),
                  ),
                const SizedBox(height: 15),

                // Reason
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Visit',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                // Notes
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDoctor == null || selectedTimeSlot == null || reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }

                try {
                  await _appointmentService.bookAppointment(
                    userId: user!.uid,
                    doctorId: selectedDoctor!['id'],
                    appointmentDate: selectedDate,
                    timeSlot: selectedTimeSlot!,
                    reason: reasonController.text,
                    notes: notesController.text.isNotEmpty ? notesController.text : null,
                  );

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment booked successfully!')),
                  );
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Book Appointment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status'];
    final date = DateTime.parse(appointment['appointmentDate']);

    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment['doctorName'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        appointment['specialization'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: statusColor,
                  avatar: Icon(statusIcon, color: Colors.white, size: 16),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(DateFormat('dd MMM yyyy').format(date)),
                const SizedBox(width: 20),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(appointment['timeSlot']),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.medical_services, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text('Reason: ${appointment['reason']}')),
              ],
            ),
            if (appointment['notes'] != null && appointment['notes'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Notes: ${appointment['notes']}')),
                ],
              ),
            ],
            if (status == 'rejected' && appointment['rejectionReason'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rejection Reason: ${appointment['rejectionReason']}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cancel Appointment'),
                        content: const Text('Are you sure you want to cancel this appointment?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('No'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Yes, Cancel'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _appointmentService.cancelAppointment(appointment['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Appointment cancelled')),
                      );
                      _loadData();
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> doctor) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    doctor['name'].toString().substring(4, 5).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        doctor['specialization'],
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text('${doctor['rating']}'),
                          const SizedBox(width: 12),
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(doctor['location']),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Consultation Fee: Rs.${doctor['consultationFee']}',
              style: TextStyle(color: Colors.grey[800]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Quick book with recommended doctor
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 300));
                  _showBookAppointmentDialog();
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text('Book with this Doctor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Grace Period Banner
                if (_isGracePeriodActive)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade400, Colors.red.shade400],
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '⏰ Grace Period Active',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Your appointment was rejected. Book with another doctor within 24 hours!',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (ctx) => DraggableScrollableSheet(
                                initialChildSize: 0.7,
                                maxChildSize: 0.9,
                                minChildSize: 0.5,
                                expand: false,
                                builder: (context, scrollController) => Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: const [
                                          Text(
                                            '✨ Recommended Doctors',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Based on your previous selection',
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        controller: scrollController,
                                        itemCount: _recommendations.length,
                                        itemBuilder: (ctx, index) {
                                          return _buildRecommendationCard(_recommendations[index]);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.deepPurple,
                          ),
                          child: const Text('View'),
                        ),
                      ],
                    ),
                  ),

                // Appointments List
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // All appointments
                      _appointments.isEmpty
                          ? const Center(child: Text('No appointments yet'))
                          : ListView.builder(
                              itemCount: _appointments.length,
                              itemBuilder: (ctx, index) {
                                return _buildAppointmentCard(_appointments[index]);
                              },
                            ),

                      // Upcoming
                      ListView.builder(
                        itemCount: _appointments
                            .where((a) => ['pending', 'approved'].contains(a['status']))
                            .length,
                        itemBuilder: (ctx, index) {
                          final upcoming = _appointments
                              .where((a) => ['pending', 'approved'].contains(a['status']))
                              .toList();
                          return _buildAppointmentCard(upcoming[index]);
                        },
                      ),

                      // Past
                      ListView.builder(
                        itemCount: _appointments
                            .where((a) => ['completed', 'rejected', 'cancelled'].contains(a['status']))
                            .length,
                        itemBuilder: (ctx, index) {
                          final past = _appointments
                              .where((a) => ['completed', 'rejected', 'cancelled'].contains(a['status']))
                              .toList();
                          return _buildAppointmentCard(past[index]);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBookAppointmentDialog,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Book Appointment', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}