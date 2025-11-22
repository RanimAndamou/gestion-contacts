class Account {
  String id;
  String name;
  String email;
  String password;

  Account({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  // Convertit JSON → Account
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json["id"].toString(),
      name: json["name"] ?? '',
      email: json["email"] ?? '',
      password: json["password"] ?? '',
    );
  }

  // Convertit Account → JSON
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "password": password,
    };
  }
}