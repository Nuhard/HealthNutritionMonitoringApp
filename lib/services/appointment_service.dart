import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'sync_service.dart';

class AppointmentService {
  static final AppointmentService instance = AppointmentService._init();
  final DatabaseService _localDb = DatabaseService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final SyncService _syncService = SyncService.instance;
  
  List<Map<String, dynamic>> _doctors = [];
  final int gracePeriodHours = 24; // Grace period in hours

  AppointmentService._init();

  // Load doctors from JSON
  Future<void> loadDoctors() async {
    if (_doctors.isNotEmpty) return;
    
    final jsonString = await rootBundle.loadString('assets/data/doctors_database.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _doctors = List<Map<String, dynamic>>.from(jsonMap['doctors']);
  }

  // Get all doctors
  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    await loadDoctors();
    return _doctors;
  }

  // Get doctor by ID
  Future<Map<String, dynamic>?> getDoctorById(String doctorId) async {
    await loadDoctors();
    try {
      return _doctors.firstWhere((doc) => doc['id'] == doctorId);
    } catch (e) {
      return null;
    }
  }

  // Get doctors by specialization
  Future<List<Map<String, dynamic>>> getDoctorsBySpecialization(String specialization) async {
    await loadDoctors();
    return _doctors.where((doc) => doc['specialization'] == specialization).toList();
  }

