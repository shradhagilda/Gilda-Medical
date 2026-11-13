import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List _salesChart = [];
  List _topMeds = [];
  List _deadStock = [];
  Map _gst = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final token = Provider.of<AuthService>(context, listen: false).token;
    final results = await Future.wait([
      ApiService.getSalesChart(token, days: 14),
      ApiService.getTopMedicines(token),
      ApiService.getDeadStock(token),
      ApiService.getGstReport(token),
    ]);
    setState(() {
      _salesChart = results[0] as List;
      _topMeds    = results[1] as List;
      _deadStock  = results[2] as List;
      _gst        = results[3] as Map;
      _loading    = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales & Analytics'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'Sales Chart'),
            Tab(text: 'Top Medicines'),
            Tab(text: 'Dead Stock'),
            Tab(text: 'GST Report'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabs, children: [
              _salesChartTab(),
              _topMedsTab(),
              _deadStockTab(),
              _gstTab(),
            ]),
    );
  }

  Widget _salesChartTab() {
    if (_salesChart.isEmpty) return const Center(child: Text('No sales data'));
    final spots = _salesChart.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), (e.value['revenue'] as num).toDouble())).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Last 14 Days Revenue', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, interval: 2,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt() < _salesChart.length
                        ? (_salesChart[v.toInt()]['date'] as String).substring(5)
                        : '',
                    style: const TextStyle(fontSize: 9)),
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => Text('₹${v.toInt()}',
                      style: const TextStyle(fontSize: 9)),
                )),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [LineChartBarData(
                spots: spots,
                isCurved: true,
                color: const Color(0xFF1565C0),
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                ),
              )],
            )),
          ),
        ],
      ),
    );
  }

  Widget _topMedsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _topMeds.length,
      itemBuilder: (_, i) {
        final m = _topMeds[i];
        return Card(child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Text(m['name'] ?? ''),
          trailing: Chip(
            label: Text('${m['total_sold']} units'),
            backgroundColor: Colors.blue.shade50,
          ),
        ));
      },
    );
  }

  Widget _deadStockTab() {
    if (_deadStock.isEmpty) {
      return const Center(child: Text('✅ No dead stock detected!',
          style: TextStyle(color: Colors.green, fontSize: 16)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _deadStock.length,
      itemBuilder: (_, i) {
        final d = _deadStock[i];
        return Card(child: ListTile(
          leading: const Icon(Icons.warning, color: Colors.red),
          title: Text(d['product'] ?? ''),
          subtitle: Text('Qty: ${d['total_qty']} | Value: ₹${d['total_value']}'),
          trailing: Chip(
            label: Text(d['dead_stock_label'] ?? ''),
            backgroundColor: Colors.red.shade50,
            labelStyle: const TextStyle(color: Colors.red, fontSize: 10),
          ),
        ));
      },
    );
  }

  Widget _gstTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const Text('GST Summary', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _gstRow('Total Sales', '₹${_gst['total_sales'] ?? 0}'),
            _gstRow('CGST (9%)', '₹${_gst['cgst_9pct'] ?? 0}'),
            _gstRow('SGST (9%)', '₹${_gst['sgst_9pct'] ?? 0}'),
            _gstRow('Total GST', '₹${_gst['total_gst'] ?? 0}'),
            const Divider(),
            _gstRow('Net Payable', '₹${_gst['net_payable'] ?? 0}', bold: true),
          ]),
        )),
      ]),
    );
  }

  Widget _gstRow(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: bold ? Colors.blue : null)),
    ]),
  );
}
