import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List _medicines = [];
  bool _loading = true;
  String _error = '';
  int _page = 1;
  int _total = 0;
  static const _limit = 100;
  final _search = TextEditingController();
  String _filter = 'all'; // all | low_stock | expiring

  String get _token => Provider.of<AuthService>(context, listen: false).token;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load({int page = 1, String? search}) async {
    setState(() { _loading = true; _error = ''; _page = page; });
    try {
      final q = search ?? _search.text;
      final res = await ApiService.getMedicinesPaged(_token, search: q, page: page, limit: _limit);
      List data = res['data'] ?? [];
      if (_filter == 'low_stock') data = data.where((m) => (m['quantity'] ?? 0) <= 10).toList();
      if (_filter == 'expiring')  data = data.where((m) => ['HIGH_RISK','MEDIUM_RISK','EXPIRED'].contains(m['expiry_risk'])).toList();
      setState(() { _medicines = data; _total = res['total'] ?? 0; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load inventory.'; _loading = false; });
    }
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'EXPIRED':     return Colors.red;
      case 'HIGH_RISK':   return Colors.orange;
      case 'MEDIUM_RISK': return Colors.amber.shade700;
      default:            return Colors.green;
    }
  }

  Future<String?> _scanBarcode() async {
    String? result;
    await showModalBottomSheet(context: context, builder: (_) => SizedBox(
      height: 300,
      child: Column(children: [
        const Padding(padding: EdgeInsets.all(12),
            child: Text('Scan Barcode', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: MobileScanner(onDetect: (c) {
          final b = c.barcodes.firstOrNull;
          if (b?.rawValue != null) { result = b!.rawValue; Navigator.pop(context); }
        })),
      ]),
    ));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_total / _limit).ceil();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _load()),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddDialog(context)),
        ],
      ),
      body: Column(children: [
        // Search + filter bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(children: [
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search by name, batch, barcode...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.qr_code_scanner, size: 20), onPressed: () async {
                    final code = await _scanBarcode();
                    if (code != null) { _search.text = code; _load(search: code); }
                  }),
                  if (_search.text.isNotEmpty)
                    IconButton(icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { _search.clear(); _load(); }),
                ]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (v) => _load(search: v),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _filterChip('All', 'all'),
                const SizedBox(width: 8),
                _filterChip('Low Stock', 'low_stock'),
                const SizedBox(width: 8),
                _filterChip('Expiring', 'expiring'),
              ]),
            ),
          ]),
        ),

        // Stats
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(children: [
            Text('Total: $_total medicines',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const Spacer(),
            Text('Page $_page of ${totalPages == 0 ? 1 : totalPages}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),

        // Table header — desktop only
        if (MediaQuery.of(context).size.width > 600)
          Container(
            color: const Color(0xFF1565C0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Row(children: [
              Expanded(flex: 3, child: Text('Medicine', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Batch / Expiry', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('Qty', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              Expanded(flex: 1, child: Text('MRP', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              Expanded(flex: 1, child: Text('Status', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            ]),
          ),

        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8), Text(_error),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ]))
                  : _medicines.isEmpty
                      ? const Center(child: Text('No medicines found'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          itemCount: _medicines.length,
                          itemBuilder: (_, i) {
                            final m = _medicines[i];
                            final risk = m['expiry_risk'] ?? 'SAFE';
                            final color = _riskColor(risk);
                            final qty = m['quantity'] ?? 0;
                            final isMobile = MediaQuery.of(context).size.width <= 600;

                            if (isMobile) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border(left: BorderSide(color: color, width: 3)),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                                ),
                                child: Row(children: [
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(m['name'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 3),
                                    Text('Batch: ${m['batch_no'] ?? '-'}  ·  Exp: ${m['expiry_date'] ?? '-'}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    Text(m['company'] ?? m['supplier'] ?? '',
                                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                                        overflow: TextOverflow.ellipsis),
                                  ])),
                                  const SizedBox(width: 8),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Text('₹${m['selling_price']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('Qty: $qty',
                                          style: TextStyle(
                                              color: qty <= 10 ? Colors.red : Colors.green.shade700,
                                              fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ]),
                                ]),
                              );
                            }

                            // Desktop table row
                            return Container(
                              decoration: BoxDecoration(
                                color: i.isEven ? Colors.white : const Color(0xFFF9FAFB),
                                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(children: [
                                Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                      overflow: TextOverflow.ellipsis),
                                  Text(m['company'] ?? m['supplier'] ?? '',
                                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                                      overflow: TextOverflow.ellipsis),
                                ])),
                                Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(m['batch_no'] ?? '-', style: const TextStyle(fontSize: 11)),
                                  Text(m['expiry_date'] ?? '-', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                ])),
                                Expanded(flex: 1, child: Text('$qty',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                                        color: qty <= 10 ? Colors.red : Colors.black87),
                                    textAlign: TextAlign.center)),
                                Expanded(flex: 1, child: Text('₹${m['selling_price']}',
                                    style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
                                Expanded(flex: 1, child: Center(child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(risk == 'SAFE' ? '✓' : '!',
                                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                                ))),
                              ]),
                            );
                          }),
        ),

        // Pagination
        if (_total > _limit)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _page > 1 ? () => _load(page: _page - 1) : null,
              ),
              Text('$_page / $totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _page < totalPages ? () => _load(page: _page + 1) : null,
              ),
            ]),
          ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _filterChip(String label, String value) => GestureDetector(
    onTap: () { setState(() => _filter = value); _load(); },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _filter == value ? const Color(0xFF1565C0) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: _filter == value ? Colors.white : Colors.grey.shade700)),
    ),
  );

  void _showAddDialog(BuildContext context) {
    final c = {
      'name': TextEditingController(), 'batch_no': TextEditingController(),
      'expiry_date': TextEditingController(), 'supplier': TextEditingController(),
      'purchase_price': TextEditingController(), 'selling_price': TextEditingController(),
      'quantity': TextEditingController(), 'barcode': TextEditingController(),
      'company': TextEditingController(), 'packing': TextEditingController(),
    };
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16, right: 16, top: 20),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Medicine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...c.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: e.value,
              keyboardType: {'purchase_price','selling_price','quantity'}.contains(e.key)
                  ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                labelText: e.key.replaceAll('_', ' ').toUpperCase(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                suffixIcon: e.key == 'barcode' ? IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    final code = await _scanBarcode();
                    if (code != null) c['barcode']!.text = code;
                  }) : null,
              ),
            ),
          )),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: () async {
                if (c['name']!.text.trim().isEmpty) return;
                await ApiService.addMedicine(_token, {
                  'name': c['name']!.text.trim(), 'batch_no': c['batch_no']!.text.trim(),
                  'expiry_date': c['expiry_date']!.text.trim(), 'supplier': c['supplier']!.text.trim(),
                  'purchase_price': double.tryParse(c['purchase_price']!.text) ?? 0,
                  'selling_price': double.tryParse(c['selling_price']!.text) ?? 0,
                  'quantity': int.tryParse(c['quantity']!.text) ?? 0,
                  'barcode': c['barcode']!.text.trim(), 'company': c['company']!.text.trim(),
                  'packing': c['packing']!.text.trim(),
                });
                if (ctx.mounted) { Navigator.pop(ctx); _load(); }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('ADD MEDICINE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ])),
      ),
    );
  }
}
