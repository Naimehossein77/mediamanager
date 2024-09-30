import 'dart:async';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class EmbeddingData {
  final int id;
  final String label;
  final List<double> embedding;

  EmbeddingData(this.id, this.label, this.embedding);
}

class ImageModel {
  final int? id; // Nullable because it will be assigned by the database.
  final int userId;
  final String imagePath;

  ImageModel({this.id, required this.userId, required this.imagePath});

  // Convert a ImageModel instance to a Map. Useful for database operations.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id, // Include id only if it is not null.
      'user_id': userId,
      'image_path': imagePath,
    };
  }

  // Create an ImageModel from a Map. Useful for extracting from database query results.
  factory ImageModel.fromMap(Map<String, dynamic> map) {
    return ImageModel(
      id: map['id'],
      userId: map['user_id'],
      imagePath: map['image_path'],
    );
  }
}

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  // Database reference
  static Database? _database;

  DatabaseHelper._internal();

  // Getter for the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Instantiate the database

    _database = await initDatabase();
    print('initialized database');
    return _database!;
  }

  // Initialize the database
  Future<Database?> initDatabase() async {
    print('init database');
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'embeddings.db');
      deleteDatabase(path);
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Create the embeddings table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE embeddings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT,
        embedding BLOB NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE user_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        image_path TEXT NOT NULL
      );
    ''');
  }

  Future<int> insertEmbedding(String label, List<double> embedding) async {
    final db = await database;
    final embeddingString = embedding.join(',');
    return await db
        .insert('embeddings', {'embedding': embeddingString, 'label': label});
  }

  Future<int> insertImagePath(int userId, String imagePath) async {
    final db = await database;
    return await db
        .insert('user_images', {'user_id': userId, 'image_path': imagePath});
  }

  Future<List<EmbeddingData>> getAllEmbeddings() async {
    final db = await database;
    final results = await db.query('embeddings');
    return results.map((map) {
      return EmbeddingData(
        map['id'] as int,
        map['label'] as String,
        map['embedding']
            .toString()
            .split(',')
            .map((e) => double.parse(e))
            .toList(),
      );
    }).toList();
  }

  Future<List<ImageModel>> getImagesByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_images',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      return ImageModel.fromMap(maps[i]);
    });
  }

  // Future<List<List<double>>> getAllEmbeddings() async {
  //   final db = await database;
  //   final results = await db.query('embeddings');
  //   print(results);
  //   return results
  //       .map((map) => map['embedding']
  //           .toString()
  //           .split(',')
  //           .map((e) => double.parse(e))
  //           .toList())
  //       .toList();
  // }

  Future<void> deleteAllEmbeddings() async {
    final db = await database;
    await db.rawDelete('DELETE FROM embeddings');
  }

  // Close the database
  Future close() async {
    final db = await database;
    db.close();
  }
}
