import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/gilda_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name     = TextEditingController();
  final _email    = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _phone    = TextEditingController();
  final _pharmacy = TextEditingController();
  final _license  = TextEditingController();
  String _role = 'pharmacist';
  bool _loading = false;
  bool _obscure = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.register({
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'username': _username.text.trim(),
        'password': _password.text,
        'phone': _phone.text.trim(),
        'pharmacy_name': _pharmacy.text.trim(),
        'license_number': _license.text.trim(),
        'role': _role,
      });
      if (!mounted) return;
      if (res.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error']), backgroundColor: Colors.red));
      } else {
        final status = res['status'];
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Registration Submitted'),
            content: Text(status == 'approved'
                ? '✅ Account created! You can login now.'
                : '⏳ Registration submitted. Waiting for admin approval.'),
            actions: [TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('OK'),
            )],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection error'), backgroundColor: Colors.red));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF1565C0)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const GildaLogo(size: 80),
                const SizedBox(height: 12),
                const Text('Create Account', style: TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(children: [
                        // Role selector
                        DropdownButtonFormField<String>(
                          value: _role,
                          decoration: _dec('Register As', Icons.badge),
                          items: const [
                            DropdownMenuItem(value: 'admin',       child: Text('Owner / Admin')),
                            DropdownMenuItem(value: 'pharmacist',  child: Text('Pharmacist')),
                            DropdownMenuItem(value: 'staff',       child: Text('Staff')),
                          ],
                          onChanged: (v) => setState(() => _role = v!),
                        ),
                        const SizedBox(height: 12),
                        _field(_name,     'Full Name',       Icons.person),
                        _field(_email,    'Email',           Icons.email,    type: TextInputType.emailAddress),
                        _field(_username, 'Username',        Icons.account_circle),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: _dec('Password', Icons.lock).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                        ),
                        const SizedBox(height: 12),
                        _field(_phone,   'Phone Number',    Icons.phone,    type: TextInputType.phone),
                        _field(_pharmacy,'Pharmacy Name',   Icons.local_pharmacy),
                        _field(_license, 'License Number',  Icons.card_membership),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity, height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('REGISTER', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Already have an account? Login'),
                        ),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: _dec(label, icon),
        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    isDense: true,
  );
}
