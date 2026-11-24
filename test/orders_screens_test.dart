import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:findprocurement/models/app_models.dart';
import 'package:findprocurement/screens/pesanan_detail_screen.dart';
import 'package:findprocurement/screens/pesanan_list_screen.dart';
import 'package:findprocurement/services/orders_api.dart';

void main() {
  testWidgets('lists API orders and opens live order details', (tester) async {
    final apiClient = MockClient((_) async => http.Response('{}', 200));
    final ordersApi = _FakeOrdersApi(
      client: apiClient,
      orders: const [
        Order(
          id: 'PO-API-001',
          poNumber: 'PO-API-001',
          title: 'Bekalan ujian',
          agency: 'UiTM Shah Alam',
          quantity: 5,
          amount: 125.50,
          status: 'Pesanan baharu',
        ),
      ],
    );
    final router = _createRouter(ordersApi);
    addTearDown(() {
      router.dispose();
      apiClient.close();
    });

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Bekalan ujian'), findsOneWidget);
    expect(find.text('PO-API-001'), findsOneWidget);
    expect(find.text('RM125.50'), findsOneWidget);

    await tester.tap(find.text('PO-API-001'));
    await tester.pumpAndSettle();

    expect(find.text('Agensi'), findsOneWidget);
    expect(find.text('UiTM Shah Alam'), findsOneWidget);
    expect(
      find.text('Pengesahan penerimaan pesanan belum tersedia.'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Pesanan tempatan'), findsOneWidget);
  });

  testWidgets('shows an empty state when the API has no orders',
      (tester) async {
    final apiClient = MockClient((_) async => http.Response('{}', 200));
    final ordersApi = _FakeOrdersApi(client: apiClient, orders: const []);
    final router = _createRouter(ordersApi);
    addTearDown(() {
      router.dispose();
      apiClient.close();
    });

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Tiada pesanan'), findsOneWidget);
  });
}

GoRouter _createRouter(OrdersApi ordersApi) {
  return GoRouter(
    initialLocation: '/pesanan',
    routes: [
      GoRoute(
        path: '/pesanan',
        builder: (_, __) => PesananListScreen(ordersApi: ordersApi),
      ),
      GoRoute(
        path: '/pesanan/:id',
        builder: (_, state) => PesananDetailScreen(
          orderId: state.pathParameters['id']!,
          ordersApi: ordersApi,
        ),
      ),
    ],
  );
}

class _FakeOrdersApi extends OrdersApi {
  _FakeOrdersApi({required http.Client client, required this.orders})
      : super(client: client);

  final List<Order> orders;

  @override
  Future<List<Order>> fetchOrders() async => orders;
}
