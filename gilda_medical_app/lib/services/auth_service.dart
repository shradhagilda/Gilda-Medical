import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  String? _role;
  String? _username;
  String? _name;

  bool get isLoggedIn => _token != null;
  String get role     => _role ?? '';
  String get username => _username ?? '';
  String get name     => _name ?? '';
  String get token    => _token ?? '';

  static const baseUrl = 'http://127.0.0.1:5001/api';

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        _token    = data['token'];
        _role     = data['role'];
        _username = data['username'];
        _name     = data['name'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token',    _token!);
        await prefs.setString('role',     _role!);
        await prefs.setString('username', _username!);
        await prefs.setString('name',     _name ?? '');
        notifyListeners();
        return {'success': true};
      }
      return {'success': false, 'error': data['error'] ?? 'Login failed'};
    } catch (e) {
      debugPrint('Login error: $e');
      return {'success': false, 'error': 'Cannot connect to server'};
    }
  }

  Future<void> logout() async {
    _token = null; _role = null; _username = null; _name = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    _token    = prefs.getString('token');
    _role     = prefs.getString('role');
    _username = prefs.getString('username');
    _name     = prefs.getString('name');
    if (_token != null) notifyListeners();
  }
}
