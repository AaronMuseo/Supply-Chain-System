import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/supplier.dart';
import '../models/ingredient.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  final _firestoreService = FirestoreService();

  // Dialog to add or edit a supplier's details and their ingredient pricing.
  void _showSupplierDialog({Supplier? supplier, String? docId}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final contactNameController = TextEditingController(text: supplier?.contactPerson ?? '');
    final contactPhoneController = TextEditingController(text: supplier?.phone ?? '');
    final addressController = TextEditingController(text: supplier?.address ?? '');
    final bankAccountController = TextEditingController(text: supplier?.bankAccount ?? '');
    final emailController = TextEditingController(text: supplier?.email ?? '');
    Map<String, double> ingredientPrices = Map<String, double>.from(supplier?.ingredientPrices ?? {});
    
    final ingredientSnapshot = await _firestoreService.getIngredients().first;
    final allIngredients = ingredientSnapshot.docs.map<Ingredient>((doc) {
      return Ingredient.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
    
    List<String> selectedIngredientIds = List<String>.from(supplier?.ingredientsSupplied ?? []);
    String searchQuery = '';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final filteredIngredients = allIngredients
              .where((i) => i.name.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();
          
          return AlertDialog(
            title: Text(supplier == null ? 'Add Supplier' : 'Edit Supplier'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Supplier Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter supplier name' : null,
                    ),
                    TextFormField(
                      controller: contactNameController,
                      decoration: const InputDecoration(labelText: 'Contact Name'),
                    ),
                    TextFormField(
                      controller: contactPhoneController,
                      decoration: const InputDecoration(labelText: 'Contact Phone'),
                    ),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    TextFormField(
                      controller: bankAccountController,
                      decoration: const InputDecoration(labelText: 'Bank Account'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter bank account' : null,
                    ),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Supplier Email'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter supplier email' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Supplied Ingredients & Prices', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Search Ingredients'),
                      onChanged: (query) => setState(() => searchQuery = query),
                    ),
                    SizedBox(
                      height: 300, // Constrain height for the list
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredIngredients.length,
                        itemBuilder: (context, index) {
                          final ingredient = filteredIngredients[index];
                          return Row(
                            children: [
                              Expanded(
                                child: CheckboxListTile(
                                  title: Text(ingredient.name),
                                  value: selectedIngredientIds.contains(ingredient.id),
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        selectedIngredientIds.add(ingredient.id);
                                      } else {
                                        selectedIngredientIds.remove(ingredient.id);
                                        ingredientPrices.remove(ingredient.id); // Also remove price
                                      }
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: TextFormField(
                                  enabled: selectedIngredientIds.contains(ingredient.id),
                                  decoration: const InputDecoration(labelText: 'Price'),
                                  keyboardType: TextInputType.number,
                                  initialValue: ingredientPrices[ingredient.id]?.toString() ?? '',
                                  onChanged: (val) {
                                    ingredientPrices[ingredient.id] = double.tryParse(val) ?? 0.0;
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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
                    final supplierData = {
                      'name': nameController.text,
                      'contactPerson': contactNameController.text,
                      'phone': contactPhoneController.text,
                      'address': addressController.text,
                      'email': emailController.text,
                      'ingredientsSupplied': selectedIngredientIds,
                      'ingredientPrices': ingredientPrices,
                      'bankAccount': bankAccountController.text,
                    };
                    if (docId == null) {
                      await _firestoreService.addSupplier(supplierData);
                    } else {
                      await _firestoreService.updateSupplier(docId, supplierData);
                    }
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: Text(supplier == null ? 'Add' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  // New purchase sheet for supplier-centric workflow
  void _showPurchaseSheet(Supplier supplier) async {
    final ingredientSnapshot = await _firestoreService.getIngredients().first;
    final allIngredients = ingredientSnapshot.docs.map((doc) {
      return Ingredient.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();

    // Filter to only show ingredients this supplier provides
    final availableIngredients = allIngredients
        .where((ing) => supplier.ingredientsSupplied.contains(ing.id))
        .toList();

    if (!mounted) return;

    Map<Ingredient, int> cart = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          double calculateTotal() {
            if (cart.isEmpty) return 0.0;
            return cart.entries
                .map((entry) => (supplier.ingredientPrices[entry.key.id] ?? 0.0) * entry.value)
                .reduce((a, b) => a + b);
          }

          void updateCart(Ingredient ingredient, int quantity) {
            setState(() {
              if (quantity > 0) {
                cart[ingredient] = quantity;
              } else {
                cart.remove(ingredient);
              }
            });
          }

          void checkout({required bool isPayNow}) async {
            if (cart.isEmpty) return;

            final total = calculateTotal();
            final items = cart.entries.map((e) => {
              'ingredientId': e.key.id,
              'ingredientName': e.key.name,
              'quantity': e.value,
              'unitCost': supplier.ingredientPrices[e.key.id] ?? 0.0,
              'totalCost': (supplier.ingredientPrices[e.key.id] ?? 0.0) * e.value,
            }).toList();

            final receiptData = {
              'supplierName': supplier.name,
              'supplierId': supplier.id,
              'supplierEmail': supplier.email,
              'items': items,
              'total': total,
              'date': DateTime.now().toIso8601String(),
              'status': 'pending',
            };

            Navigator.pop(context); // Close the purchase sheet
            final result = await _firestoreService.processPurchase(receiptData, isPayNow: isPayNow);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message'] ?? 'An unknown error occurred.')),
              );
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Create Order for ${supplier.name}', style: Theme.of(context).textTheme.headlineSmall),
                Expanded(
                  child: ListView.builder(
                    itemCount: availableIngredients.length,
                    itemBuilder: (context, idx) {
                      final ingredient = availableIngredients[idx];
                      final price = supplier.ingredientPrices[ingredient.id] ?? 0.0;
                      return ListTile(
                        title: Text(ingredient.name),
                        subtitle: Text('Price: KSh${price.toStringAsFixed(2)}'),
                        trailing: SizedBox(
                          width: 120,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => updateCart(ingredient, (cart[ingredient] ?? 1) - 1),
                              ),
                              Expanded(
                                child: Text(
                                  (cart[ingredient] ?? 0).toString(),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => updateCart(ingredient, (cart[ingredient] ?? 0) + 1),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text('KSh${calculateTotal().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: cart.isEmpty ? null : () => checkout(isPayNow: false),
                        child: const Text('Pay Later'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: cart.isEmpty ? null : () => checkout(isPayNow: true),
                        child: const Text('Pay Now'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Suppliers')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getSuppliers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No suppliers found.'));
          }
          
          final suppliers = snapshot.data!.docs.map((doc) {
            return Supplier.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return ListView.builder(
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              return Card(
                child: ListTile(
                  title: Text(supplier.name),
                  subtitle: Text('Contact: ${supplier.contactPerson}\nPhone: ${supplier.phone}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart),
                        tooltip: 'Create Order',
                        onPressed: () => _showPurchaseSheet(supplier),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit Supplier',
                        onPressed: () => _showSupplierDialog(supplier: supplier, docId: supplier.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Delete Supplier',
                        onPressed: () async {
                          await _firestoreService.deleteSupplier(supplier.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Supplier deleted.')),
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
        onPressed: () => _showSupplierDialog(),
        tooltip: 'Add New Supplier',
        child: const Icon(Icons.add),
      ),
    );
  }
}
