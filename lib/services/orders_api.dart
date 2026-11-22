import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_models.dart';
import 'auth_session.dart';

class OrdersApi {
  OrdersApi({http.Client? client, AuthSession? session})
      : _client = client ?? http.Client(),
        _session = session ?? AuthSession.instance;

  static final Uri _endpoint =
      Uri.parse('http://localhost/uitm_api/orders.php');

  final http.Client _client;
  final AuthSession _session;

  Future<List<Order>> fetchOrders() async {
    final response = await _client
        .get(
          _endpoint,
          headers: _session.authorizationHeaders,
        )
        .timeout(
          const Duration(seconds: 10),
        );

    if (response.statusCode != 200) {
      throw Exception('Server returned HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      throw const FormatException('Invalid response from orders API');
    }

    final data = decoded['data'];
    if (data is! List) {
      throw const FormatException('Orders API response has no order list');
    }

    return data.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid order in API response');
      }
      return Order.fromJson(item);
    }).toList(growable: false);
  }
}
