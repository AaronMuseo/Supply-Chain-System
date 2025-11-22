import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/supplier.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Centralized method to handle the entire purchase process
  Future<Map<String, dynamic>> processPurchase(
    Map<String, dynamic> receiptData, {
    required bool isPayNow,
    String? existingReceiptId,
  }) async {
    if (isPayNow) {
      String receiptId;
      if (existingReceiptId != null) {
        // If we are retrying a payment, update the existing receipt
        receiptId = existingReceiptId;
        await updateSupplierReceipt(receiptId, {'paymentStatus': 'pending_payment'});
      } else {
        // Otherwise, create a new receipt
        final pendingReceipt = {
          ...receiptData,
          'paymentStatus': 'pending_payment',
          'transactionId': '',
        };
        final docRef = await addSupplierReceipt(pendingReceipt);
        receiptId = docRef.id;
      }

      // Pass the correct receipt ID to the backend
      final response = await http.post(
        Uri.parse('http://localhost:8000/stripe_backend.php?checkout=1'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          ...receiptData,
          'receipt_id': receiptId,
        }),
      );

      if (response.statusCode == 200) {
        final paymentResult = jsonDecode(response.body) as Map<String, dynamic>;
        if (paymentResult['success'] == true && paymentResult['checkoutUrl'] != null) {
          final Uri url = Uri.parse(paymentResult['checkoutUrl']);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            return {'success': true, 'message': 'Redirecting to Stripe for payment...'};
          } else {
            return {'success': false, 'message': 'Could not launch Stripe URL.'};
          }
        } else {
          return {'success': false, 'message': paymentResult['error'] ?? 'Failed to create Stripe session.'};
        }
      } else {
        return {'success': false, 'message': 'Backend error during payment.'};
      }
    } else {
      // Pay Later Logic
      final unpaidReceipt = {
        ...receiptData,
        'paymentStatus': 'unpaid',
        'transactionId': '',
      };
      await addSupplierReceipt(unpaidReceipt);
      
      final emailResult = await sendPurchaseEmail(unpaidReceipt);
      if (emailResult['success']) {
        return {'success': true, 'message': 'Order placed for later payment. Email sent.'};
      } else {
        return {'success': false, 'message': 'Order saved, but failed to send email: ${emailResult['message']}'};
      }
    }
  }

  // Supplier CRUD
  Future<void> addSupplier(Map<String, dynamic> data) async {
    await _db.collection('suppliers').add(data);
  }
  Future<void> updateSupplier(String id, Map<String, dynamic> data) async {
    await _db.collection('suppliers').doc(id).update(data);
  }
  Future<void> deleteSupplier(String id) async {
    await _db.collection('suppliers').doc(id).delete();
  }
  Stream<QuerySnapshot> getSuppliers() {
    return _db.collection('suppliers').snapshots().map((snapshot) {
      for (var doc in snapshot.docs) {
        log('RAW_SUPPLIER_DATA for ${doc.id}: ${doc.data()}');
      }
      return snapshot;
    });
  }

  Future<List<Supplier>> getSuppliersForIngredient(String ingredientId) async {
    final snapshot = await _db
        .collection('suppliers')
        .where('ingredientsSupplied', arrayContains: ingredientId)
        .get();
    return snapshot.docs.map((doc) {
      return Supplier.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  // Menu Item CRUD
  Future<void> addMenuItem(Map<String, dynamic> data) async {
    await _db.collection('menu_items').add(data);
  }
  Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    await _db.collection('menu_items').doc(id).update(data);
  }
  Future<void> deleteMenuItem(String id) async {
    await _db.collection('menu_items').doc(id).delete();
  }
  Stream<QuerySnapshot> getMenuItems() {
    return _db.collection('menu_items').snapshots();
  }

  // User CRUD
  Future<void> addUser(Map<String, dynamic> data) async {
    await _db.collection('users').add(data);
  }
  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await _db.collection('users').doc(id).update(data);
  }
  Future<void> deleteUser(String id) async {
    await _db.collection('users').doc(id).delete();
  }
  Stream<QuerySnapshot> getUsers() {
    return _db.collection('users').snapshots();
  }

  // Supplier Receipt CRUD
  Future<DocumentReference> addSupplierReceipt(Map<String, dynamic> data) async {
    return await _db.collection('supplier_receipts').add(data);
  }
  Future<void> updateSupplierReceipt(String id, Map<String, dynamic> data) async {
    await _db.collection('supplier_receipts').doc(id).update(data);
  }
  Future<void> deleteSupplierReceipt(String id) async {
    await _db.collection('supplier_receipts').doc(id).delete();
  }
  Stream<QuerySnapshot> getSupplierReceipts() {
    return _db.collection('supplier_receipts').snapshots();
  }

  // Customer Receipt CRUD
  Future<void> addCustomerReceipt(Map<String, dynamic> data) async {
    await _db.collection('customer_receipts').add(data);
  }
  Future<void> updateCustomerReceipt(String id, Map<String, dynamic> data) async {
    await _db.collection('customer_receipts').doc(id).update(data);
  }
  Future<void> deleteCustomerReceipt(String id) async {
    await _db.collection('customer_receipts').doc(id).delete();
  }
  Stream<QuerySnapshot> getCustomerReceipts() {
    return _db.collection('customer_receipts').snapshots();
  }

  // Ingredient CRUD
  Future<void> addIngredient(Map<String, dynamic> data) async {
    await _db.collection('ingredients').add(data);
  }
  Future<void> updateIngredient(String id, Map<String, dynamic> data) async {
    await _db.collection('ingredients').doc(id).update(data);
  }
  Future<void> deleteIngredient(String id) async {
    await _db.collection('ingredients').doc(id).delete();
  }
  Stream<QuerySnapshot> getIngredients() {
    return _db.collection('ingredients').snapshots();
  }

  Future<void> incrementIngredientInventory(String ingredientId, int quantity) async {
    await _db.collection('ingredients').doc(ingredientId).update({'inventoryLevel': FieldValue.increment(quantity)});
  }

  Future<void> decrementIngredientInventory(String ingredientId, int quantity) async {
    await _db.collection('ingredients').doc(ingredientId).update({'inventoryLevel': FieldValue.increment(-quantity)});
  }

  Future<Map<String, dynamic>> sendPurchaseEmail(Map<String, dynamic> emailData) async {
    log('SENDING_EMAIL_DATA: ${jsonEncode(emailData)}'); // Diagnostic logging
    final url = 'http://localhost:8000/send_purchase_email.php';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(emailData),
    );
    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {'success': false, 'message': 'Invalid response from email backend.'};
      }
    } else {
      return {'success': false, 'message': 'Failed to send email.'};
    }
  }
}