  // Book appointment
  Future<String> bookAppointment({
    required String userId,
    required String doctorId,
    required DateTime appointmentDate,
    required String timeSlot,
    required String reason,
    String? notes,
  }) async {
    final doctor = await getDoctorById(doctorId);
    if (doctor == null) throw Exception('Doctor not found');

    final appointmentId = const Uuid().v4();
    final appointment = {
      'id': appointmentId,
      'userId': userId,
      'doctorId': doctorId,
      'doctorName': doctor['name'],
      'specialization': doctor['specialization'],
      'appointmentDate': appointmentDate.toIso8601String(),
      'timeSlot': timeSlot,
      'status': 'pending', // pending, approved, rejected, completed, cancelled
      'reason': reason,
      'notes': notes ?? '',
      'rejectionReason': '',
      'isSynced': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    // Save locally first
    await _localDb.createAppointment(appointment);

    // Try to sync if online
    final online = await _syncService.isOnline();
    if (online) {
      try {
        await _firestore.collection('appointments').doc(appointmentId).set({
          'userId': userId,
          'doctorId': doctorId,
          'doctorName': doctor['name'],
          'specialization': doctor['specialization'],
          'appointmentDate': Timestamp.fromDate(appointmentDate),
          'timeSlot': timeSlot,
          'status': 'pending',
          'reason': reason,
          'notes': notes ?? '',
          'rejectionReason': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _localDb.markAsSynced('appointments', appointmentId);
      } catch (e) {
        print('Failed to sync appointment: $e');
      }
    }

    // Send notification to user
    await _notificationService.showNotification(
      title: 'Appointment Booked',
      body: 'Your appointment with ${doctor['name']} has been requested.',
    );

    return appointmentId;
  }

  // Reject appointment (called by doctor/consultant)
  Future<void> rejectAppointment(String appointmentId, String rejectionReason) async {
    // Update appointment status
    final appointment = await _getAppointmentById(appointmentId);
    if (appointment == null) return;

    await _localDb.updateAppointment(appointmentId, {
      ...appointment,
      'status': 'rejected',
      'rejectionReason': rejectionReason,
      'isSynced': 0,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Sync to Firestore if online
    final online = await _syncService.isOnline();
    if (online) {
      try {
        await _firestore.collection('appointments').doc(appointmentId).update({
          'status': 'rejected',
          'rejectionReason': rejectionReason,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _localDb.markAsSynced('appointments', appointmentId);
      } catch (e) {
        print('Failed to sync rejection: $e');
      }
    }

    // Trigger grace period and recommendations
    await _handleRejectionWithGracePeriod(appointment);
  }

  // Handle rejection with grace period
  Future<void> _handleRejectionWithGracePeriod(Map<String, dynamic> appointment) async {
    final userId = appointment['userId'];
    final specialization = appointment['specialization'];
    final originalDoctorId = appointment['doctorId'];

    // Send notification to patient about rejection
    await _notificationService.showNotification(
      title: '❌ Appointment Rejected',
      body: 'Your appointment has been rejected. Reason: ${appointment['rejectionReason']}',
    );

    // Schedule grace period notification
    await _notificationService.scheduleNotification(
      id: appointment['id'].hashCode,
      title: '⏰ Grace Period Active',
      body: 'You have $gracePeriodHours hours to book with another doctor. Check recommendations!',
      scheduledDate: DateTime.now().add(const Duration(minutes: 5)),
    );

    // Get recommended doctors
    final recommendations = await getRecommendedDoctors(
      specialization: specialization,
      excludeDoctorId: originalDoctorId,
    );

    // Save recommendations to a collection for the user to view
    if (recommendations.isNotEmpty) {
      final online = await _syncService.isOnline();
      if (online) {
        try {
          await _firestore.collection('appointment_recommendations').doc(userId).set({
            'userId': userId,
            'originalAppointmentId': appointment['id'],
            'specialization': specialization,
            'recommendations': recommendations.map((doc) => {
              'id': doc['id'],
              'name': doc['name'],
              'specialization': doc['specialization'],
              'rating': doc['rating'],
              'consultationFee': doc['consultation_fee'],
              'location': doc['location'],
            }).toList(),
            'gracePeriodEnd': Timestamp.fromDate(
              DateTime.now().add(Duration(hours: gracePeriodHours)),
            ),
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          print('Failed to save recommendations: $e');
        }
      }

      // Send another notification with first recommendation
      await _notificationService.showNotification(
        title: '✨ Recommended Doctors Available',
        body: 'Dr. ${recommendations[0]['name']} (${recommendations[0]['specialization']}) - Rating: ${recommendations[0]['rating']}⭐',
      );
    }
  }

  // Get recommended doctors based on criteria
  Future<List<Map<String, dynamic>>> getRecommendedDoctors({
    required String specialization,
    String? excludeDoctorId,
    String? userLocation,
  }) async {
    await loadDoctors();

    // Filter doctors by specialization
    var recommended = _doctors.where((doc) {
      return doc['specialization'] == specialization && 
             doc['id'] != excludeDoctorId;
    }).toList();

    // Sort by rating (descending)
    recommended.sort((a, b) => (b['rating'] as num).compareTo(a['rating'] as num));

    // If user location is provided, prioritize nearby doctors
    if (userLocation != null) {
      recommended = recommended.where((doc) {
        return doc['location'].toString().toLowerCase().contains(userLocation.toLowerCase());
      }).toList();
    }

    // Return top 5 recommendations
    return recommended.take(5).toList();
  }

  // Get user's appointments
  Future<List<Map<String, dynamic>>> getUserAppointments(String userId) async {
    return await _localDb.getAppointments(userId);
  }

  // Get appointment by ID (from local DB)
  Future<Map<String, dynamic>?> _getAppointmentById(String appointmentId) async {
    final db = await _localDb.database;
    final results = await db.query(
      'appointments',
      where: 'id = ?',
      whereArgs: [appointmentId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Approve appointment (called by doctor)
  Future<void> approveAppointment(String appointmentId) async {
    final appointment = await _getAppointmentById(appointmentId);
    if (appointment == null) return;

    await _localDb.updateAppointment(appointmentId, {
      ...appointment,
      'status': 'approved',
      'isSynced': 0,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    final online = await _syncService.isOnline();
    if (online) {
      try {
        await _firestore.collection('appointments').doc(appointmentId).update({
          'status': 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _localDb.markAsSynced('appointments', appointmentId);
      } catch (e) {
        print('Failed to sync approval: $e');
      }
    }

    await _notificationService.showNotification(
      title: '✅ Appointment Approved',
      body: 'Your appointment with ${appointment['doctorName']} has been approved!',
    );
  }

  // Cancel appointment (by user)
  Future<void> cancelAppointment(String appointmentId) async {
    final appointment = await _getAppointmentById(appointmentId);
    if (appointment == null) return;

    await _localDb.updateAppointment(appointmentId, {
      ...appointment,
      'status': 'cancelled',
      'isSynced': 0,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    final online = await _syncService.isOnline();
    if (online) {
      try {
        await _firestore.collection('appointments').doc(appointmentId).update({
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _localDb.markAsSynced('appointments', appointmentId);
      } catch (e) {
        print('Failed to sync cancellation: $e');
      }
    }
  }

  // Check if grace period is still active for a user
  Future<bool> isGracePeriodActive(String userId) async {
    final online = await _syncService.isOnline();
    if (!online) return false;

    try {
      final doc = await _firestore
          .collection('appointment_recommendations')
          .doc(userId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final gracePeriodEnd = (data['gracePeriodEnd'] as Timestamp).toDate();
      return DateTime.now().isBefore(gracePeriodEnd);
    } catch (e) {
      return false;
    }
  }

  // Get active recommendations for user
  Future<List<Map<String, dynamic>>> getActiveRecommendations(String userId) async {
    final online = await _syncService.isOnline();
    if (!online) return [];

    try {
      final doc = await _firestore
          .collection('appointment_recommendations')
          .doc(userId)
          .get();

      if (!doc.exists) return [];

      final data = doc.data()!;
      final gracePeriodEnd = (data['gracePeriodEnd'] as Timestamp).toDate();
      
      if (DateTime.now().isAfter(gracePeriodEnd)) return [];

      return List<Map<String, dynamic>>.from(data['recommendations']);
    } catch (e) {
      return [];
    }
  }
}