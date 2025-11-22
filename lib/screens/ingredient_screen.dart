import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../services/firestore_service.dart';
import '../models/supplier.dart';

class IngredientScreen extends StatefulWidget {
  const IngredientScreen({super.key});

  @override
  State<IngredientScreen> createState() => _IngredientScreenState();
}

class _IngredientScreenState extends State<IngredientScreen> {
  final _firestoreService = FirestoreService();

  // Dialog for adding or editing an ingredient
  void _showIngredientDialog({Ingredient? ingredient, String? docId}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: ingredient?.name ?? '');
    final inventoryController = TextEditingController(text: ingredient?.inventoryLevel.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ingredient == null ? 'Add Ingredient' : 'Edit Ingredient'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                ),
                TextFormField(
                  controller: inventoryController,
                  decoration: const InputDecoration(labelText: 'Inventory Level'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Enter inventory' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final ingredientData = {
                  'name': nameController.text,
                  'inventoryLevel': int.tryParse(inventoryController.text) ?? 0,
                };
                if (docId == null) {
                  await _firestoreService.addIngredient(ingredientData);
                } else {
                  await _firestoreService.updateIngredient(docId, ingredientData);
                }
                if (mounted) Navigator.pop(context);
              }
            },
            child: Text(ingredient == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  // Main purchase flow starts here
  void _showPurchaseDialog(Ingredient ingredient) async {
    final suppliers = await _firestoreService.getSuppliersForIngredient(ingredient.id);
    if (!mounted) return;

    if (suppliers.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Suppliers'),
          content: Text('No suppliers found for ${ingredient.name}.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buy ${ingredient.name} from:'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              final price = supplier.ingredientPrices[ingredient.id] ?? 0.0;
              return ListTile(
                title: Text(supplier.name),
                subtitle: Text('Price: KSh${price.toStringAsFixed(2)}'),
                onTap: () {
                  Navigator.pop(context); // Close supplier list
                  _showQuantityDialog(ingredient, supplier, price);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Dialog to enter quantity and choose payment option
  void _showQuantityDialog(Ingredient ingredient, Supplier supplier, double price) {
    final quantityController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase from ${supplier.name}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: quantityController,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty || (int.tryParse(v) ?? 0) <= 0) {
                return 'Enter a valid quantity';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final qty = int.parse(quantityController.text);
                Navigator.pop(context); // Close quantity dialog
                _handlePurchase(ingredient, supplier, price, qty, isPayNow: false);
              }
            },
            child: const Text('Pay Later'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final qty = int.parse(quantityController.text);
                Navigator.pop(context); // Close quantity dialog
                _handlePurchase(ingredient, supplier, price, qty, isPayNow: true);
              }
            },
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  // Unified handler for both "Pay Now" and "Pay Later"
  Future<void> _handlePurchase(Ingredient ingredient, Supplier supplier, double price, int qty, {required bool isPayNow}) async {
    final total = price * qty;
    final receiptData = _createReceiptData(ingredient, supplier, price, qty, total);

    final result = await _firestoreService.processPurchase(receiptData, isPayNow: isPayNow);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'An unknown error occurred.')),
      );
    }
  }

  // Helper to create the base receipt data map
  Map<String, dynamic> _createReceiptData(Ingredient ingredient, Supplier supplier, double price, int qty, double total) {
    return {
      'supplierName': supplier.name,
      'supplierId': supplier.id,
      'supplierEmail': supplier.email,
      'items': [
        {
          'ingredientId': ingredient.id,
          'ingredientName': ingredient.name,
          'quantity': qty,
          'unitCost': price,
          'totalCost': total,
        }
      ],
      'total': total,
      'date': DateTime.now().toIso8601String(),
      'status': 'pending', // Status of the order (e.g., pending, delivered)
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingredients')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getIngredients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No ingredients found.'));
          }
          final ingredients = snapshot.data!.docs.map((doc) {
            return Ingredient.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return ListView.builder(
            itemCount: ingredients.length,
            itemBuilder: (context, index) {
              final ingredient = ingredients[index];
              final isLow = ingredient.inventoryLevel < 5;
              return Card(
                child: ListTile(
                  title: Text(ingredient.name),
                  subtitle: Text('Inventory: ${ingredient.inventoryLevel}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLow) const Icon(Icons.warning, color: Colors.red),
                      IconButton(
                        icon: const Icon(Icons.shopping_cart),
                        tooltip: 'Buy from Supplier',
                        onPressed: () => _showPurchaseDialog(ingredient),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showIngredientDialog(ingredient: ingredient, docId: ingredient.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await _firestoreService.deleteIngredient(ingredient.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ingredient deleted.')),
                            );
                          }
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
        onPressed: () => _showIngredientDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
