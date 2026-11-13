import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class ExpiryAnalysisScreen extends StatefulWidget {
  const ExpiryAnalysisScreen({super.key});
  @override
  State<ExpiryAnalysisScreen> createState() => _ExpiryAnalysisScreenState();
}

class _ExpiryAnalysisScreenState extends State<ExpiryAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List _all = [];
  // Map of medicine id -> AI risk label
  final Map<int, String> _aiRisk = {};
  final Map<int, bool> _aiLoading = {};
  bool _loading = true;
  bool _fetchingAI = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// Fetch ALL medicines using pagination (backend caps at 500 per call)
  Future<void> _load() async {
    setState(() { _loading = true; _aiRisk.clear(); });
    final token = Provider.of<AuthService>(context, listen: false).token;
    try {
      List allMeds = [];
      int page = 1;
      const int pageSize = 500;
      while (true) {
        final data = await ApiService.getMedicines(token, page: page, limit: pageSize);
        allMeds.addAll(data);
        if (data.length < pageSize) break;
        page++;
      }
      setState(() { _all = allMeds; _loading = false; });
      // Auto-fetch AI suggestions for expiring/expired items
      _fetchAiSuggestionsForRiskyItems(token);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  /// Call AI prediction endpoint for medicines that are expiring/expired
  Future<void> _fetchAiSuggestionsForRiskyItems(String token) async {
    if (_fetchingAI) return;
    _fetchingAI = true;
    final risky = _all.where((m) {
      final s = _status(m);
      return s == 'Expired' || s == 'Expiring Soon' || s == 'Expiring in 90 days';
    }).toList();

    for (final m in risky) {
      final id = m['id'] as int? ?? m.hashCode;
      if (_aiRisk.containsKey(id)) continue;
      setState(() => _aiLoading[id] = true);
      try {
        final expParts = (m['expiry_date'] as String? ?? '').split('/');
        if (expParts.length == 2) {
          final expMonth = int.parse(expParts[0]);
          final expYear  = int.parse(expParts[1]) + (int.parse(expParts[1]) < 100 ? 2000 : 0);
          final result = await ApiService.predictExpiryRisk(token, {
            'product':   m['name'] ?? '',
            'qty':       m['quantity'] ?? 0,
            'mrp':       (m['selling_price'] ?? 0).toDouble(),
            'mrp_value': ((m['selling_price'] ?? 0) * (m['quantity'] ?? 0)).toDouble(),
            'exp_month': expMonth,
            'exp_year':  expYear,
          });
          if (mounted) {
            setState(() {
              _aiRisk[id]    = result['expiry_risk'] ?? 'UNKNOWN';
              _aiLoading[id] = false;
            });
          }
        }
      } catch (_) {
        if (mounted) setState(() => _aiLoading[id] = false);
      }
    }
    _fetchingAI = false;
  }

  // ── Rule-based status ──────────────────────────────────────────
  String _status(Map m) {
    final exp = m['expiry_date'] as String?;
    if (exp == null || exp.isEmpty) return 'Unknown';
    try {
      final parts = exp.split('/');
      if (parts.length != 2) return 'Unknown';
      final month = int.parse(parts[0]);
      final year  = int.parse(parts[1]) + (int.parse(parts[1]) < 100 ? 2000 : 0);
      final expDate = DateTime(year, month + 1, 0);
      final days = expDate.difference(DateTime.now()).inDays;
      if (days < 0)   return 'Expired';
      if (days <= 30) return 'Expiring Soon';
      if (days <= 90) return 'Expiring in 90 days';
      return 'Safe';
    } catch (_) {
      return 'Unknown';
    }
  }

  int _daysLeft(Map m) {
    final exp = m['expiry_date'] as String?;
    if (exp == null || exp.isEmpty) return 9999;
    try {
      final parts = exp.split('/');
      final month = int.parse(parts[0]);
      final year  = int.parse(parts[1]) + (int.parse(parts[1]) < 100 ? 2000 : 0);
      final expDate = DateTime(year, month + 1, 0);
      return expDate.difference(DateTime.now()).inDays;
    } catch (_) {
      return 9999;
    }
  }

  List get _expired => _all.where((m) => _status(m) == 'Expired').toList()
    ..sort((a, b) => _daysLeft(a).compareTo(_daysLeft(b)));
  List get _soon30  => _all.where((m) => _status(m) == 'Expiring Soon').toList()
    ..sort((a, b) => _daysLeft(a).compareTo(_daysLeft(b)));
  List get _soon90  => _all.where((m) => _status(m) == 'Expiring in 90 days').toList()
    ..sort((a, b) => _daysLeft(a).compareTo(_daysLeft(b)));

  // ── AI risk colour & label helpers ────────────────────────────
  Color _aiColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'HIGH_RISK':   return Colors.red.shade700;
      case 'MEDIUM_RISK': return Colors.orange.shade700;
      case 'SAFE':        return Colors.green.shade700;
      default:            return Colors.grey.shade600;
    }
  }

  String _aiLabel(String risk) {
    switch (risk.toUpperCase()) {
      case 'HIGH_RISK':   return '🔴 High Risk';
      case 'MEDIUM_RISK': return '🟠 Medium Risk';
      case 'SAFE':        return '🟢 Safe';
      default:            return '⚪ Unknown';
    }
  }

  String _aiSuggestion(String risk) {
    switch (risk.toUpperCase()) {
      case 'HIGH_RISK':
        return 'AI Suggestion: Offer immediate discount or return to supplier. '
               'Consider marking for disposal if unsellable.';
      case 'MEDIUM_RISK':
        return 'AI Suggestion: Run a promotion or bundle with fast-moving items. '
               'Monitor closely and restock conservatively.';
      case 'SAFE':
        return 'AI Suggestion: Continue normal sales. No immediate action needed.';
      default:
        return 'AI Suggestion: Review product manually. Expiry date may be missing.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Expiry Tracker'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Expired (${_loading ? '…' : _expired.length})'),
            Tab(text: '≤30 Days (${_loading ? '…' : _soon30.length})'),
            Tab(text: '≤90 Days (${_loading ? '…' : _soon90.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // ── AI banner ──────────────────────────────────────
              _aiBanner(),
              // ── Summary cards ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(children: [
                  _summaryCard('Expired',    _expired.length, Colors.red),
                  const SizedBox(width: 8),
                  _summaryCard('≤30 Days',  _soon30.length,  Colors.orange),
                  const SizedBox(width: 8),
                  _summaryCard('≤90 Days',  _soon90.length,  Colors.amber.shade700),
                ]),
              ),
              // ── Tab body ───────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _table(_expired, Colors.red),
                    _table(_soon30,  Colors.orange),
                    _table(_soon90,  Colors.amber.shade700),
                  ],
                ),
              ),
            ]),
    );
  }

  // ── AI banner ──────────────────────────────────────────────────
  Widget _aiBanner() {
    final total = _expired.length + _soon30.length + _soon90.length;
    final aiDone = _aiRisk.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('AI Expiry Risk Analysis',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            total == 0
                ? 'No at-risk medicines found — inventory is healthy!'
                : 'Analysing $total at-risk medicines · AI scored $aiDone/$total',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ])),
        if (total > 0 && aiDone < total)
          const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white,
            ),
          ),
      ]),
    );
  }

  // ── Summary card ───────────────────────────────────────────────
  Widget _summaryCard(String label, int count, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text('$count',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 11, color: color)),
      ]),
    ),
  );

  // ── Medicine list ─────────────────────────────────────────────
  Widget _table(List items, Color color) {
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle, size: 56, color: Colors.green.shade300),
          const SizedBox(height: 12),
          const Text('No medicines in this category',
              style: TextStyle(color: Colors.grey)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final m    = items[i];
        final id   = m['id'] as int? ?? m.hashCode;
        final days = _daysLeft(m);
        final daysText = days < 0
            ? 'Expired ${-days}d ago'
            : '$days days left';
        final aiRisk    = _aiRisk[id];
        final aiPending = _aiLoading[id] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.20)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(children: [
            // ── Top row: medicine info ────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(
                      days < 0 ? Icons.dangerous : Icons.warning_amber,
                      color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(m['name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text(
                      'Batch: ${m['batch_no'] ?? '-'}  |  Exp: ${m['expiry_date'] ?? '-'}  |  Qty: ${m['quantity']}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(daysText,
                        style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  Text('₹${m['selling_price']}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ]),
              ]),
            ),

            // ── AI Suggestion panel ───────────────────────────
            if (aiPending)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(children: [
                  SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.blue.shade400),
                  ),
                  const SizedBox(width: 8),
                  const Text('Getting AI risk assessment…',
                      style: TextStyle(
                          fontSize: 11, color: Colors.blueGrey)),
                ]),
              )
            else if (aiRisk != null)
              _aiSuggestionPanel(aiRisk)
            else
              const SizedBox.shrink(),
          ]),
        );
      },
    );
  }

  // ── AI suggestion panel widget ────────────────────────────────
  Widget _aiSuggestionPanel(String risk) {
    final color      = _aiColor(risk);
    final label      = _aiLabel(risk);
    final suggestion = _aiSuggestion(risk);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.auto_awesome, size: 13, color: Colors.blueGrey),
          const SizedBox(width: 4),
          const Text('AI Assessment',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6)),
            child: Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(suggestion,
            style: const TextStyle(fontSize: 11, color: Color(0xFF37474F))),
      ]),
    );
  }
}
