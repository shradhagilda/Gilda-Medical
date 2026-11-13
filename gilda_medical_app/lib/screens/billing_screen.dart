import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

// ── Pharmacy branding constants ──────────────────────────────────
const _kPharmacyName    = 'GILDA Medical';
const _kPharmacyTagline = 'Pharmacy Management System';
const _kAddress         = 'Gandhi Chowk, Shop No 8, Latur, Maharashtra';
const _kPhone           = '8275460166';
const _kGstRate         = 0.12;

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});
  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final List<Map> _cart = [];
  final _customerCtrl = TextEditingController(text: 'Walk-in');
  final _searchCtrl   = TextEditingController();
  List  _searchResults = [];
  Map?  _billResult;
  bool  _processing = false;
  int   _invoiceNo  = 1001;

  String get _token => Provider.of<AuthService>(context, listen: false).token;

  // ── Barcode scanner ──────────────────────────────────────────
  Future<void> _scanBarcode() async {
    String? code;
    await showModalBottomSheet(context: context, builder: (_) => SizedBox(
      height: 320,
      child: Column(children: [
        const Padding(padding: EdgeInsets.all(12),
            child: Text('Point camera at barcode',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
        Expanded(child: MobileScanner(onDetect: (c) {
          final b = c.barcodes.firstOrNull;
          if (b?.rawValue != null) { code = b!.rawValue; Navigator.pop(context); }
        })),
      ]),
    ));
    if (code == null || !mounted) return;
    final med = await ApiService.getMedicineByBarcode(_token, code!);
    if (!mounted) return;
    med.containsKey('error')
        ? ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Not found: $code'), backgroundColor: Colors.red))
        : _addToCart(med);
  }

  // ── Search ───────────────────────────────────────────────────
  Future<void> _search(String q) async {
    if (q.isEmpty) { setState(() => _searchResults = []); return; }
    final data = await ApiService.getMedicines(_token, search: q, limit: 8);
    if (mounted) setState(() => _searchResults = data.take(8).toList());
  }

  void _addToCart(Map med) {
    setState(() {
      final idx = _cart.indexWhere((c) => c['medicine_id'] == med['id']);
      if (idx >= 0) {
        _cart[idx]['quantity']++;
      } else {
        _cart.add({
          'medicine_id': med['id'],
          'name':        med['name'],
          'batch':       med['batch_no'] ?? '-',
          'expiry':      med['expiry_date'] ?? '-',
          'price':       (med['selling_price'] as num).toDouble(),
          'quantity':    1,
        });
      }
      _searchResults = [];
      _searchCtrl.clear();
    });
  }

  double get _subtotal  => _cart.fold(0.0, (s, i) => s + (i['price'] * i['quantity']));
  double get _gstAmt    => _subtotal * _kGstRate;
  double get _grandTotal => _subtotal + _gstAmt;

  // ── Process sale ─────────────────────────────────────────────
  Future<void> _processBill() async {
    if (_cart.isEmpty) return;
    setState(() => _processing = true);
    final items = _cart.map((c) => {'medicine_id': c['medicine_id'], 'quantity': c['quantity']}).toList();
    final result = await ApiService.processSale(_token, items, _customerCtrl.text);
    if (mounted) setState(() { _billResult = result; _invoiceNo++; _processing = false; });
  }

  void _clearCart() => setState(() { _cart.clear(); _billResult = null; });

  // ── Print / show invoice ─────────────────────────────────────
  void _showInvoice() {
    if (_billResult == null) return;
    showDialog(context: context, builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _InvoiceWidget(
            invoiceNo: _invoiceNo - 1,
            customer: _customerCtrl.text,
            items: List<Map>.from(_billResult!['items'] ?? []),
            subtotal:   (_billResult!['total']       as num).toDouble(),
            gst:        (_billResult!['gst']         as num).toDouble(),
            grandTotal: (_billResult!['grand_total'] as num).toDouble(),
            date:       _billResult!['date'] ?? '',
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text('Smart Billing'),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner),
              onPressed: _scanBarcode, tooltip: 'Scan Barcode'),
          if (_cart.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_outline),
                onPressed: _clearCart, tooltip: 'Clear Cart'),
        ],
      ),
      body: Column(children: [

        // ── Header: customer + search ──────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(children: [
            // Pharmacy info strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.local_pharmacy, color: Color(0xFF1565C0), size: 18),
                const SizedBox(width: 8),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_kPharmacyName,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1565C0))),
                  Text(_kAddress, style: TextStyle(fontSize: 10, color: Colors.grey)),
                ])),
                Text('📞 $_kPhone', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ),
            const SizedBox(height: 10),
            // Customer
            TextField(
              controller: _customerCtrl,
              decoration: InputDecoration(
                labelText: 'Customer Name',
                prefixIcon: const Icon(Icons.person_outline, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            // Search
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search medicine by name...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF1565C0), size: 20),
                  onPressed: _scanBarcode,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              onChanged: _search,
            ),
          ]),
        ),

        // ── Search results ─────────────────────────────────────
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue.shade100),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Column(children: _searchResults.map((m) => InkWell(
              onTap: () => _addToCart(m),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(children: [
                  const Icon(Icons.medication, color: Color(0xFF1565C0), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('Qty: ${m['quantity']}  |  MRP: ₹${m['selling_price']}  |  Exp: ${m['expiry_date'] ?? '-'}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ])),
                  const Icon(Icons.add_circle, color: Colors.green, size: 20),
                ]),
              ),
            )).toList()),
          ),

        // ── Cart table header ──────────────────────────────────
        if (_cart.isNotEmpty)
          Container(
            color: const Color(0xFF1565C0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Row(children: [
              Expanded(flex: 4, child: Text('Medicine', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Batch/Exp', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
              SizedBox(width: 80, child: Text('Qty', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('Total', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
            ]),
          ),

        // ── Cart items ─────────────────────────────────────────
        Expanded(
          child: _cart.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade200),
                  const SizedBox(height: 12),
                  Text('Cart is empty', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                  Text('Search or scan medicines above', style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
                ]))
              : ListView.builder(
                  itemCount: _cart.length,
                  itemBuilder: (_, i) {
                    final item = _cart[i];
                    final total = (item['price'] * item['quantity']) as double;
                    return Container(
                      decoration: BoxDecoration(
                        color: i.isEven ? Colors.white : const Color(0xFFF9FAFB),
                        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(children: [
                        Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                          Text('₹${item['price']} each', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ])),
                        Expanded(flex: 2, child: Text('${item['batch']}\n${item['expiry']}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey))),
                        SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          GestureDetector(
                            onTap: () => setState(() {
                              if (item['quantity'] > 1) item['quantity']--;
                              else _cart.removeAt(i);
                            }),
                            child: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('${item['quantity']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => item['quantity']++),
                            child: const Icon(Icons.add_circle_outline, size: 18, color: Colors.green),
                          ),
                        ])),
                        Expanded(flex: 2, child: Text('₹${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
                                color: Color(0xFF1565C0)),
                            textAlign: TextAlign.right)),
                      ]),
                    );
                  }),
        ),

        // ── Bill success banner ────────────────────────────────
        if (_billResult != null && !(_billResult!.containsKey('error')))
          GestureDetector(
            onTap: _showInvoice,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Bill Generated!',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('Grand Total: ₹${_billResult!['grand_total']}  |  GST: ₹${_billResult!['gst']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ])),
                const Text('View Invoice →',
                    style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
            ),
          ),

        // ── Bottom totals + action bar ─────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
          ),
          child: Column(children: [
            // Totals
            if (_cart.isNotEmpty) ...[
              _totalRow('Subtotal', '₹${_subtotal.toStringAsFixed(2)}'),
              _totalRow('GST (12%)', '₹${_gstAmt.toStringAsFixed(2)}'),
              const Divider(height: 12),
              _totalRow('Grand Total', '₹${_grandTotal.toStringAsFixed(2)}',
                  bold: true, color: const Color(0xFF1565C0)),
              const SizedBox(height: 12),
            ],
            // Buttons
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: _cart.isEmpty ? null : _clearCart,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton.icon(
                onPressed: (_cart.isEmpty || _processing) ? null : _processBill,
                icon: _processing
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.receipt_long, size: 18),
                label: Text(_processing ? 'Processing...' : 'Generate Bill',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: Colors.grey.shade700, fontSize: bold ? 14 : 13)),
      Text(value, style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color ?? Colors.black87, fontSize: bold ? 16 : 13)),
    ]),
  );
}

