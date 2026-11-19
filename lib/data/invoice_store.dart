import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import 'dummy_data.dart';

class InvoiceStore extends ChangeNotifier {
  InvoiceStore._() : _invoices = List<Invoice>.of(DummyData.invoices);

  static final InvoiceStore instance = InvoiceStore._();

  final List<Invoice> _invoices;

  List<Invoice> get invoices => List.unmodifiable(_invoices);

  bool invoiceNumberExists(String invoiceNo, {String? excludingId}) {
    final normalizedInvoiceNo = invoiceNo.trim().toLowerCase();
    return _invoices.any(
      (invoice) =>
          invoice.id != excludingId &&
          invoice.invoiceNo.trim().toLowerCase() == normalizedInvoiceNo,
    );
  }

  void save(Invoice invoice) {
    final index = _invoices.indexWhere((item) => item.id == invoice.id);

    if (index == -1) {
      _invoices.insert(0, invoice);
    } else {
      _invoices[index] = invoice;
    }

    notifyListeners();
  }
}
