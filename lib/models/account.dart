class Account {
  final String uid, role, name;
  final bool mustChangePassword, provisioning;
  const Account({
    required this.uid,
    required this.role,
    required this.name,
    required this.mustChangePassword,
    required this.provisioning,
  });
  factory Account.fromMap(String uid, Map<String, dynamic> data) => Account(
    uid: uid,
    role: data['role'] as String? ?? '',
    name: data['name'] as String? ?? '',
    mustChangePassword: data['mustChangePassword'] == true,
    provisioning: data['provisioning'] == true,
  );
  bool get isAdmin => role == 'admin';
}
