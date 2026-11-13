import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List _staff = [];
  Map _summary = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    final token = Provider.of<AuthService>(context, listen: false).token;
    final results = await Future.wait([ApiService.getStaff(token), ApiService.getStaffSummary(token)]);
    setState(() {
      _staff   = results[0] as List;
      _summary = results[1] as Map;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        bottom: TabBar(controller: _tabs, labelColor: Colors.white,
            tabs: const [Tab(text: 'Staff List'), Tab(text: 'Attendance')]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabs, children: [_staffTab(), _attendanceTab()]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStaff(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _staffTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          _card('Total', '${_summary['total_staff'] ?? 0}', Colors.blue),
          const SizedBox(width: 8),
          _card('Present', '${_summary['present_today'] ?? 0}', Colors.green),
          const SizedBox(width: 8),
          _card('Salary', '₹${_summary['total_salary'] ?? 0}', Colors.purple),
        ]),
      ),
      Expanded(
        child: _staff.isEmpty
            ? const Center(child: Text('No staff added yet'))
            : ListView.builder(
                itemCount: _staff.length,
                itemBuilder: (_, i) {
                  final s = _staff[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text((s['name'] as String? ?? 'S')[0],
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      title: Text(s['name'] ?? ''),
                      subtitle: Text('${s['role']} | Attendance: ${s['attendance']} days'),
                      trailing: Text('₹${s['salary']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                  );
                }),
      ),
    ]);
  }

  Widget _attendanceTab() {
    return _staff.isEmpty
        ? const Center(child: Text('No staff found'))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _staff.length,
            itemBuilder: (_, i) {
              final s = _staff[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Text((s['name'] as String? ?? 'S')[0]),
                  ),
                  title: Text(s['name'] ?? ''),
                  subtitle: Text(s['role'] ?? ''),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    _attBtn('In', Colors.green, () => _checkIn(s['id'])),
                    const SizedBox(width: 6),
                    _attBtn('Out', Colors.orange, () => _checkOut(s['id'])),
                  ]),
                ),
              );
            });
  }

  Widget _attBtn(String label, Color color, VoidCallback onTap) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
        backgroundColor: color, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );

  Future<void> _checkIn(int staffId) async {
    final token = Provider.of<AuthService>(context, listen: false).token;
    final res = await ApiService.checkIn(token, staffId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? res['error'] ?? 'Done'),
        backgroundColor: res.containsKey('error') ? Colors.red : Colors.green));
    _load();
  }

  Future<void> _checkOut(int staffId) async {
    final token = Provider.of<AuthService>(context, listen: false).token;
    final res = await ApiService.checkOut(token, staffId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? res['error'] ?? 'Done'),
        backgroundColor: res.containsKey('error') ? Colors.red : Colors.orange));
  }

  Widget _card(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    ),
  );

  void _showAddStaff(BuildContext context) {
    final nameCtrl   = TextEditingController();
    final roleCtrl   = TextEditingController();
    final salaryCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Add Staff'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Name')),
        TextField(controller: roleCtrl,
            decoration: const InputDecoration(labelText: 'Role')),
        TextField(controller: salaryCtrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Salary')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final token = Provider.of<AuthService>(context, listen: false).token;
            await ApiService.addStaff(token, {
              'name': nameCtrl.text,
              'role': roleCtrl.text,
              'salary': double.tryParse(salaryCtrl.text) ?? 0,
            });
            if (context.mounted) { Navigator.pop(context); _load(); }
          },
          child: const Text('Add'),
        ),
      ],
    ));
  }
}
