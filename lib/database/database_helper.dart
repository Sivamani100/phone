import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/contact_model.dart';
import '../models/call_log_model.dart';
import '../models/blocked_number.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('callin_phone.db');
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

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE call_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE blocked_numbers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL
      )
    ''');

    // Seed mock data
    await _seedMockData(db);
  }

  Future<void> _seedMockData(Database db) async {
    // 1. Seed Contacts
    final mockContacts = [
      ContactModel(name: 'Aditya Sen', phone: '9876543210', email: 'aditya.sen@example.com', isFavorite: true),
      ContactModel(name: 'Roshan Kumar', phone: '8765432109', email: 'roshan.k@example.com', isFavorite: false),
      ContactModel(name: 'Alice Johnson', phone: '7654321098', email: 'alice.j@example.com', isFavorite: true),
      ContactModel(name: 'Bob Miller', phone: '5550199', email: 'bob.m@example.com', isFavorite: false),
      ContactModel(name: 'Jane Smith', phone: '6543210987', email: 'jane.smith@example.com', isFavorite: true),
      ContactModel(name: 'Rajesh Patel', phone: '9123456780', email: 'rajesh.p@example.com', isFavorite: false),
      ContactModel(name: 'Priya Sharma', phone: '9234567812', email: 'priya.s@example.com', isFavorite: false),
      ContactModel(name: 'Carlos Silva', phone: '981234567', email: 'carlos.s@example.com', isFavorite: false),
    ];

    for (var contact in mockContacts) {
      await db.insert('contacts', contact.toMap());
    }

    // 2. Seed Call Logs with varying dates (Today, Yesterday, Older)
    final now = DateTime.now();
    final today = now;
    final yesterday = now.subtract(const Duration(days: 1));
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    final fiveDaysAgo = now.subtract(const Duration(days: 5));

    final mockLogs = [
      CallLogModel(
        name: 'Aditya Sen',
        phone: '9876543210',
        type: 'outgoing',
        timestamp: today.subtract(const Duration(hours: 2)),
        durationSeconds: 125,
      ),
      CallLogModel(
        name: 'Roshan Kumar',
        phone: '8765432109',
        type: 'incoming',
        timestamp: today.subtract(const Duration(hours: 4, minutes: 12)),
        durationSeconds: 45,
      ),
      CallLogModel(
        name: 'Alice Johnson',
        phone: '7654321098',
        type: 'missed',
        timestamp: today.subtract(const Duration(hours: 6)),
        durationSeconds: 0,
      ),
      CallLogModel(
        name: 'Carlos Silva',
        phone: '981234567',
        type: 'outgoing',
        timestamp: yesterday.subtract(const Duration(hours: 1)),
        durationSeconds: 310,
      ),
      CallLogModel(
        name: 'Rajesh Patel',
        phone: '9123456780',
        type: 'incoming',
        timestamp: yesterday.subtract(const Duration(hours: 5)),
        durationSeconds: 85,
      ),
      CallLogModel(
        name: 'Unknown Caller',
        phone: '+919999988888',
        type: 'missed',
        timestamp: yesterday.subtract(const Duration(hours: 8)),
        durationSeconds: 0,
      ),
      CallLogModel(
        name: 'Jane Smith',
        phone: '6543210987',
        type: 'outgoing',
        timestamp: twoDaysAgo.subtract(const Duration(hours: 3)),
        durationSeconds: 140,
      ),
      CallLogModel(
        name: 'Priya Sharma',
        phone: '9234567812',
        type: 'incoming',
        timestamp: fiveDaysAgo.subtract(const Duration(hours: 6)),
        durationSeconds: 220,
      ),
    ];

    for (var log in mockLogs) {
      await db.insert('call_logs', log.toMap());
    }

    // 3. Seed Blocked Numbers
    final mockBlocked = BlockedNumber(phone: '+919999988888', name: 'Spam Telemarketer');
    await db.insert('blocked_numbers', mockBlocked.toMap());
  }

  // --- Contacts CRUD ---
  Future<int> insertContact(ContactModel contact) async {
    final db = await instance.database;
    return await db.insert('contacts', contact.toMap());
  }

  Future<List<ContactModel>> getContacts() async {
    final db = await instance.database;
    final result = await db.query('contacts', orderBy: 'name ASC');
    return result.map((json) => ContactModel.fromMap(json)).toList();
  }

  Future<int> updateContact(ContactModel contact) async {
    final db = await instance.database;
    return await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(int id) async {
    final db = await instance.database;
    return await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await instance.database;
    return await db.update(
      'contacts',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Call Logs CRUD ---
  Future<int> insertCallLog(CallLogModel log) async {
    final db = await instance.database;
    return await db.insert('call_logs', log.toMap());
  }

  Future<List<CallLogModel>> getCallLogs() async {
    final db = await instance.database;
    final result = await db.query('call_logs', orderBy: 'timestamp DESC');
    return result.map((json) => CallLogModel.fromMap(json)).toList();
  }

  Future<int> deleteCallLog(int id) async {
    final db = await instance.database;
    return await db.delete(
      'call_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAllCallLogs() async {
    final db = await instance.database;
    return await db.delete('call_logs');
  }

  // --- Blocked Numbers CRUD ---
  Future<int> insertBlockedNumber(BlockedNumber number) async {
    final db = await instance.database;
    return await db.insert(
      'blocked_numbers',
      number.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BlockedNumber>> getBlockedNumbers() async {
    final db = await instance.database;
    final result = await db.query('blocked_numbers');
    return result.map((json) => BlockedNumber.fromMap(json)).toList();
  }

  Future<int> deleteBlockedNumberByPhone(String phone) async {
    final db = await instance.database;
    return await db.delete(
      'blocked_numbers',
      where: 'phone = ?',
      whereArgs: [phone],
    );
  }

  Future<bool> isBlocked(String phone) async {
    final db = await instance.database;
    final maps = await db.query(
      'blocked_numbers',
      where: 'phone = ?',
      whereArgs: [phone],
    );
    return maps.isNotEmpty;
  }
}
