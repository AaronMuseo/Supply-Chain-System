import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final _firestoreService = FirestoreService();

  void _showUserDialog({AppUser? user, String? docId}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final roleController = TextEditingController(text: user?.role ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user == null ? 'Add User' : 'Edit User'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v == null || v.isEmpty ? 'Enter name' : null),
                TextFormField(controller: emailController, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v == null || v.isEmpty ? 'Enter email' : null),
                TextFormField(controller: roleController, decoration: const InputDecoration(labelText: 'Role'), validator: (v) => v == null || v.isEmpty ? 'Enter role' : null),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final userData = {
                  'name': nameController.text,
                  'email': emailController.text,
                  'role': roleController.text,
                };
                if (user == null) {
                  await _firestoreService.addUser(userData);
                } else {
                  await _firestoreService.updateUser(docId!, userData);
                }
                Navigator.pop(context);
              }
            },
            child: Text(user == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: StreamBuilder(
        stream: _firestoreService.getUsers(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          final docs = snapshot.data!.docs;
          final users = docs.map<AppUser>((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return AppUser(
              id: doc.id,
              name: data['name'] ?? '',
              email: data['email'] ?? '',
              role: data['role'] ?? '',
            );
          }).toList();
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: ListTile(
                  title: Text(user.name),
                  subtitle: Text('\${user.email} (\${user.role})'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showUserDialog(user: user, docId: user.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await _firestoreService.deleteUser(user.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
