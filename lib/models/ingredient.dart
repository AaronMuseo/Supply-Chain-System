class Ingredient {
  final String id;
  final String name;
  final int inventoryLevel;

  Ingredient({
    required this.id,
    required this.name,
    required this.inventoryLevel,
  });

  factory Ingredient.fromMap(Map<String, dynamic> map, String id) {
    return Ingredient(
      id: id,
      name: map['name'] ?? '',
      inventoryLevel: map['inventoryLevel'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'inventoryLevel': inventoryLevel,
  };
}
