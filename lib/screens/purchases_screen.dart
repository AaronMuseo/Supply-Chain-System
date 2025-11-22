import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final _firestoreService = FirestoreService();

  Future<void> _markAsReceived(String docId, List items) async {
    await _firestoreService.updateSupplierReceipt(docId, {'status': 'received'});
    for (var item in items) {
      final ingredientId = item['ingredientId'];
      final quantity = item['quantity'] ?? 0;
      await _firestoreService.incrementIngredientInventory(ingredientId, quantity);
    }
  }

  // Updated to handle retrying payments for existing receipts
  Future<void> _handlePayNow(String receiptId, Map<String, dynamic> purchaseData) async {
    final receiptData = {
      'supplierName': purchaseData['supplierName'],
      'supplierId': purchaseData['supplierId'],
      'supplierEmail': purchaseData['supplierEmail'],
      'items': purchaseData['items'],
      'total': purchaseData['total'],
      'date': purchaseData['date'],
      'status': 'pending',
    };

    final result = await _firestoreService.processPurchase(
      receiptData,
      isPayNow: true,
      existingReceiptId: receiptId, // Pass the existing ID
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'An unknown error occurred.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supplier Purchases')),
      body: StreamBuilder(
        stream: _firestoreService.getSupplierReceipts(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No purchases found.'));
          }
          final docs = snapshot.data!.docs;
          final purchases = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'data': data,
            };
          }).toList();

          // Sort by date descending
          purchases.sort((a, b) {
            final dateA = DateTime.tryParse(a['data']['date'] ?? '') ?? DateTime(1970);
            final dateB = DateTime.tryParse(b['data']['date'] ?? '') ?? DateTime(1970);
            return dateB.compareTo(dateA);
          });

          return ListView.builder(
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final purchase = purchases[index];
              final data = purchase['data'] as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';
              final paymentStatus = data['paymentStatus'] ?? 'unpaid';
              final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

              Widget trailingWidget;
              if (status == 'received') {
                trailingWidget = const Icon(Icons.check_circle, color: Colors.green, semanticLabel: 'Received');
              } else if (paymentStatus == 'paid') {
                trailingWidget = ElevatedButton(
                  onPressed: () => _markAsReceived(purchase['id'], items),
                  child: const Text('Mark as Received'),
                );
              } else { // unpaid or pending_payment
                trailingWidget = ElevatedButton(
                  onPressed: () => _handlePayNow(purchase['id'], data),
                  child: const Text('Pay Now'),
                );
              }

              return Card(
                child: ListTile(
                  title: Text('Supplier: ${data['supplierName'] ?? 'Unknown'}'),
                  subtitle: Text('Total: KSh${data['total'].toStringAsFixed(2)}\nDate: ${data['date']}\nStatus: $status | Payment: $paymentStatus'),
                  isThreeLine: true,
                  trailing: trailingWidget,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Purchase Details'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: items.map((item) {
                            final name = item['ingredientName'] ?? 'Unknown';
                            final qty = item['quantity']?.toString() ?? '0';
                            final cost = item['unitCost']?.toStringAsFixed(2) ?? '0.00';
                            return ListTile(
                              title: Text(name),
                              subtitle: Text('Qty: $qty | Unit Cost: KSh$cost'),
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
