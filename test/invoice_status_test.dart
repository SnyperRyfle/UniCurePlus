import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:findprocurement/models/app_models.dart';
import 'package:findprocurement/screens/invoice/invoice_status_screen.dart';

void main() {
  testWidgets('shows invoice progress based on its status', (tester) async {
    final router = GoRouter(
      initialLocation: '/invois/test/status',
      routes: [
        GoRoute(
          path: '/invois/:invoiceId/status',
          builder: (_, state) => InvoiceStatusScreen(
            invoiceId: state.pathParameters['invoiceId']!,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    Invoice testInvoice(String status) => Invoice(
          id: 'test',
          invoiceNo: 'INV-TEST',
          orderRef: 'PO-TEST',
          date: '2026-11-19',
          amount: 100,
          status: status,
        );

    router.go('/invois/test/status', extra: testInvoice('Draf'));
    await tester.pumpAndSettle();
    expect(find.text('Belum dihantar'), findsOneWidget);
    expect(find.text('Menunggu penghantaran'), findsNWidgets(2));

    router.go(
      '/invois/test/status',
      extra: testInvoice('Dihantar'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dalam proses'), findsOneWidget);
    expect(find.text('Menunggu'), findsOneWidget);

    router.go(
      '/invois/test/status',
      extra: testInvoice('Dibayar'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Dibayar'), findsNWidgets(2));
  });
}
