import 'package:flutter/foundation.dart';

import 'auth_api.dart';

class AuthSession extends ChangeNotifier {
  AuthSession({AuthApi? api}) : _api = api ?? AuthApi();

  static final AuthSession instance = AuthSession();

  final AuthApi _api;
  AuthCredentials? _credentials;

  bool get isAuthenticated => _credentials != null;
  AuthCredentials? get credentials => _credentials;

  Map<String, String> get authorizationHeaders {
    final token = _credentials?.token;
    return token == null ? const {} : {'Authorization': 'Bearer $token'};
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final credentials =
        await _api.login(username: username, password: password);
    _credentials = credentials;
    notifyListeners();
  }

  Future<void> logout() async {
    final token = _credentials?.token;
    if (token == null) return;

    try {
      await _api.logout(token);
    } on AuthApiException catch (error) {
      if (error.statusCode != 401) rethrow;
    }

    _credentials = null;
    notifyListeners();
  }
}
