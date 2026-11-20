import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_app_bar.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/primary_button.dart';
import '../../models/app_models.dart';
import '../../data/invoice_store.dart';
import '../../services/orders_api.dart';
import '../../services/invoices_api.dart';

/// V12 - Penyediaan invois (Create invoice)
class InvoiceCreateScreen extends StatefulWidget {
  final Invoice? draft;
  final OrdersApi? ordersApi;

  const InvoiceCreateScreen({super.key, this.draft, this.ordersApi});

  @override
  State<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends State<InvoiceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  Order? _selectedOrder;
  late Future<List<Order>> _ordersFuture;
  late final TextEditingController _noCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _amountCtrl;
  bool _confirm = false;
  bool _isSubmitting = false;
  String? _invoiceId;
  late final OrdersApi _ordersApi;

  @override
  void initState() {
    super.initState();

    final draft = widget.draft;
    _noCtrl = TextEditingController(text: draft?.invoiceNo ?? '');
    _dateCtrl = TextEditingController(text: draft?.date ?? '2026-10-14');
    _amountCtrl = TextEditingController(
      text: draft?.amount.toStringAsFixed(2) ?? '',
    );
    _invoiceId = draft?.id;
    _ordersApi = widget.ordersApi ?? OrdersApi();
    _ordersFuture = _loadOrders();
  }

  Future<List<Order>> _loadOrders() async {
    final orders = await _ordersApi.fetchOrders();
    final draftOrderRef = widget.draft?.orderRef;
    if (draftOrderRef != null) {
      for (final order in orders) {
        if (order.poNumber == draftOrderRef) {
          _selectedOrder = order;
          break;
        }
      }
    }
    return orders;
  }

  @override
  void dispose() {
    _noCtrl.dispose();
    _dateCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  String? _validateInvoiceNumber(String? value) {
    final invoiceNo = value?.trim() ?? '';
    if (invoiceNo.isEmpty) {
      return 'Masukkan nombor invois';
    }
    if (InvoiceStore.instance.invoiceNumberExists(
      invoiceNo,
      excludingId: _invoiceId,
    )) {
      return 'Nombor invois ini sudah digunakan';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null || !amount.isFinite || amount <= 0) {
      return 'Masukkan jumlah yang sah melebihi RM0.00';
    }
    final order = _selectedOrder;
    if (order != null && amount > order.amount) {
      return 'Jumlah invois tidak boleh melebihi jumlah pesanan';
    }
    return null;
  }

  Future<void> _pickInvoiceDate() async {
    final initialDate = DateTime.tryParse(_dateCtrl.text) ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      _dateCtrl.text = pickedDate.toIso8601String().split('T').first;
    }
  }

  void _saveDraft() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final order = _selectedOrder;
    if (order == null) return;

    _invoiceId ??= DateTime.now().microsecondsSinceEpoch.toString();
    final invoice = Invoice(
      id: _invoiceId!,
      invoiceNo: _noCtrl.text.trim(),
      orderRef: order.poNumber,
      date: _dateCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.trim()),
      status: 'Draf',
    );
    InvoiceStore.instance.save(invoice);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draf invois disimpan untuk sesi ini')),
    );
  }

  Future<void> _submitInvoice() async {
    final order = _selectedOrder;
    if (order == null || !(_formKey.currentState?.validate() ?? false)) {
      _formKey.currentState?.validate();
      return;
    }
    if (!_confirm || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final invoice = await InvoicesApi().createInvoice(
        invoiceNo: _noCtrl.text,
        orderId: order.id,
        date: _dateCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text.trim()),
      );

      final store = InvoiceStore.instance;
      final draftId = _invoiceId;
      if (draftId != null && draftId != invoice.id) {
        store.remove(draftId);
      }
      store.save(invoice);

      if (!mounted) return;
      context.go('/invois/berjaya', extra: invoice);
    } on InvoicesApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandAppBar(showBack: true, onBack: () => context.go('/invois')),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Tidak dapat memuat pesanan daripada server.'),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _ordersFuture = _loadOrders();
                        });
                      },
                      child: const Text('Cuba lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final orders = snapshot.data ?? const <Order>[];
          if (orders.isEmpty) {
            return const Center(child: Text('Tiada pesanan tersedia.'));
          }
          final selectedOrder = _selectedOrder;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                    widget.draft == null
                        ? 'Sediakan invois'
                        : 'Edit draf invois',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: AppSpacing.xs),
                const Text('Pilih pesanan untuk disediakan invois',
                    style: TextStyle(color: AppColors.grey500, fontSize: 13)),
                const SizedBox(height: AppSpacing.lg),
                LabeledField(
                  label: 'Pesanan',
                  child: DropdownButtonFormField<Order>(
                    initialValue: _selectedOrder,
                    decoration:
                        const InputDecoration(hintText: 'Pilih pesanan'),
                    items: orders.map((order) {
                      return DropdownMenuItem<Order>(
                        value: order,
                        child: Text('${order.poNumber} · ${order.title}'),
                      );
                    }).toList(),
                    validator: (order) =>
                        order == null ? 'Pilih pesanan untuk invois ini' : null,
                    onChanged: (order) {
                      setState(() {
                        _selectedOrder = order;
                        if (order != null) {
                          _amountCtrl.text = order.amount.toStringAsFixed(2);
                        }
                      });
                    },
                  ),
                ),
                if (selectedOrder != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          DetailRow(
                              label: 'Pesanan', value: selectedOrder.poNumber),
                          const Divider(),
                          DetailRow(label: 'Item', value: selectedOrder.title),
                          const Divider(),
                          DetailRow(
                            label: 'Kuantiti',
                            value: '${selectedOrder.quantity} unit',
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                LabeledField(
                  label: 'No. invois',
                  child: TextFormField(
                    controller: _noCtrl,
                    validator: _validateInvoiceNumber,
                  ),
                ),
                LabeledField(
                  label: 'Tarikh invois',
                  child: TextField(
                    controller: _dateCtrl,
                    readOnly: true,
                    onTap: _pickInvoiceDate,
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                    ),
                  ),
                ),
                LabeledField(
                  label: 'Jumlah invois (RM)',
                  child: TextFormField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: _validateAmount,
                  ),
                ),
                CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  value: _confirm,
                  onChanged: (v) => setState(() => _confirm = v ?? false),
                  title: const Text(
                    'Saya mengesahkan maklumat invois ini betul dan tepat.',
                    style: TextStyle(fontSize: 12, color: AppColors.grey700),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Hantar invois',
                  onPressed: _confirm && !_isSubmitting ? _submitInvoice : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                SecondaryButton(
                  label:
                      widget.draft == null ? 'Simpan draf' : 'Kemas kini draf',
                  onPressed: _saveDraft,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
