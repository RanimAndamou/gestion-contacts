import 'package:flutter/material.dart';
import '../models/account.dart';
import 'add_edit_account_screen.dart';
import '../services/accounts_db.dart';
import 'package:go_router/go_router.dart';
//import 'login_screen.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  List<Account> accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    accounts = await AccountsDb.getAllAccounts();
    setState(() {});
  }

  void _addAccount() async {
    final result = await Navigator.push<Account?>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditAccountScreen()),
    );

    if (result != null) {
      await AccountsDb.insertAccount(result);
      await _loadAccounts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte ajouté ✅')),
      );
    }
  }

  void _editAccount(Account account) async {
    final result = await Navigator.push<Account?>(
      context,
      MaterialPageRoute(builder: (_) => AddEditAccountScreen(account: account)),
    );

    if (result != null) {
      await AccountsDb.updateAccount(result);
      await _loadAccounts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte modifié ✏️')),
      );
    }
  }

  void _deleteAccount(Account account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce compte ?'),
        content: Text(
          'Voulez-vous vraiment supprimer le compte "${account.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              // 1️⃣ Supprimer depuis SQLite
              await AccountsDb.deleteAccount(int.parse(account.id));

              // 2️⃣ Supprimer depuis la liste locale
              setState(() {
                accounts.removeWhere((a) => a.id == account.id);
              });

              Navigator.pop(ctx);

              // 3️⃣ Message de confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Compte supprimé 🗑️')),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des comptes'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () {
              context.go('/login');
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

      body: accounts.isEmpty
          ? const Center(child: Text('Aucun compte disponible.'))
          : ListView.builder(
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final acc = accounts[index];
          return ListTile(
            leading: const Icon(Icons.person),
            title: Text(acc.name),
            subtitle: Text(acc.email),
            onTap: () => _editAccount(acc),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteAccount(acc),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _addAccount,
        child: const Icon(Icons.add),
      ),
    );
  }
}
