import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});
  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  Map? _winner;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = Provider.of<AuthService>(context, listen: false).token;
    try {
      final data = await ApiService.getBestEmployee(token);
      setState(() {
        _winner = data;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Failed to load'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Rewards')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _winner == null || _winner!['winner'] == null
                  ? const Center(child: Text('No staff data available'))
                  : _buildWinner(),
    );
  }

  Widget _buildWinner() {
    final w = _winner!['winner'] as Map;
    final score = w['score'] ?? 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Trophy banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color: Colors.amber.withValues(alpha: 0.4),
              blurRadius: 16, offset: const Offset(0, 6),
            )],
          ),
          child: Column(children: [
            const Text('🏆', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Text(_winner!['reward'] ?? 'Employee of the Half-Year',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(_winner!['period'] ?? '6 months',
                style: const TextStyle(color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 24),

        // Winner card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  (w['name'] as String? ?? 'S')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Text(w['name'] ?? '', style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
              Text(w['role'] ?? '', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              const Divider(),
              _stat('Performance Score', '$score / 60', Colors.blue),
              _stat('Attendance Days', '${w['attendance_days']}', Colors.green),
              _stat('Late Days', '${w['late_days']}', Colors.orange),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  _winner!['message'] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _stat(String label, String value, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.grey)),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
    ]),
  );
}
