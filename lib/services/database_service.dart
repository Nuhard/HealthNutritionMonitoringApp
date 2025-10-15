import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('health_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    // Health Logs Table
    await db.execute('''
      CREATE TABLE health_logs (
        id $idType,
        userId $textType,
        date $textType,
        meal $textType,
        physicalActivity $textType,
        weight $doubleType,
        mood $textType,
        notes TEXT,
        isSynced $boolType,
        createdAt $textType,
        updatedAt $textType
      )
    ''');

    // Symptoms Table
    await db.execute('''
      CREATE TABLE symptoms (
        id $idType,
        userId $textType,
        symptomName $textType,
        severity $textType,
        onsetDate $textType,
        isSynced $boolType,
        createdAt $textType
      )
    ''');

    // Appointments Table
    await db.execute('''
      CREATE TABLE appointments (
        id $idType,
        userId $textType,
        doctorId $textType,
        doctorName $textType,
        specialization $textType,
        appointmentDate $textType,
        timeSlot $textType,
        status TEXT NOT NULL,
        reason TEXT,
        notes TEXT,
        rejectionReason TEXT,
        isSynced $boolType,
        createdAt $textType,
        updatedAt $textType
      )
    ''');

    // User Profile Table (for offline access)
    await db.execute('''
      CREATE TABLE user_profile (
        userId $idType,
        name $textType,
        age $intType,
        gender $textType,
        weight $doubleType,
        height $doubleType,
        email $textType,
        isSynced $boolType,
        updatedAt $textType
      )
    ''');

    // Sync Queue Table (tracks what needs to be synced)
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entityType $textType,
        entityId $textType,
        operation $textType,
        data TEXT,
        createdAt $textType
      )
    ''');
  }

  // ========== HEALTH LOGS CRUD ==========
  
  Future<String> createHealthLog(Map<String, dynamic> log) async {
    final db = await database;
    await db.insert('health_logs', log);
    return log['id'];
  }

  Future<List<Map<String, dynamic>>> getHealthLogs(String userId) async {
    final db = await database;
    return await db.query(
      'health_logs',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  Future<int> updateHealthLog(String id, Map<String, dynamic> log) async {
    final db = await database;
    return await db.update(
      'health_logs',
      log,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteHealthLog(String id) async {
    final db = await database;
    return await db.delete(
      'health_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedHealthLogs() async {
    final db = await database;
    return await db.query(
      'health_logs',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
  }

  // ========== SYMPTOMS CRUD ==========
  
  Future<String> createSymptom(Map<String, dynamic> symptom) async {
    final db = await database;
    await db.insert('symptoms', symptom);
    return symptom['id'];
  }

  Future<List<Map<String, dynamic>>> getSymptoms(String userId) async {
    final db = await database;
    return await db.query(
      'symptoms',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> deleteSymptom(String id) async {
    final db = await database;
    return await db.delete(
      'symptoms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedSymptoms() async {
    final db = await database;
    return await db.query(
      'symptoms',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
  }

  // ========== APPOINTMENTS CRUD ==========
  
  Future<String> createAppointment(Map<String, dynamic> appointment) async {
    final db = await database;
    await db.insert('appointments', appointment);
    return appointment['id'];
  }

  Future<List<Map<String, dynamic>>> getAppointments(String userId) async {
    final db = await database;
    return await db.query(
      'appointments',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'appointmentDate DESC',
    );
  }

  Future<int> updateAppointment(String id, Map<String, dynamic> appointment) async {
    final db = await database;
    return await db.update(
      'appointments',
      appointment,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAppointment(String id) async {
    final db = await database;
    return await db.delete(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedAppointments() async {
    final db = await database;
    return await db.query(
      'appointments',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
  }

  // ========== USER PROFILE ==========
  
  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    final db = await database;
    await db.insert(
      'user_profile',
      profile,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final db = await database;
    final results = await db.query(
      'user_profile',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // ========== SYNC QUEUE ==========
  
  Future<void> addToSyncQueue(String entityType, String entityId, String operation, String data) async {
    final db = await database;
    await db.insert('sync_queue', {
      'entityType': entityType,
      'entityId': entityId,
      'operation': operation,
      'data': data,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'createdAt ASC');
  }

  Future<void> clearSyncQueue(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  // Mark items as synced
  Future<void> markAsSynced(String table, String id) async {
    final db = await database;
    await db.update(
      table,
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clear all data (for logout)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('health_logs');
    await db.delete('symptoms');
    await db.delete('appointments');
    await db.delete('user_profile');
    await db.delete('sync_queue');
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}