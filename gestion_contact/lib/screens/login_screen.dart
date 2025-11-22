import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/account.dart';
//import 'signup_screen.dart';
//import 'accounts_page.dart';
import '../models/accounts_manager.dart';
import '../services/accounts_db.dart';
import 'package:sqflite/sqflite.dart';
import 'package:go_router/go_router.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Veuillez remplir tous les champs ❗", false);
      return;
    }

    final user = AccountsManager.accounts.firstWhere(
          (u) => u.email == email && u.password == password,
      orElse: () => Account(id: '', name: '', email: '', password: ''),
    );

    if (user.email.isNotEmpty) {
      _showMessage("Connexion réussie ✅", true);
    } else {
      _showMessage("Email ou mot de passe incorrect ❌", false);
    }
  }

  void _showMessage(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _login,
              child: const Text('Se connecter'),
            ),

          TextButton(
            onPressed: () => context.go('/signup'),
            child: const Text('Créer un compte'),
          ),

          OutlinedButton(
            onPressed: () => context.go('/accounts'),
            child: const Text('Gérer les comptes'),
          ),

            const SizedBox(height: 30),

            // BUTTON: open built-in DB viewer page
            ElevatedButton(
              onPressed: () async {
                if (kIsWeb) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("SQLite Viewer ne fonctionne pas sur Web ❌"),
                    ),
                  );
                  return;
                }

                final db = await AccountsDb.database;
                final dbPath = db.path;

                // 👉 هنا تعمل التنقل مباشرة (بدون OutlinedButton داخل onPressed)
                context.go(
                  '/database-view',
                  extra: dbPath,
                );
              },
              child: const Text("📂 Voir Database SQLite"),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- Database viewer (no external plugin) ----------
class DatabaseViewPage extends StatefulWidget {
  final String dbPath;
  const DatabaseViewPage({super.key, required this.dbPath});

  @override
  State<DatabaseViewPage> createState() => _DatabaseViewPageState();
}

class _DatabaseViewPageState extends State<DatabaseViewPage> {
  List<String> tables = [];
  String? selectedTable;
  List<Map<String, Object?>> rows = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() => loading = true);
    final db = await openDatabase(widget.dbPath);
    final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name");
    tables = result.map((r) => r['name'] as String).toList();
    // auto-select first table if any
    if (tables.isNotEmpty) selectedTable = tables.first;
    if (selectedTable != null) await _loadRows(selectedTable!);
    setState(() => loading = false);
  }

  Future<void> _loadRows(String table) async {
    setState(() {
      loading = true;
      rows = [];
    });
    final db = await openDatabase(widget.dbPath);
    try {
      final data = await db.query(table, orderBy: 'id ASC');
      rows = data.map((r) => Map<String, Object?>.from(r)).toList();
    } catch (e) {
      // if table has no id column or other issue, just attempt rawQuery
      try {
        final data = await db.rawQuery('SELECT * FROM $table');
        rows = data.map((r) => Map<String, Object?>.from(r)).toList();
      } catch (e) {
        rows = [];
      }
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadTables(),
            tooltip: 'Reload',
          ),

          TextButton(
            onPressed: () {
              context.go('/'); // login
            },
            child: const Text(
              '>',
              style: TextStyle(
                fontSize: 28,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (tables.isEmpty)
              const Center(child: Text('Aucune table trouvée dans la DB.'))
            else
              Row(
                children: [
                  const Text('Table: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedTable,
                    items: tables
                        .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t),
                    ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      selectedTable = v;
                      _loadRows(v);
                    },
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: selectedTable == null
                        ? null
                        : () => _loadRows(selectedTable!),
                    child: const Text('Charger'),
                  )
                ],
              ),
            const SizedBox(height: 12),
            Expanded(
              child: rows.isEmpty
                  ? const Center(child: Text('Aucune ligne à afficher.'))
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: rows.first.keys
                      .map((k) => DataColumn(label: Text(k)))
                      .toList(),
                  rows: rows.map((row) {
                    return DataRow(
                      cells: row.values
                          .map((v) => DataCell(Text(v?.toString() ?? '')))
                          .toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
