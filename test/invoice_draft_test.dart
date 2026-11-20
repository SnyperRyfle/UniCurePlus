import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:findprocurement/data/invoice_store.dart';
import 'package:findprocurement/models/app_models.dart';
import 'package:findprocurement/screens/invoice/invoice_create_screen.dart';
import 'package:findprocurement/screens/invoice/invoice_list_screen.dart';
import 'package:findprocurement/services/invoices_api.dart';
import 'package:findprocurement/services/orders_api.dart';

void _installTestInvoiceStore() {
  final previousStore = InvoiceStore.instance;
  final client = MockClient((_) async {
    return http.Response(
      jsonEncode({
        'success': true,
        'data': [
          {
            'id': 'INV-CONTOH-018',
            'invoice_no': 'INV-CONTOH-018',
            'order_ref': 'PO-CONTOH-018',
            'date': '2026-10-14',
            'amount': 1800,
            'status': 'Dihantar',
          },
          {
            'id': 'INV-CONTOH-015',
            'invoice_no': 'INV-CONTOH-015',
            'order_ref': 'PO-CONTOH-015',
            'date': '2026-10-12',
            'amount': 2308,
            'status': 'Dibayar',
          },
        ],
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
  InvoiceStore.instance = InvoiceStore(api: InvoicesApi(client: client));
  addTearDown(() {
    client.close();
    InvoiceStore.instance = previousStore;
  });
}

OrdersApi _installTestOrdersApi() {
  final client = MockClient((_) async {
    return http.Response(
      jsonEncode({
        'success': true,
        'data': [
          {
            'id': 'PO-CONTOH-018',
            'po_number': 'PO-CONTOH-018',
            'title': 'Toner pencetak',
            'agency': 'UiTM Puncak Alam',
            'quantity': 6,
            'amount': 1800,
            'status': 'Pesanan baharu',
          },
          {
            'id': 'PO-CONTOH-015',
            'po_number': 'PO-CONTOH-015',
            'title': 'Bekalan kertas A4',
            'agency': 'UiTM Shah Alam',
            'quantity': 50,
            'amount': 2308,
            'status': 'Diterima',
          },
        ],
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
  addTearDown(client.close);
  return OrdersApi(client: client);
}

GoRouter _createTestRouter(OrdersApi ordersApi) {
  return GoRouter(
    initialLocation: '/invois',
    routes: [
      GoRoute(
        path: '/invois',
        builder: (_, __) => const InvoiceListScreen(),
      ),
      GoRoute(
        path: '/invois/baru',
        builder: (_, state) {
          final extra = state.extra;
          return InvoiceCreateScreen(
            draft: extra is Invoice ? extra : null,
            ordersApi: ordersApi,
          );
        },
      ),
    ],
  );
}

void main() {
  testWidgets(
      'prefills selected order amount and rejects duplicate invoice numbers',
      (tester) async {
    _installTestInvoiceStore();
    final router = _createTestRouter(_installTestOrdersApi());
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sediakan invois'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<Order>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PO-CONTOH-015 · Bekalan kertas A4').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      '2308.00',
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      'INV-CONTOH-018',
    );
    await tester.scrollUntilVisible(
      find.byType(CheckboxListTile),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Hantar invois'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Hantar invois'));
    await tester.pumpAndSettle();

    expect(find.text('Nombor invois ini sudah digunakan'), findsOneWidget);
  });

  testWidgets('reopens and updates an existing draft', (tester) async {
    _installTestInvoiceStore();
    const draft = Invoice(
      id: 'draft-reopen-test',
      invoiceNo: 'INV-DRAFT-REOPEN-TEST',
      orderRef: 'PO-CONTOH-015',
      date: '2026-11-18',
      amount: 123.45,
      status: 'Draf',
    );
    InvoiceStore.instance.save(draft);

    final router = _createTestRouter(_installTestOrdersApi());
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text(draft.invoiceNo));
    await tester.pumpAndSettle();

    expect(find.text('Edit draf invois'), findsOneWidget);
    expect(
      find.text('PO-CONTOH-015 · Bekalan kertas A4'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      draft.invoiceNo,
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      '123.45',
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      'INV-DRAFT-REOPEN-UPDATED',
    );
    await tester.scrollUntilVisible(
      find.text('Kemas kini draf'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kemas kini draf'));
    await tester.pumpAndSettle();

    router.go('/invois');
    await tester.pumpAndSettle();
    expect(find.text('INV-DRAFT-REOPEN-UPDATED'), findsOneWidget);
    expect(find.text(draft.invoiceNo), findsNothing);
  });
}
