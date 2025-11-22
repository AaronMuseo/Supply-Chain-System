import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/firestore_service.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _firestoreService = FirestoreService();
  final Map<MenuItem, int> _cart = {};
  double _total = 0.0;

  void _addToCart(MenuItem item) {
    setState(() {
      _cart[item] = (_cart[item] ?? 0) + 1;
      _calculateTotal();
    });
  }

  void _removeFromCart(MenuItem item) {
    setState(() {
      if (_cart[item] != null && _cart[item]! > 1) {
        _cart[item] = _cart[item]! - 1;
      } else {
        _cart.remove(item);
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _total = _cart.entries.fold(0.0, (sum, entry) => sum + entry.key.price * entry.value);
  }

  Future<List<MenuItem>> _fetchMenuItems() async {
    final snapshot = await _firestoreService.getMenuItems().first;
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MenuItem.fromMap(data, doc.id);
    }).toList();
  }

  void _checkout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
      }
      return;
    }

    final now = DateTime.now();
    final receiptItems = _cart.entries.map((e) => {
      'menuItemId': e.key.id,
      'productName': e.key.name,
      'quantity': e.value,
      'unitPrice': e.key.price,
      'totalPrice': e.key.price * e.value,
    }).toList();

    final receiptData = {
      'userId': user.uid,
      'items': receiptItems,
      'total': _total,
      'date': now.toIso8601String(),
      'status': 'completed',
    };

    try {
      // Save the customer receipt
      await _firestoreService.addCustomerReceipt(receiptData);

      // Decrement inventory for each ingredient used
      for (var cartEntry in _cart.entries) {
        final menuItem = cartEntry.key;
        final quantitySold = cartEntry.value;
        for (var menuIngredient in menuItem.ingredients) {
          final totalToDecrement = menuIngredient.quantity * quantitySold;
          await _firestoreService.decrementIngredientInventory(
            menuIngredient.ingredientId,
            totalToDecrement,
          );
        }
      }

      setState(() {
        _cart.clear();
        _total = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order recorded and inventory updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Customer Order')),
      body: FutureBuilder<List<MenuItem>>(
        future: _fetchMenuItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading menu items: ${snapshot.error}'));
          }
          final menuItems = snapshot.data ?? [];
          if (menuItems.isEmpty) {
            return const Center(
              child: Text('No menu items found. Please add items in the Menu screen.'),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text('Price: KSh${item.price.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _cart.containsKey(item) ? () => _removeFromCart(item) : null,
                            ),
                            Text(_cart[item]?.toString() ?? '0'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _addToCart(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text('KSh${_total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  onPressed: _cart.isEmpty ? null : _checkout,
                  child: const Text('Record Order'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
