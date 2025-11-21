class CustomerReceipt {
  final String id;
  final String userId;
  final List<ReceiptItem> items;
  final double total;
  final String date;
  final String status;

  CustomerReceipt({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.date,
    required this.status,
  });

  factory CustomerReceipt.fromMap(Map<String, dynamic> map, String id) {
    return CustomerReceipt(
      id: id,
      userId: map['userId'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => ReceiptItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] ?? '',
      status: map['status'] ?? 'unknown',
    );
  }
}

class ReceiptItem {
  final String menuItemId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  ReceiptItem({
    required this.menuItemId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      menuItemId: map['menuItemId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
