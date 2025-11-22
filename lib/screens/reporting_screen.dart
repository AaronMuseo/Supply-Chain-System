import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';
import '../models/customer_receipt.dart';
import '../models/supplier_receipt.dart';
import '../models/ingredient.dart';

class ReportingScreen extends StatefulWidget {
  const ReportingScreen({super.key});

  @override
  State<ReportingScreen> createState() => _ReportingScreenState();
}

class _ReportingScreenState extends State<ReportingScreen> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reporting & Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FinancialSummary(firestoreService: _firestoreService),
            const Divider(),
            _MonthlySalesChart(firestoreService: _firestoreService),
            const Divider(),
            _TopMenuItemsBarChart(firestoreService: _firestoreService),
            const Divider(),
            _TopSuppliers(firestoreService: _firestoreService),
            const Divider(),
            _InventoryAlerts(firestoreService: _firestoreService),
          ],
        ),
      ),
    );
  }
}

class _FinancialSummary extends StatelessWidget {
  final FirestoreService firestoreService;
  const _FinancialSummary({required this.firestoreService});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        firestoreService.getCustomerReceipts().first,
        firestoreService.getSupplierReceipts().first,
      ]),
      builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final customerReceipts = snapshot.data![0].docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return CustomerReceipt.fromMap(data, doc.id);
        }).toList();
        final supplierReceipts = snapshot.data![1].docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return SupplierReceipt.fromMap(data, doc.id);
        }).toList();
        final totalSales = customerReceipts.fold(0.0, (sum, r) => sum + r.total);
        final totalPurchases = supplierReceipts.fold(0.0, (sum, r) => sum + r.total);
        final netProfit = totalSales - totalPurchases;
        return Card(
          margin: const EdgeInsets.all(12),
          child: ListTile(
            title: const Text('Financial Summary'),
            subtitle: Text('Total Sales: KSh${totalSales.toStringAsFixed(2)}\nTotal Purchases: KSh${totalPurchases.toStringAsFixed(2)}\nNet Profit: KSh${netProfit.toStringAsFixed(2)}'),
          ),
        );
      },
    );
  }
}

class _MonthlySalesChart extends StatelessWidget {
  final FirestoreService firestoreService;
  const _MonthlySalesChart({required this.firestoreService});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: firestoreService.getCustomerReceipts().first,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final receipts = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return CustomerReceipt.fromMap(data, doc.id);
        }).toList();
        // Aggregate monthly sales
        final now = DateTime.now();
        final salesByMonth = <String, double>{};
        for (var i = 0; i < 12; i++) {
          final month = DateTime(now.year, now.month - i, 1);
          final key = "${month.year}-${month.month.toString().padLeft(2, '0')}";
          salesByMonth[key] = 0.0;
        }
        for (var receipt in receipts) {
          final date = DateTime.tryParse(receipt.date);
          if (date != null) {
            final key = "${date.year}-${date.month.toString().padLeft(2, '0')}";
            if (salesByMonth.containsKey(key)) {
              salesByMonth[key] = salesByMonth[key]! + receipt.total;
            }
          }
        }
        final months = salesByMonth.keys.toList().reversed.toList();
        final sales = months.map((m) => salesByMonth[m] ?? 0.0).toList();
        return Card(
          margin: const EdgeInsets.all(12),
          child: Column(
            children: [
              const ListTile(title: Text('Monthly Sales (Last 12 Months)')),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= months.length) return Container();
                            return Text(months[idx].substring(5));
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(sales.length, (i) => FlSpot(i.toDouble(), sales[i])),
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopMenuItemsBarChart extends StatelessWidget {
  final FirestoreService firestoreService;
  const _TopMenuItemsBarChart({required this.firestoreService});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: firestoreService.getCustomerReceipts().first,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final receipts = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return CustomerReceipt.fromMap(data, doc.id);
        }).toList();
        final itemSales = <String, int>{};
        for (var receipt in receipts) {
          for (var item in receipt.items) {
            itemSales[item.productName] = (itemSales[item.productName] ?? 0) + item.quantity;
          }
        }
        final topItems = itemSales.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final barData = topItems.take(5).toList();
        return Card(
          margin: const EdgeInsets.all(12),
          child: Column(
            children: [
              const ListTile(title: Text('Top Menu Items (By Quantity Sold)')),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= barData.length) return Container();
                            return Text(barData[idx].key);
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                    ),
                    barGroups: List.generate(barData.length, (i) => BarChartGroupData(
                      x: i,
                      barRods: [BarChartRodData(toY: barData[i].value.toDouble(), color: Colors.orange)],
                    )),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopSuppliers extends StatelessWidget {
  final FirestoreService firestoreService;
  const _TopSuppliers({required this.firestoreService});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: firestoreService.getSupplierReceipts().first,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final receipts = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return SupplierReceipt.fromMap(data, doc.id);
        }).toList();
        final supplierTotals = <String, double>{};
        for (var receipt in receipts) {
          supplierTotals[receipt.supplierName] = (supplierTotals[receipt.supplierName] ?? 0) + receipt.total;
        }
        final topSuppliers = supplierTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return Card(
          margin: const EdgeInsets.all(12),
          child: Column(
            children: [
              const ListTile(title: Text('Top Suppliers (By Purchase Value)')),
              ...topSuppliers.take(3).map((e) => ListTile(
                title: Text(e.key),
                trailing: Text('Purchased: KSh${e.value.toStringAsFixed(2)}'),
              )),
            ],
          ),
        );
      },
    );
  }
}

class _InventoryAlerts extends StatelessWidget {
  final FirestoreService firestoreService;
  const _InventoryAlerts({required this.firestoreService});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: firestoreService.getIngredients().first,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final ingredients = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Ingredient.fromMap(data, doc.id);
        }).where((i) => i.inventoryLevel < 5).toList();
        if (ingredients.isEmpty) {
          return const Card(
            margin: EdgeInsets.all(12),
            child: ListTile(title: Text('No inventory alerts.')),
          );
        }
        return Card(
          margin: const EdgeInsets.all(12),
          child: Column(
            children: [
              const ListTile(title: Text('Low Inventory Alerts')),
              ...ingredients.map((i) => ListTile(
                title: Text(i.name),
                trailing: Text('Inventory: ${i.inventoryLevel}'),
                textColor: Colors.red,
              )),
            ],
          ),
        );
      },
    );
  }
}
