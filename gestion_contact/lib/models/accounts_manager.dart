import 'account.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AccountsManager {
  static List<Account> _accounts = [];

  static List<Account> get accounts => _accounts;

  static Future<void> init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString("accounts");

    if (data != null) {
      List decoded = jsonDecode(data);
      _accounts = decoded.map((e) => Account.fromJson(e)).toList();
    }
  }

  static Future<void> save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        "accounts", jsonEncode(_accounts.map((e) => e.toJson()).toList()));
  }

  static Future<void> add(Account a) async {
    _accounts.add(a);
    await save();
  }

  static Future<void> update(Account a) async {
    int index = _accounts.indexWhere((x) => x.id == a.id);
    if (index != -1) _accounts[index] = a;
    await save();
  }

  static Future<void> delete(Account a) async {
    _accounts.removeWhere((x) => x.id == a.id);
    await save();
  }
}
