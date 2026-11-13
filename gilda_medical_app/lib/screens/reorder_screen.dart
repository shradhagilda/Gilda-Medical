import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class ReorderScreen extends StatefulWidget {
  const ReorderScreen({super.key});
  @override
  State<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends State<ReorderScreen> {
  List _lowStock = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final token = Provider.of<AuthService>(context, listen: false).token;
    final data = await ApiService.getLowStock(token);
    setState(() { _lowStock = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Reorder')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lowStock.isEmpty
              ? const Center(child: Text('✅ All stock levels are healthy!',
                  style: TextStyle(color: Colors.green, fontSize: 16)))
              : Column(children: [
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(children: [
                      const Icon(Icons.shopping_cart, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text('${_lowStock.length} medicines need reordering',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _lowStock.length,
                      itemBuilder: (_, i) {
                        final m = _lowStock[i];
                        final suggestedQty = ((m['quantity'] ?? 0) < 5) ? 100 : 50;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.inventory_2, color: Colors.red),
                            title: Text(m['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Current Stock: ${m['quantity']} units'),
                                Text('Supplier: ${m['supplier'] ?? 'N/A'}'),
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('AI Suggests: Order $suggestedQty units',
                                      style: const TextStyle(color: Colors.blue, fontSize: 11)),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Order placed for ${m['name']}'))),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, foregroundColor: Colors.white),
                              child: const Text('Order', style: TextStyle(fontSize: 12)),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
                  ),
                ]),
    );
  }
}
