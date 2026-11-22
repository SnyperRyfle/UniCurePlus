import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_models.dart';
import 'auth_session.dart';

class InvoicesApiException implements Exception {
  final String message;

  const InvoicesApiException(this.message);

  @override
  String toString() => message;
}

class InvoicesApi {
  InvoicesApi({http.Client? client, AuthSession? session})
      : _client = client ?? http.Client(),
        _session = session ?? AuthSession.instance;

  static final Uri _endpoint =
      Uri.parse('http://localhost/uitm_api/invoices.php');

  final http.Client _client;
  final AuthSession _session;

  Future<List<Invoice>> fetchInvoices() async {
    late final http.Response response;
    try {
      response = await _client
          .get(
            _endpoint,
            headers: _session.authorizationHeaders,
          )
          .timeout(
            const Duration(seconds: 10),
          );
    } on TimeoutException {
      throw const InvoicesApiException(
          'Sambungan ke server mengambil masa terlalu lama.');
    } on http.ClientException {
      throw const InvoicesApiException(
        'Tidak dapat menyambung ke server invois. Pastikan Apache dan MySQL berjalan.',
      );
    }

    final decoded = _decodeResponse(response);
    if (response.statusCode != 200 || decoded['success'] != true) {
      final message = decoded['message'];
      throw InvoicesApiException(
        message is String ? message : 'Senarai invois tidak dapat dimuat.',
      );
    }

    final data = decoded['data'];
    if (data is! List) {
      throw const InvoicesApiException(
          'Senarai invois daripada server tidak sah.');
    }

    return data.map(_parseInvoice).toList(growable: false);
  }

  Future<Invoice> createInvoice({
    required String invoiceNo,
    required String orderId,
    required String date,
    required double amount,
  }) async {
    late final http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            headers: {
              'Content-Type': 'application/json',
              ..._session.authorizationHeaders,
            },
            body: jsonEncode({
              'invoice_no': invoiceNo.trim(),
              'order_id': orderId,
              'date': date,
              'amount': amount,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const InvoicesApiException(
          'Sambungan ke server mengambil masa terlalu lama.');
    } on http.ClientException {
      throw const InvoicesApiException(
        'Tidak dapat menyambung ke server invois. Pastikan Apache dan MySQL berjalan.',
      );
    }

    final decoded = _decodeResponse(response);

    if (response.statusCode != 201 || decoded['success'] != true) {
      final message = decoded['message'];
      throw InvoicesApiException(
        message is String ? message : 'Invois tidak dapat dihantar.',
      );
    }

    return _parseInvoice(decoded['data']);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    late final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const InvoicesApiException(
          'Server memulangkan jawapan yang tidak sah.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const InvoicesApiException('Format jawapan server tidak sah.');
    }
    return decoded;
  }

  Invoice _parseInvoice(dynamic data) {
    if (data is! Map<String, dynamic> ||
        data['id'] is! String ||
        data['invoice_no'] is! String ||
        data['order_ref'] is! String ||
        data['date'] is! String ||
        data['amount'] is! num ||
        data['status'] is! String) {
      throw const InvoicesApiException(
          'Maklumat invois daripada server tidak lengkap.');
    }
    return Invoice(
      id: data['id'] as String,
      invoiceNo: data['invoice_no'] as String,
      orderRef: data['order_ref'] as String,
      date: data['date'] as String,
      amount: (data['amount'] as num).toDouble(),
      status: data['status'] as String,
    );
  }
}
