import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'inventory_screen.dart';
import 'billing_screen.dart';
import 'expiry_analysis_screen.dart';
import 'alerts_screen.dart';
import 'analytics_screen.dart';
import 'staff_screen.dart';
import 'reorder_screen.dart';
import 'alternatives_screen.dart';
import 'approval_screen.dart';
import 'reward_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map  _data = {}, _revenue = {}, _loss = {};
  List _salesChart = [];
  bool _loading = true;
  int  _unread = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final token = Provider.of<AuthService>(context, listen: false).token;
    try {
      final r = await Future.wait([
        ApiService.getDashboard(token),
        ApiService.getTodayRevenue(token),
        ApiService.getLossPrevention(token),
        ApiService.getUnreadCount(token),
        ApiService.getSalesChart(token, days: 7),
      ]);
      setState(() {
        _data       = r[0] as Map;
        _revenue    = r[1] as Map;
        _loss       = r[2] as Map;
        _unread     = (r[3] as Map)['unread'] ?? 0;
        _salesChart = r[4] as List;
        _loading    = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  void _go(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final role = auth.role;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _appBar(auth, role),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Welcome banner ──────────────────────────────────
            _welcomeBanner(auth),
            const SizedBox(height: 20),

            // ── KPI row ─────────────────────────────────────────
            if (!_loading) ...[
              Row(children: [
                _kpi('Revenue', '₹${_revenue['revenue'] ?? 0}', Colors.green.shade700, const Color(0xFFE8F5E9)),
                const SizedBox(width: 10),
                _kpi('Low Stock', '${_data['low_stock_count'] ?? 0}', Colors.orange.shade700, const Color(0xFFFFF3E0)),
                const SizedBox(width: 10),
                _kpi('Expiring', '${_data['expiring_soon_count'] ?? 0}', Colors.red.shade700, const Color(0xFFFFEBEE)),
              ]),
              const SizedBox(height: 20),
            ],

            // ── Feature cards grid ──────────────────────────────
            const Text('Features', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF263238))),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10, mainAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                if (role != 'staff') ...[
                  _FeatureCard('Billing', 'Create & print bills',
                      Icons.point_of_sale, const Color(0xFF1565C0),
                      () => _go(const BillingScreen())),
                  _FeatureCard('Inventory', 'Manage medicine stock',
                      Icons.inventory_2, Colors.green.shade700,
                      () => _go(const InventoryScreen())),
                ],
                _FeatureCard('Expiry Checker', 'Check expiring medicines',
                    Icons.warning_amber, Colors.orange.shade700,
                    () => _go(const ExpiryAnalysisScreen())),
                _FeatureCard('Reports', 'Sales & analytics',
                    Icons.bar_chart, Colors.purple.shade600,
                    () => _go(const AnalyticsScreen())),
                _FeatureCard('Reorder', 'AI reorder suggestions',
                    Icons.shopping_cart, Colors.teal.shade700,
                    () => _go(const ReorderScreen())),
                _FeatureCard('Alternatives', 'Find substitutes',
                    Icons.swap_horiz, Colors.indigo.shade600,
                    () => _go(const AlternativesScreen())),
                _FeatureCard('Alerts', 'Stock & expiry alerts',
                    Icons.notifications_active, Colors.red.shade600,
                    () => _go(const AlertsScreen()),
                    badge: _unread),
                if (role == 'admin') ...[
                  _FeatureCard('Staff', 'Attendance & salary',
                      Icons.people, Colors.brown.shade600,
                      () => _go(const StaffScreen())),
                  _FeatureCard('Approvals', 'User registrations',
                      Icons.how_to_reg, Colors.deepOrange,
                      () => _go(const ApprovalScreen())),
                  _FeatureCard('Rewards', 'Best employee',
                      Icons.emoji_events, Colors.amber.shade700,
                      () => _go(const RewardScreen())),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // ── Sales chart ─────────────────────────────────────
            if (_salesChart.isNotEmpty) ...[
              const Text('Sales — Last 7 Days', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF263238))),
              const SizedBox(height: 12),
              _salesChartCard(),
              const SizedBox(height: 20),
            ],

            // ── AI banner ───────────────────────────────────────
            _aiBanner(),
          ]),
        ),
      ),
      floatingActionButton: role != 'staff' ? FloatingActionButton.extended(
        onPressed: () => _go(const BillingScreen()),
        icon: const Icon(Icons.point_of_sale),
        label: const Text('New Bill', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ) : null,
    );
  }

  PreferredSizeWidget _appBar(AuthService auth, String role) => AppBar(
    backgroundColor: const Color(0xFF1565C0),
    foregroundColor: Colors.white,
    elevation: 0,
    titleSpacing: 16,
    title: Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
        child: const Icon(Icons.local_pharmacy, size: 18, color: Colors.white),
      ),
      const SizedBox(width: 10),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('GILDA Medical',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        Text('Pharmacy System',
            style: TextStyle(fontSize: 10, color: Colors.white70)),
      ]),
    ]),
    actions: [
      // Notification bell
      Stack(children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AlertsScreen())),
        ),
        if (_unread > 0)
          Positioned(right: 8, top: 8,
            child: Container(
              width: 15, height: 15,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Center(child: Text('$_unread',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
            )),
      ]),
      // Role chip
      Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(role.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
      // Logout
      IconButton(
        icon: const Icon(Icons.power_settings_new_outlined),
        onPressed: auth.logout,
        tooltip: 'Logout',
      ),
    ],
  );

  Widget _welcomeBanner(AuthService auth) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
        begin: Alignment.centerLeft, end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hello, ${auth.name.isNotEmpty ? auth.name : auth.username}! 👋',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        Text('${_data['total_medicines'] ?? 0} medicines in stock',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ])),
      const Icon(Icons.local_pharmacy, color: Colors.white38, size: 48),
    ]),
  );

  Widget _kpi(String label, String value, Color color, Color bg) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
      ]),
    ),
  );

  Widget _salesChartCard() {
    final spots = _salesChart.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), (e.value['revenue'] as num).toDouble()))
        .toList();
    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: LineChart(LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, interval: 1,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= _salesChart.length) return const SizedBox();
              return Text((_salesChart[i]['date'] as String).substring(5),
                  style: const TextStyle(fontSize: 9, color: Colors.grey));
            },
          )),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 36,
            getTitlesWidget: (v, _) => Text('₹${v.toInt()}',
                style: const TextStyle(fontSize: 9, color: Colors.grey)),
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [LineChartBarData(
          spots: spots, isCurved: true,
          color: const Color(0xFF1565C0), barWidth: 2.5,
          dotData: FlDotData(show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3, color: const Color(0xFF1565C0),
                  strokeWidth: 2, strokeColor: Colors.white)),
          belowBarData: BarAreaData(show: true,
              gradient: LinearGradient(
                colors: [const Color(0xFF1565C0).withValues(alpha: 0.15),
                         const Color(0xFF1565C0).withValues(alpha: 0.0)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              )),
        )],
      )),
    );
  }

  Widget _aiBanner() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF26A69A)],
          begin: Alignment.centerLeft, end: Alignment.centerRight),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(children: [
      const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
      const SizedBox(width: 12),
      Expanded(child: Text(
        _loss['message'] ?? 'AI models protecting your inventory',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
      )),
    ]),
  );
}

// ── Feature Card ──────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int badge;
  const _FeatureCard(this.title, this.subtitle, this.icon, this.color, this.onTap, {this.badge = 0});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8, offset: const Offset(0, 3),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          if (badge > 0) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
              child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
        const Spacer(),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF263238))),
        Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10),
            overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}
