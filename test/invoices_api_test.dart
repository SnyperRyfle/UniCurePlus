import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:findprocurement/services/invoices_api.dart';

void main() {
  test('fetches and parses saved invoices', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'success': true,
          'data': [
            {
              'id': 'API-test123',
              'invoice_no': 'INV-TEST-123',
              'order_ref': 'PO-CONTOH-015',
              'date': '2026-11-19',
              'amount': 2308,
              'status': 'Dihantar',
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    addTearDown(client.close);

    final invoices = await InvoicesApi(client: client).fetchInvoices();

    expect(capturedRequest.method, 'GET');
    expect(invoices, hasLength(1));
    expect(invoices.single.invoiceNo, 'INV-TEST-123');
    expect(invoices.single.amount, 2308);
  });

  test('posts invoice fields and parses the created invoice', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'id': 'API-test123',
            'invoice_no': 'INV-TEST-123',
            'order_ref': 'PO-CONTOH-015',
            'date': '2026-11-19',
            'amount': 2308,
            'status': 'Dihantar',
          },
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    addTearDown(client.close);

    final invoice = await InvoicesApi(client: client).createInvoice(
      invoiceNo: ' INV-TEST-123 ',
      orderId: 'PO-CONTOH-015',
      date: '2026-11-19',
      amount: 2308,
    );

    expect(capturedRequest.method, 'POST');
    expect(jsonDecode(capturedRequest.body), {
      'invoice_no': 'INV-TEST-123',
      'order_id': 'PO-CONTOH-015',
      'date': '2026-11-19',
      'amount': 2308,
    });
    expect(invoice.id, 'API-test123');
    expect(invoice.status, 'Dihantar');
  });

  test('surfaces a duplicate invoice number response', () async {
    final client = MockClient((_) async {
      return http.Response(
        jsonEncode({
          'success': false,
          'message': 'Invoice number already exists',
        }),
        409,
        headers: {'content-type': 'application/json'},
      );
    });
    addTearDown(client.close);

    expect(
      () => InvoicesApi(client: client).createInvoice(
        invoiceNo: 'INV-DUPLICATE',
        orderId: 'PO-CONTOH-015',
        date: '2026-11-19',
        amount: 100,
      ),
      throwsA(
        isA<InvoicesApiException>().having(
          (error) => error.message,
          'message',
          'Invoice number already exists',
        ),
      ),
    );
  });
}
