import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'siade_local.db');

    return openDatabase(
      path,
      version: 2, // Upgraded from 1
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE users ADD COLUMN photo_url TEXT');
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table des utilisateurs locaux
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id INTEGER,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        phone TEXT,
        poste TEXT,
        organisation TEXT,
        photo_url TEXT,
        access_token TEXT,
        refresh_token TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // File d'attente de synchronisation
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        endpoint TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ─── USERS ──────────────────────────────────────────────────────────────────

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateUserTokens({
    required String email,
    required String accessToken,
    String? refreshToken,
  }) async {
    final db = await database;
    final values = <String, dynamic>{'access_token': accessToken};
    if (refreshToken != null) values['refresh_token'] = refreshToken;
    return db.update('users', values, where: 'email = ?', whereArgs: [email]);
  }

  Future<int> markUserSynced(String email, int remoteId) async {
    final db = await database;
    return db.update(
      'users',
      {'is_synced': 1, 'remote_id': remoteId},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  // ─── SYNC QUEUE ─────────────────────────────────────────────────────────────

  Future<int> addToSyncQueue({
    required String action,
    required String endpoint,
    required String payload,
  }) async {
    final db = await database;
    return db.insert('sync_queue', {
      'action': action,
      'endpoint': endpoint,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
      where: 'retry_count < 5',
    );
  }

  Future<void> deleteSyncItem(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementRetryCount(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<int> getPendingSyncCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE retry_count < 5',
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
