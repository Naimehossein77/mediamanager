import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper db = DatabaseHelper._();

  DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  Future<Database> initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'FilePathsDB.db');
    return await openDatabase(path, version: 1, onOpen: (db) {},
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE FilePaths (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT UNIQUE
          )
        ''');
      },
    );
  }

  Future<int> insertFilePath(String path) async {
    final db = await database;
    return await db.insert('FilePaths', {'path': path}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<String>> getAllFilePaths() async {
    final db = await database;
    final res = await db.query('FilePaths');
    List<String> list =
      res.isNotEmpty ? res.map((c) => c['path'] as String).toList() : [];
    return list;
  }
}