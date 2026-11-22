import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:findprocurement/services/auth_api.dart';
import 'package:findprocurement/services/auth_session.dart';
import 'package:findprocurement/services/invoices_api.dart';
import 'package:findprocurement/services/orders_api.dart';

void main() {
  test('login stores supplier credentials and sends bearer token to orders API',
      () async {
    const token =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    final authClient = MockClient((request) async {
      expect(request.method, 'POST');
      expect(jsonDecode(request.body), {
        'username': 'supplier1',
        'password': 'password123',
      });
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'token': token,
            'user': {
              'id': 1,
              'username': 'supplier1',
              'role': 'supplier',
              'company_id': 1,
              'company_name': 'Pembekal Mantap Sdn. Bhd.',
            },
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final session = AuthSession(api: AuthApi(client: authClient));
    addTearDown(() {
      session.dispose();
      authClient.close();
    });

    await session.login(username: ' supplier1 ', password: 'password123');

    expect(session.isAuthenticated, isTrue);
    expect(session.credentials?.companyId, 1);
    expect(session.authorizationHeaders, {'Authorization': 'Bearer $token'});

    late http.Request ordersRequest;
    final ordersClient = MockClient((request) async {
      ordersRequest = request;
      return http.Response(
        jsonEncode({'success': true, 'data': []}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    addTearDown(ordersClient.close);

    await OrdersApi(client: ordersClient, session: session).fetchOrders();
    expect(
      ordersRequest.headers['Authorization'],
      'Bearer $token',
    );
  });

  test('logout revokes the token and clears the local session', () async {
    const token =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'token': token,
              'user': {
                'id': 1,
                'username': 'supplier1',
                'role': 'supplier',
                'company_id': 1,
                'company_name': 'Pembekal Mantap Sdn. Bhd.',
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      expect(request.method, 'DELETE');
      expect(request.headers['Authorization'], 'Bearer $token');
      return http.Response(
        jsonEncode({'success': true}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final session = AuthSession(api: AuthApi(client: client));
    addTearDown(() {
      session.dispose();
      client.close();
    });

    await session.login(username: 'supplier1', password: 'password123');
    await session.logout();

    expect(session.isAuthenticated, isFalse);
    expect(session.authorizationHeaders, isEmpty);
  });

  test('invoice requests include the authenticated supplier token', () async {
    const token =
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
    final authClient = MockClient((_) async {
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'token': token,
            'user': {
              'id': 1,
              'username': 'supplier1',
              'role': 'supplier',
              'company_id': 1,
              'company_name': 'Pembekal Mantap Sdn. Bhd.',
            },
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final session = AuthSession(api: AuthApi(client: authClient));
    addTearDown(() {
      session.dispose();
      authClient.close();
    });
    await session.login(username: 'supplier1', password: 'password123');

    late http.Request invoiceRequest;
    final invoicesClient = MockClient((request) async {
      invoiceRequest = request;
      return http.Response(
        jsonEncode({'success': true, 'data': []}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    addTearDown(invoicesClient.close);

    await InvoicesApi(client: invoicesClient, session: session).fetchInvoices();

    expect(invoiceRequest.headers['Authorization'], 'Bearer $token');
  });

  test('reports rejected credentials without creating a session', () async {
    final client = MockClient((_) async {
      return http.Response(
        jsonEncode({
          'success': false,
          'message': 'Invalid username or password',
        }),
        401,
        headers: {'content-type': 'application/json'},
      );
    });
    final session = AuthSession(api: AuthApi(client: client));
    addTearDown(() {
      session.dispose();
      client.close();
    });

    await expectLater(
      session.login(username: 'supplier1', password: 'wrong-password'),
      throwsA(
        isA<AuthApiException>()
            .having((error) => error.statusCode, 'statusCode', 401),
      ),
    );
    expect(session.isAuthenticated, isFalse);
  });
}
