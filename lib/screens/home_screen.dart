import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class HomeScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome to the Restaurant Supply Chain System!', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickStat(title: 'Menu Items', stream: _firestoreService.getMenuItems()),
                _QuickStat(title: 'Ingredients', stream: _firestoreService.getIngredients()),
                _QuickStat(title: 'Suppliers', stream: _firestoreService.getSuppliers()),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Text('Use the navigation bar below to access all features.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String title;
  final Stream stream;
  const _QuickStat({required this.title, required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (context, AsyncSnapshot snapshot) {
        int count = 0;
        if (snapshot.hasData && snapshot.data?.docs != null) {
          count = snapshot.data.docs.length;
        }
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$count', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        );
      },
    );
  }
}
