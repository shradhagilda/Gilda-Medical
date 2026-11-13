import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List _alerts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final token = Provider.of<AuthService>(context, listen: false).token;
    if (token.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Please login to view alerts';
        });
      }
      return;
    }
    try {
      final data = await ApiService.getAlerts(token);
      if (mounted) {
        setState(() {
          _alerts = data;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('Alerts load error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load alerts. Check server connection. Tap retry.';
        });
      }
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'expiry':
        return Icons.warning;
      case 'stock':
        return Icons.inventory;
      case 'fraud':
        return Icons.security;
      default:
        return Icons.notifications;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'expiry':
        return Colors.orange;
      case 'stock':
        return Colors.red;
      case 'fraud':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading
                ? null
                : () {
                    _error = null;
                    _loading = true;
                    _load();
                  },
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Card(
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _loading = true;
                          });
                          _load();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _alerts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off,
                              size: 64, color: Colors.green),
                          SizedBox(height: 16),
                          Text('✅ No alerts',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.green)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _alerts.length,
                      itemBuilder: (context, i) {
                        final a = _alerts[i] as Map? ?? {};
                        final type = a['type']?.toString() ?? 'unknown';
                        final status = a['status']?.toString() ?? '';
                        final isUnread = status == 'unread';
                        final message =
                            a['message']?.toString() ?? 'No message';
                        final dateStr = a['date']?.toString() ?? '';
                        final date = dateStr.length > 16
                            ? dateStr.substring(0, 16)
                            : dateStr;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          color: isUnread ? Colors.blue.shade50 : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _color(type).withValues(alpha: 0.2),
                              child: Icon(_icon(type), color: _color(type)),
                            ),
                            title: Text(message,
                                style: TextStyle(
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                )),
                            subtitle: Text(date),
                            trailing: isUnread
                                ? Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
    );
  }
}
