import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'http://127.0.0.1:5001/api';

  static Map<String, String> headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── Auth ───────────────────────────────────────────────────────
  static Future<Map> register(Map data) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));
    return jsonDecode(res.body);
  }

  static Future<List> getPendingUsers(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/auth/pending-users'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  static Future<Map> approveUser(String token, int userId, String action) async {
    final res = await http.put(Uri.parse('$baseUrl/auth/approve/$userId'),
        headers: headers(token), body: jsonEncode({'action': action}));
    return jsonDecode(res.body);
  }

  // ── Dashboard ──────────────────────────────────────────────────
  static Future<Map> getDashboard(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/analytics/dashboard'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  static Future<Map> getTodayRevenue(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/billing/today-revenue'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  // ── Medicine ───────────────────────────────────────────────────
  static Future<List> getMedicines(String token, {String search = '', int page = 1, int limit = 100}) async {
    final res = await http.get(
        Uri.parse('$baseUrl/medicine/?search=$search&page=$page&limit=$limit'),
        headers: headers(token));
    final body = jsonDecode(res.body);
    return body is List ? body : (body['data'] ?? []);
  }

  static Future<Map> getMedicinesPaged(String token, {String search = '', int page = 1, int limit = 100}) async {
    final res = await http.get(
        Uri.parse('$baseUrl/medicine/?search=$search&page=$page&limit=$limit'),
        headers: headers(token));
    final body = jsonDecode(res.body);
    if (body is Map) return body;
    return {'data': body, 'total': body.length};
  }

  static Future<Map> addMedicine(String token, Map data) async {
    final res = await http.post(Uri.parse('$baseUrl/medicine/'),
        headers: headers(token), body: jsonEncode(data));
    return jsonDecode(res.body);
  }

  static Future<Map> getMedicineByBarcode(String token, String code) async {
    final res = await http.get(Uri.parse('$baseUrl/medicine/barcode/$code'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  static Future<List> getExpiringSoon(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/medicine/expiring-soon'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  static Future<List> getLowStock(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/medicine/low-stock'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  // ── Billing ────────────────────────────────────────────────────
  static Future<Map> processSale(String token, List items, String customer) async {
    final res = await http.post(Uri.parse('$baseUrl/billing/sell'),
        headers: headers(token),
        body: jsonEncode({'items': items, 'customer': customer}));
    return jsonDecode(res.body);
  }

  static Future<List> getBillingHistory(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/billing/history'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  // ── Alerts ─────────────────────────────────────────────────────
  static Future<List> getAlerts(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/alerts/'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  static Future<Map> getUnreadCount(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/alerts/unread-count'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  // ── Analytics ──────────────────────────────────────────────────
  static Future<List> getSalesChart(String token, {int days = 30}) async {
    final res = await http.get(
        Uri.parse('$baseUrl/analytics/sales-chart?days=$days'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  static Future<List> getTopMedicines(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/analytics/top-medicines'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  static Future<List> getDeadStock(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/analytics/dead-stock'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  static Future<Map> getAlternatives(String token, String medicine) async {
    final res = await http.get(
        Uri.parse('$baseUrl/analytics/alternatives?medicine=$medicine'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  // ── Predictions ────────────────────────────────────────────────
  static Future<Map> predictDemand(String token, Map data) async {
    final res = await http.post(Uri.parse('$baseUrl/predictions/demand'),
        headers: headers(token), body: jsonEncode(data));
    return jsonDecode(res.body);
  }

  static Future<Map> predictExpiryRisk(String token, Map data) async {
    final res = await http.post(Uri.parse('$baseUrl/predictions/expiry-risk'),
        headers: headers(token), body: jsonEncode(data));
    return jsonDecode(res.body);
  }

  static Future<Map> getLossPrevention(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/predictions/loss-prevention'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  // ── Staff ──────────────────────────────────────────────────────
  static Future<List> getStaff(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/staff/'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  static Future<Map> addStaff(String token, Map data) async {
    final res = await http.post(Uri.parse('$baseUrl/staff/'),
        headers: headers(token), body: jsonEncode(data));
    return jsonDecode(res.body);
  }

  static Future<Map> getStaffSummary(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/staff/summary'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  static Future<Map> checkIn(String token, int staffId) async {
    final res = await http.post(
        Uri.parse('$baseUrl/staff/attendance/checkin/$staffId'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  static Future<Map> checkOut(String token, int staffId) async {
    final res = await http.post(
        Uri.parse('$baseUrl/staff/attendance/checkout/$staffId'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  static Future<List> getAttendance(String token, int staffId) async {
    final res = await http.get(
        Uri.parse('$baseUrl/staff/attendance/$staffId'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  static Future<Map> getSalary(String token, int staffId) async {
    final res = await http.get(
        Uri.parse('$baseUrl/staff/salary/$staffId'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  static Future<Map> getGstReport(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/analytics/gst-report'),
        headers: headers(token));
    return jsonDecode(res.body);
  }

  // ── Rewards ────────────────────────────────────────────────────
  static Future<Map> getBestEmployee(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/rewards/best-employee'),
        headers: headers(token));
    return jsonDecode(res.body);
  }
}
