import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final result = await auth.login(_userCtrl.text.trim(), _passCtrl.text.trim());
    setState(() => _loading = false);
    if (!mounted) return;
    if (result['success']) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'] ?? 'Login failed'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w > 800;

    return Scaffold(
      body: isWide ? _wideLayout() : _mobileLayout(),
    );
  }

  // ── Wide (desktop/tablet) — split layout ──────────────────────
  Widget _wideLayout() => Row(children: [
    // Left panel
    Expanded(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF42A5F5)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_pharmacy, size: 52, color: Colors.white),
          ),
          const SizedBox(height: 32),
          const Text('GILDA Medical',
              style: TextStyle(color: Colors.white, fontSize: 30,
                  fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('Smart Pharmacy Management System',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 48),
          _featureItem(Icons.inventory_2, 'Complete Inventory Management'),
          _featureItem(Icons.receipt_long, 'Smart Billing & Invoicing'),
          _featureItem(Icons.analytics, 'AI-Powered Analytics'),
          _featureItem(Icons.warning_amber, 'Expiry & Stock Alerts'),
        ]),
      ),
    ),
    // Right panel
    Expanded(child: _loginCard()),
  ]);

  Widget _featureItem(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 40),
    child: Row(children: [
      Icon(icon, color: Colors.white70, size: 18),
      const SizedBox(width: 12),
      Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
    ]),
  );

  // ── Mobile layout ─────────────────────────────────────────────
  Widget _mobileLayout() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF42A5F5)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Icon(Icons.local_pharmacy, size: 56, color: Colors.white),
            const SizedBox(height: 12),
            const Text('GILDA Medical',
                style: TextStyle(color: Colors.white, fontSize: 26,
                    fontWeight: FontWeight.w800, letterSpacing: 1)),
            const Text('Smart Pharmacy Management System',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 32),
            _loginCard(),
          ]),
        ),
      ),
    ),
  );

  // ── Login card ────────────────────────────────────────────────
  Widget _loginCard() => Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 420),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 40, offset: const Offset(0, 16)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Welcome back',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF263238))),
        const SizedBox(height: 4),
        const Text('Secure Login – Gilda Medical Management System',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 32),

        // Username
        const Text('Username', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF263238))),
        const SizedBox(height: 6),
        TextField(
          controller: _userCtrl,
          decoration: const InputDecoration(
            hintText: 'Enter username',
            prefixIcon: Icon(Icons.person_outline, size: 20),
          ),
          onSubmitted: (_) => _login(),
        ),
        const SizedBox(height: 20),

        // Password
        const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF263238))),
        const SizedBox(height: 6),
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          decoration: InputDecoration(
            hintText: 'Enter password',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          onSubmitted: (_) => _login(),
        ),
        const SizedBox(height: 28),

        // Login button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _login,
            child: _loading
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Sign In'),
          ),
        ),
        const SizedBox(height: 14),

        // Register
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RegisterScreen())),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1565C0)),
              foregroundColor: const Color(0xFF1565C0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
        const Center(child: Text('© 2025 GILDA Medical System',
            style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 11))),
      ]),
    ),
  );
}