// ── Professional Invoice Widget ──────────────────────────────────
class _InvoiceWidget extends StatelessWidget {
  final int invoiceNo;
  final String customer, date;
  final List<Map> items;
  final double subtotal, gst, grandTotal;

  const _InvoiceWidget({
    required this.invoiceNo, required this.customer, required this.date,
    required this.items, required this.subtotal, required this.gst, required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Center(child: Column(children: [
        const Icon(Icons.local_pharmacy, color: Color(0xFF1565C0), size: 36),
        const SizedBox(height: 4),
        const Text(_kPharmacyName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
        const Text(_kPharmacyTagline, style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        const Text(_kAddress, style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
        Text('📞 $_kPhone', style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ])),
      const SizedBox(height: 12),
      const Divider(thickness: 2, color: Color(0xFF1565C0)),

      // Invoice meta
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Invoice #: INV-${invoiceNo.toString().padLeft(4, '0')}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text('Customer: $customer', style: const TextStyle(fontSize: 12)),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Date: $date', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ]),
      const SizedBox(height: 10),

      // Table header
      Container(
        color: const Color(0xFF1565C0),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: const Row(children: [
          Expanded(flex: 3, child: Text('Medicine', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('Qty', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text('MRP', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
          Expanded(flex: 1, child: Text('Total', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        ]),
      ),

      // Items
      ...items.asMap().entries.map((e) {
        final i = e.key; final m = e.value;
        return Container(
          color: i.isEven ? Colors.white : const Color(0xFFF9FAFB),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(children: [
            Expanded(flex: 3, child: Text(m['name'] ?? '',
                style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
            Expanded(flex: 1, child: Text('${m['qty']}',
                style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
            Expanded(flex: 1, child: Text('₹${m['price']}',
                style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
            Expanded(flex: 1, child: Text('₹${m['subtotal']}',
                style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
          ]),
        );
      }),

      const Divider(),

      // Totals
      _row('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
      _row('GST (12%)', '₹${gst.toStringAsFixed(2)}'),
      const Divider(thickness: 1.5),
      _row('Grand Total', '₹${grandTotal.toStringAsFixed(2)}', bold: true),

      const SizedBox(height: 20),
      const Center(child: Text('Thank you for visiting GILDA Medical',
          style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic))),
      const SizedBox(height: 16),
      const Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(width: 120, child: Divider(thickness: 1)),
          Text('Authorized Signature', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ]),
      const SizedBox(height: 8),
      Center(child: TextButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close, size: 16),
        label: const Text('Close'),
      )),
    ]);
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
      Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: bold ? 14 : 12, color: bold ? const Color(0xFF1565C0) : null)),
    ]),
  );
}
