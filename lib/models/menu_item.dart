import 'package:flutter/foundation.dart';

class MenuItem {
  final String id;
  final String name;
  final double price;
  final List<MenuIngredient> ingredients; // List of ingredient IDs and quantities

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.ingredients,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map, String id) {
    try {
      return MenuItem(
        id: id,
        name: map['name'] ?? '',
        price: (map['price'] is int) ? (map['price'] as int).toDouble() : (map['price'] ?? 0.0),
        ingredients: (map['ingredients'] as List<dynamic>?)?.map((e) => MenuIngredient.fromMap(e)).toList() ?? [],
      );
    } catch (e) {
      debugPrint('MenuItem.fromMap error: $e, map: $map');
      return MenuItem(id: id, name: '', price: 0.0, ingredients: []);
    }
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'ingredients': ingredients.map((e) => e.toMap()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class MenuIngredient {
  final String ingredientId;
  final String ingredientName;
  final int quantity; // Quantity of ingredient used in this menu item

  MenuIngredient({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
  });

  factory MenuIngredient.fromMap(Map<String, dynamic> map) {
    try {
      return MenuIngredient(
        ingredientId: map['ingredientId'] ?? '',
        ingredientName: map['ingredientName'] ?? '',
        quantity: map['quantity'] ?? 0,
      );
    } catch (e) {
      debugPrint('MenuIngredient.fromMap error: $e, map: $map');
      return MenuIngredient(ingredientId: '', ingredientName: '', quantity: 0);
    }
  }

  Map<String, dynamic> toMap() => {
    'ingredientId': ingredientId,
    'ingredientName': ingredientName,
    'quantity': quantity,
  };
}
