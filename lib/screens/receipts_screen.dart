import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class ReceiptsScreen extends StatelessWidget {
  final _firestoreService = FirestoreService();

  ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Receipts')),
      body: StreamBuilder(
        stream: _firestoreService.getCustomerReceipts(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No receipts found.'));
          }
          final docs = snapshot.data!.docs;
          
          // Keep data as a List of Maps, similar to PurchasesScreen
          final receipts = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'data': data,
            };
          }).toList();
          
          return ListView.builder(
            itemCount: receipts.length,
            itemBuilder: (context, index) {
              final receipt = receipts[index];
              final data = receipt['data'] as Map<String, dynamic>;
              final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

              return Card(
                child: ListTile(
                  title: Text('Receipt ID: ${receipt['id']}'),
                  subtitle: Text('Total: KSh${data['total'].toStringAsFixed(2)}\nDate: ${data['date']}'),
                  isThreeLine: true,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Receipt Details'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: items.map((item) {
                            final name = item['productName'] ?? 'Unknown';
                            final qty = item['quantity']?.toString() ?? '0';
                            final price = item['unitPrice']?.toStringAsFixed(2) ?? '0.00';
                            return ListTile(
                              title: Text(name),
                              subtitle: Text('Qty: $qty | Unit Price: KSh$price'),
                            );
                          }).toList(),
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
