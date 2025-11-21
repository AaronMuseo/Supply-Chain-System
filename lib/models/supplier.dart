import 'dart:developer';

class Supplier {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String address;
  final String email;
  final List<String> ingredientsSupplied;
  final Map<String, double> ingredientPrices;
  final String bankAccount;

  Supplier({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.address,
    required this.email,
    required this.ingredientsSupplied,
    required this.ingredientPrices,
    required this.bankAccount,
  });

  factory Supplier.fromMap(Map<String, dynamic> map, String id) {
    List<String> ingredients = [];
    if (map['ingredientsSupplied'] is List) {
      ingredients = List<String>.from(map['ingredientsSupplied']);
    } else if (map['ingredientsSupplied'] != null) {
      log('Malformed ingredientsSupplied for supplier $id: ${map['ingredientsSupplied']}');
    }

    Map<String, double> prices = {};
    if (map['ingredientPrices'] is Map) {
      prices = Map<String, dynamic>.from(map['ingredientPrices']).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    } else if (map['ingredientPrices'] != null) {
      log('Malformed ingredientPrices for supplier $id: ${map['ingredientPrices']}');
    }

    return Supplier(
      id: id,
      name: map['name'] ?? '',
      contactPerson: map['contactPerson'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      email: map['email'] ?? '',
      ingredientsSupplied: ingredients,
      ingredientPrices: prices,
      bankAccount: map['bankAccount'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'contactPerson': contactPerson,
    'phone': phone,
    'address': address,
    'email': email,
    'ingredientsSupplied': ingredientsSupplied,
    'ingredientPrices': ingredientPrices,
    'bankAccount': bankAccount,
  };
}
