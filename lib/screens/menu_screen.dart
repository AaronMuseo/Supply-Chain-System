import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/menu_item.dart';
import '../models/ingredient.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _firestoreService = FirestoreService();

  void _showMenuItemDialog({MenuItem? menuItem, List<Ingredient>? ingredients, String? docId}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: menuItem?.name ?? '');
    final priceController = TextEditingController(text: menuItem?.price.toString() ?? '');
    List<MenuIngredient> selectedIngredients = List<MenuIngredient>.from(menuItem?.ingredients ?? []);

    // Only allow ingredients to be selectable
    final ingredientList = ingredients ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(menuItem == null ? 'Add Menu Item' : 'Edit Menu Item'),
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
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Enter price' : null,
                ),
                const SizedBox(height: 16),
                const Text('Ingredients', style: TextStyle(fontWeight: FontWeight.bold)),
                ...ingredientList.map((ingredient) {
                  final selected = selectedIngredients.firstWhere(
                    (i) => i.ingredientId == ingredient.id,
                    orElse: () => MenuIngredient(ingredientId: ingredient.id, ingredientName: ingredient.name, quantity: 0),
                  );
                  return Row(
                    children: [
                      Expanded(child: Text(ingredient.name)),
                      SizedBox(
                        width: 60,
                        child: TextFormField(
                          initialValue: selected.quantity > 0 ? selected.quantity.toString() : '',
                          decoration: const InputDecoration(labelText: 'Qty'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            final qty = int.tryParse(val) ?? 0;
                            setState(() {
                              final idx = selectedIngredients.indexWhere((i) => i.ingredientId == ingredient.id);
                              if (idx >= 0) {
                                selectedIngredients[idx] = MenuIngredient(ingredientId: ingredient.id, ingredientName: ingredient.name, quantity: qty);
                              } else {
                                selectedIngredients.add(MenuIngredient(ingredientId: ingredient.id, ingredientName: ingredient.name, quantity: qty));
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final ingredients = selectedIngredients.where((i) => i.quantity > 0).toList();
                final menuItemData = {
                  'name': nameController.text,
                  'price': double.tryParse(priceController.text) ?? 0,
                  'ingredients': ingredients.map((i) => i.toMap()).toList(),
                };
                if (menuItem == null) {
                  await _firestoreService.addMenuItem(menuItemData);
                } else {
                  await _firestoreService.updateMenuItem(docId!, menuItemData);
                }
                Navigator.pop(context);
              }
            },
            child: Text(menuItem == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<List<Ingredient>> _fetchIngredients() async {
    final snapshot = await _firestoreService.getIngredients().first;
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Ingredient.fromMap(data, doc.id);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: StreamBuilder(
        stream: _firestoreService.getMenuItems(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No menu items found.'));
          }
          final docs = snapshot.data!.docs;
          final menuItems = docs.map<MenuItem>((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final rawIngredients = data['ingredients'] as List<dynamic>? ?? [];
            final parsedIngredients = rawIngredients.isNotEmpty && rawIngredients.first is Map<String, dynamic>
              ? rawIngredients.map((i) => MenuIngredient.fromMap(i as Map<String, dynamic>)).toList()
              : rawIngredients.map((i) => MenuIngredient(ingredientId: i.toString(), ingredientName: i.toString(), quantity: 1)).toList();
            return MenuItem(
              id: doc.id,
              name: data['name'] ?? '',
              price: (data['price'] is int)
    ? (data['price'] as int).toDouble()
    : (data['price'] is double)
        ? data['price']
        : double.tryParse(data['price'].toString()) ?? 0.0,
              ingredients: parsedIngredients,
            );
          }).toList();
          return ListView.builder(
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final menuItem = menuItems[index];
              return Card(
                child: ListTile(
                  title: Text(menuItem.name),
                  subtitle: Text('Price: ${menuItem.price}\nIngredients: ${menuItem.ingredients.map((i) => i.ingredientName + ' x' + i.quantity.toString()).join(', ')}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final ingredients = await _fetchIngredients();
                          _showMenuItemDialog(menuItem: menuItem, ingredients: ingredients, docId: menuItem.id);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await _firestoreService.deleteMenuItem(menuItem.id);
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
      floatingActionButton: FutureBuilder<List<Ingredient>>(
        future: _fetchIngredients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox();
          }
          if (snapshot.hasError) {
            return FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.grey,
              tooltip: 'Error loading ingredients',
              child: const Icon(Icons.error),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.grey,
              tooltip: 'Add ingredients first',
              child: const Icon(Icons.add),
            );
          }
          final ingredients = snapshot.data!;
          return FloatingActionButton(
            onPressed: () => _showMenuItemDialog(ingredients: ingredients),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
