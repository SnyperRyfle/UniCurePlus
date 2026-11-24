// Use http://192.168.0.25/uitm_api/auth.php when testing on physical mobile devices
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthCredentials {
  const AuthCredentials({
    required this.token,
    required this.userId,
    required this.username,
    required this.companyId,
    required this.companyName,
  });

  final String token;
  final int userId;
  final String username;
  final int companyId;
  final String companyName;
}

class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _endpoint = Uri.parse('http://localhost/uitm_api/auth.php');

  final http.Client _client;

  Future<AuthCredentials> login({
    required String username,
    required String password,
  }) async {
    late final http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const AuthApiException(
        'Sambungan ke server mengambil masa terlalu lama.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'Tidak dapat menyambung ke server. Pastikan Apache dan MySQL berjalan.',
      );
    }

    final decoded = _decodeResponse(response);
    if (response.statusCode != 200 || decoded['success'] != true) {
      final message = decoded['message'];
      throw AuthApiException(
        message is String ? message : 'Log masuk tidak berjaya.',
        statusCode: response.statusCode,
      );
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthApiException(
          'Maklumat log masuk daripada server tidak sah.');
    }

    final user = data['user'];
    if (data['token'] is! String ||
        !RegExp(r'^[a-f0-9]{64}$', caseSensitive: false)
            .hasMatch(data['token'] as String) ||
        user is! Map<String, dynamic> ||
        user['id'] is! num ||
        user['username'] is! String ||
        user['role'] != 'supplier' ||
        user['company_id'] is! num ||
        user['company_name'] is! String) {
      throw const AuthApiException(
          'Maklumat akaun daripada server tidak lengkap.');
    }

    return AuthCredentials(
      token: data['token'] as String,
      userId: (user['id'] as num).toInt(),
      username: user['username'] as String,
      companyId: (user['company_id'] as num).toInt(),
      companyName: user['company_name'] as String,
    );
  }

  Future<void> logout(String token) async {
    late final http.Response response;
    try {
      response = await _client.delete(
        _endpoint,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const AuthApiException(
        'Sambungan ke server mengambil masa terlalu lama.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'Tidak dapat menyambung ke server untuk log keluar.',
      );
    }

    final decoded = _decodeResponse(response);
    if (response.statusCode != 200 || decoded['success'] != true) {
      final message = decoded['message'];
      throw AuthApiException(
        message is String ? message : 'Log keluar tidak berjaya.',
        statusCode: response.statusCode,
      );
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    late final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const AuthApiException(
          'Server memulangkan jawapan yang tidak sah.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const AuthApiException('Format jawapan server tidak sah.');
    }
    return decoded;
  }
}
