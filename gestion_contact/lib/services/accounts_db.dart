import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
//import 'dart:io';
import '../models/account.dart';

class AccountsDb {
  static Database? _db;
  static const String _dbName = 'accounts.db';
  static const int _dbVersion = 1;
  static const String tableAccounts = 'accounts';

  // Getter de la DB
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  // INITIALISATION DB (important!!)
  static Future<void> initDb() async {
    await database; // force create
  }

  static Future<Database> _initDb() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableAccounts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
          )
        ''');
      },
    );
  }

  static Future<List<Account>> getAllAccounts() async {
    final db = await database;
    final maps = await db.query(tableAccounts, orderBy: 'id ASC');
    return maps.map((m) => Account(
      id: m['id'].toString(),
      name: m['name'] as String,
      email: m['email'] as String,
      password: m['password'] as String,
    )).toList();
  }

  static Future<int> insertAccount(Account account) async {
    final db = await database;
    return await db.insert(tableAccounts, {
      'name': account.name,
      'email': account.email,
      'password': account.password,
    });
  }

  static Future<int> updateAccount(Account account) async {
    final db = await database;
    return await db.update(
      tableAccounts,
      {
        'name': account.name,
        'email': account.email,
        'password': account.password,
      },
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  static Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete(
      tableAccounts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}


