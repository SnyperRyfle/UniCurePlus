import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:findprocurement/data/invoice_store.dart';
import 'package:findprocurement/models/app_models.dart';
import 'package:findprocurement/screens/invoice/invoice_create_screen.dart';
import 'package:findprocurement/screens/invoice/invoice_list_screen.dart';

GoRouter _createTestRouter() {
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
    final router = _createTestRouter();
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
    const draft = Invoice(
      id: 'draft-reopen-test',
      invoiceNo: 'INV-DRAFT-REOPEN-TEST',
      orderRef: 'PO-CONTOH-015',
      date: '2026-11-18',
      amount: 123.45,
      status: 'Draf',
    );
    InvoiceStore.instance.save(draft);

    final router = _createTestRouter();
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
