import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AlternativesScreen extends StatefulWidget {
  const AlternativesScreen({super.key});
  @override
  State<AlternativesScreen> createState() => _AlternativesScreenState();
}

class _AlternativesScreenState extends State<AlternativesScreen> {
  final _ctrl = TextEditingController();
  Map? _result;
  bool _loading = false;

  Future<void> _search() async {
    if (_ctrl.text.isEmpty) return;
    setState(() => _loading = true);
    final token = Provider.of<AuthService>(context, listen: false).token;
    final data = await ApiService.getAlternatives(token, _ctrl.text.trim());
    setState(() { _result = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Alternatives')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Enter medicine name (e.g. CROCIN)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (_) => _search(),
            )),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _search, child: const Text('Find')),
          ]),
          const SizedBox(height: 16),

          if (_loading) const CircularProgressIndicator(),

          if (_result != null && !_loading) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.medication, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Alternatives for: ${_result!['medicine']}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: (_result!['alternatives'] as List?)?.length ?? 0,
                itemBuilder: (_, i) {
                  final alt = (_result!['alternatives'] as List)[i];
                  return Card(child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Text('${i + 1}', style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(alt['name'] ?? ''),
                    subtitle: Text('${alt['packing']} | ${alt['company']}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('₹${alt['avg_mrp']}', style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue)),
                        Text('${alt['similarity']}% match',
                            style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ));
                },
              ),
            ),
          ],

          if (_result == null && !_loading)
            const Expanded(child: Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Search for a medicine to find alternatives',
                    style: TextStyle(color: Colors.grey)),
              ],
            ))),
        ]),
      ),
    );
  }
}
