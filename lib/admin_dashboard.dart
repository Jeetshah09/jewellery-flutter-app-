import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminProduct {
  final String name;
  final String category;
  final String image;
  final int stock;

  const AdminProduct(
      {required this.name,
      required this.category,
      required this.image,
      required this.stock});

  factory AdminProduct.fromJson(Map<String, dynamic> json) => AdminProduct(
        name: json['name'] as String,
        category: json['category'] as String,
        image: json['image'] as String,
        stock: json['stock'] as int,
      );
}

class AdminDashboardPage extends StatefulWidget {
  final String token;

  const AdminDashboardPage({required this.token, super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic>? metrics;
  List<AdminProduct> products = [];
  String? error;
  bool loading = true;

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8003',
  );

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final responses = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/api/admin/dashboard'),
            headers: headers),
        http.get(Uri.parse('$apiBaseUrl/api/products?limit=100'),
            headers: headers),
      ]);
      if (responses.any((response) => response.statusCode != 200)) {
        throw Exception('Dashboard request failed');
      }
      final dashboard = jsonDecode(responses[0].body) as Map<String, dynamic>;
      final records = jsonDecode(responses[1].body) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        metrics = dashboard;
        products = records
            .map((item) => AdminProduct.fromJson(item as Map<String, dynamic>))
            .toList();
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'Could not load the live admin data.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STUDIO CONTROL',
                      style: TextStyle(
                          color: Color(0xFF9B4D5C),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
                  SizedBox(height: 8),
                  Text('Admin dashboard',
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
                ],
              ),
              IconButton(
                  onPressed: refresh,
                  tooltip: 'Refresh dashboard',
                  icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 24),
          if (loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator()))
          else if (error != null)
            _AdminMessage(message: error!)
          else ...[
            _MetricGrid(metrics: metrics!),
            const SizedBox(height: 30),
            const Text('Inventory overview',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...products.map((product) => _InventoryRow(product: product)),
          ],
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final values = [
      ('Products', metrics['total_products'] ?? 0, Icons.diamond_outlined),
      ('Customers', metrics['total_customers'] ?? 0, Icons.people_outline),
      ('Orders', metrics['total_orders'] ?? 0, Icons.receipt_long_outlined),
      (
        'Low stock',
        metrics['low_stock_products'] ?? 0,
        Icons.warning_amber_outlined
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 700 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: values.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6),
          itemBuilder: (context, index) {
            final item = values[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFEDE4DF),
                  borderRadius: BorderRadius.circular(4)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.$3, color: const Color(0xFF9B4D5C)),
                    const Spacer(),
                    Text('${item.$2}',
                        style: const TextStyle(
                            fontSize: 25, fontWeight: FontWeight.bold)),
                    Text(item.$1,
                        style: const TextStyle(
                            color: Color(0xFF746B6D), fontSize: 12))
                  ]),
            );
          },
        );
      },
    );
  }
}

class _InventoryRow extends StatelessWidget {
  final AdminProduct product;

  const _InventoryRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final lowStock = product.stock <= 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(3)),
      child: Row(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.network(product.image,
                width: 44, height: 44, fit: BoxFit.cover)),
        const SizedBox(width: 12),
        Expanded(
            child: Text(product.name,
                style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(product.category,
            style: const TextStyle(color: Color(0xFF746B6D), fontSize: 12)),
        const SizedBox(width: 18),
        Text('${product.stock} in stock',
            style: TextStyle(
                color: lowStock
                    ? const Color(0xFF9B4D5C)
                    : const Color(0xFF746B6D),
                fontSize: 12,
                fontWeight: lowStock ? FontWeight.bold : FontWeight.normal)),
      ]),
    );
  }
}

class _AdminMessage extends StatelessWidget {
  final String message;

  const _AdminMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(20),
        color: const Color(0xFFEDE4DF),
        child: Text(message));
  }
}
