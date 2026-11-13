import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});
  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  List _pending = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final token = Provider.of<AuthService>(context, listen: false).token;
    setState(() => _loading = true);
    try {
      final data = await ApiService.getPendingUsers(token);
      setState(() { _pending = data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _action(int userId, String action) async {
    final token = Provider.of<AuthService>(context, listen: false).token;
    await ApiService.approveUser(token, userId, action);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pending.isEmpty
              ? const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green),
                    SizedBox(height: 12),
                    Text('No pending requests', style: TextStyle(fontSize: 16)),
                  ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _pending.length,
                  itemBuilder: (_, i) {
                    final u = _pending[i] as Map;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text((u['name'] as String? ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(u['email'] ?? '', style: const TextStyle(color: Colors.grey)),
                            ])),
                            Chip(
                              label: Text(u['role'] ?? '', style: const TextStyle(fontSize: 11)),
                              backgroundColor: Colors.blue.shade50,
                            ),
                          ]),
                          const SizedBox(height: 8),
                          if (u['pharmacy_name'] != null && u['pharmacy_name'].toString().isNotEmpty)
                            Text('🏥 ${u['pharmacy_name']}', style: const TextStyle(color: Colors.grey)),
                          if (u['phone'] != null && u['phone'].toString().isNotEmpty)
                            Text('📞 ${u['phone']}', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: OutlinedButton.icon(
                              onPressed: () => _action(u['id'], 'reject'),
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text('Reject', style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: ElevatedButton.icon(
                              onPressed: () => _action(u['id'], 'approve'),
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green, foregroundColor: Colors.white),
                            )),
                          ]),
                        ]),
                      ),
                    );
                  }),
    );
  }
}
