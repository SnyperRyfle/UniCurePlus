import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../services/invoices_api.dart';
import 'dummy_data.dart';

class InvoiceStore extends ChangeNotifier {
  InvoiceStore({InvoicesApi? api})
      : _invoices = List<Invoice>.of(DummyData.invoices),
        _api = api ?? InvoicesApi();

  static InvoiceStore instance = InvoiceStore();

  final List<Invoice> _invoices;
  final InvoicesApi _api;

  List<Invoice> get invoices => List.unmodifiable(_invoices);
  bool isLoading = false;
  String? loadError;

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

  void remove(String id) {
    _invoices.removeWhere((invoice) => invoice.id == id);
    notifyListeners();
  }

  Future<void> loadInvoices() async {
    if (isLoading) return;
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final remoteInvoices = await _api.fetchInvoices();
      final drafts = _invoices.where((invoice) => invoice.status == 'Draf');
      final localDrafts = List<Invoice>.of(drafts);
      _invoices
        ..clear()
        ..addAll(localDrafts)
        ..addAll(
          remoteInvoices.where(
            (remote) => !localDrafts.any(
              (draft) =>
                  draft.id == remote.id ||
                  draft.invoiceNo.toLowerCase() ==
                      remote.invoiceNo.toLowerCase(),
            ),
          ),
        );
    } on InvoicesApiException catch (error) {
      loadError = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
