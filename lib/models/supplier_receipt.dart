class SupplierReceipt {
  final String id;
  final String supplierId;
  final String supplierName;
  final List<ReceiptItem> items;
  final double total;
  final String date;
  final String status; // 'pending', 'received'

  SupplierReceipt({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.total,
    required this.date,
    required this.status,
  });

  factory SupplierReceipt.fromMap(Map<String, dynamic> map, String id) => SupplierReceipt(
    id: id,
    supplierId: map['supplierId'] ?? '',
    supplierName: map['supplierName'] ?? '',
    items: (map['items'] as List<dynamic>? ?? []).map((item) => ReceiptItem.fromMap(item)).toList(),
    total: (map['total'] is int) ? (map['total'] as int).toDouble() : (map['total'] ?? 0.0),
    date: map['date'] ?? '',
    status: map['status'] ?? 'pending',
  );

  Map<String, dynamic> toMap() => {
    'supplierId': supplierId,
    'supplierName': supplierName,
    'items': items.map((item) => item.toMap()).toList(),
    'total': total,
    'date': date,
    'status': status,
  };
}

class ReceiptItem {
  final String ingredientId;
  final String ingredientName;
  final int quantity;
  final double unitCost;
  final double totalCost;

  ReceiptItem({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
  });

  factory ReceiptItem.fromMap(Map<String, dynamic> map) => ReceiptItem(
    ingredientId: map['ingredientId'] ?? '',
    ingredientName: map['ingredientName'] ?? '',
    quantity: map['quantity'] ?? 0,
    unitCost: (map['unitCost'] is int) ? (map['unitCost'] as int).toDouble() : (map['unitCost'] ?? 0.0),
    totalCost: (map['totalCost'] is int) ? (map['totalCost'] as int).toDouble() : (map['totalCost'] ?? 0.0),
  );

  Map<String, dynamic> toMap() => {
    'ingredientId': ingredientId,
    'ingredientName': ingredientName,
    'quantity': quantity,
    'unitCost': unitCost,
    'totalCost': totalCost,
  };
}

