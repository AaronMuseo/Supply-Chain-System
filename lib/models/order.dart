import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    productId: map['productId'],
    productName: map['productName'],
    quantity: map['quantity'],
    unitPrice: (map['unitPrice'] is int) ? (map['unitPrice'] as int).toDouble() : (map['unitPrice'] ?? 0.0),
    totalPrice: (map['totalPrice'] is int) ? (map['totalPrice'] as int).toDouble() : (map['totalPrice'] ?? 0.0),
  );

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'totalPrice': totalPrice,
  };
}

class AppOrder {
  final String id;
  final String customerId;
  final List<OrderItem> items;
  final DateTime orderDate;
  final String status; // e.g., 'pending', 'received', 'prepared', 'served'
  final double totalPrice;

  AppOrder({
    required this.id,
    required this.customerId,
    required this.items,
    required this.orderDate,
    required this.status,
    required this.totalPrice,
  });

  factory AppOrder.fromMap(Map<String, dynamic> map, String id) => AppOrder(
    id: id,
    customerId: map['customerId'] ?? '',
    items: (map['items'] as List<dynamic>? ?? []).map((item) => OrderItem.fromMap(item as Map<String, dynamic>)).toList(),
    orderDate: (map['orderDate'] is Timestamp)
        ? (map['orderDate'] as Timestamp).toDate()
        : DateTime.tryParse(map['orderDate'].toString()) ?? DateTime.now(),
    status: map['status'] ?? '',
    totalPrice: (map['totalPrice'] is int) ? (map['totalPrice'] as int).toDouble() : (map['totalPrice'] ?? 0.0),
  );

  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    'items': items.map((item) => item.toMap()).toList(),
    'orderDate': orderDate,
    'status': status,
    'totalPrice': totalPrice,
  };
}
