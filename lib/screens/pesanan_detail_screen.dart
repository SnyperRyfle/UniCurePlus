import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/app_models.dart';
import '../services/orders_api.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/common_widgets.dart';

/// V10 - Butiran pesanan (Order detail — e.g. Toner pencetak)
class PesananDetailScreen extends StatefulWidget {
  final String orderId;
  final OrdersApi? ordersApi;

  const PesananDetailScreen({
    super.key,
    required this.orderId,
    this.ordersApi,
  });

  @override
  State<PesananDetailScreen> createState() => _PesananDetailScreenState();
}

class _PesananDetailScreenState extends State<PesananDetailScreen> {
  late final OrdersApi _ordersApi;
  late Future<Order?> _orderFuture;

  @override
  void initState() {
    super.initState();
    _ordersApi = widget.ordersApi ?? OrdersApi();
    _orderFuture = _loadOrder();
  }

  Future<Order?> _loadOrder() async {
    final orders = await _ordersApi.fetchOrders();
    for (final order in orders) {
      if (order.id == widget.orderId) return order;
    }
    return null;
  }

  void _retry() {
    setState(() {
      _orderFuture = _loadOrder();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandAppBar(
        showBack: true,
        onBack: () => context.go('/pesanan'),
      ),
      body: FutureBuilder<Order?>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _LoadOrderMessage(
              message: 'Butiran pesanan tidak dapat dimuat daripada server.',
              onRetry: _retry,
            );
          }

          final order = snapshot.data;
          if (order == null) {
            return _LoadOrderMessage(
              message: 'Pesanan tidak dijumpai.',
              onRetry: () => context.go('/pesanan'),
              retryLabel: 'Kembali ke pesanan',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusPill(label: order.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                order.poNumber,
                style: const TextStyle(
                  color: AppColors.grey500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      DetailRow(label: 'Agensi', value: order.agency),
                      const Divider(),
                      DetailRow(
                        label: 'Kuantiti',
                        value: '${order.quantity} unit',
                      ),
                      const Divider(),
                      DetailRow(
                        label: 'Jumlah pesanan',
                        value: 'RM${order.amount.toStringAsFixed(2)}',
                        emphasize: true,
                      ),
                      const Divider(),
                      DetailRow(label: 'Status', value: order.status),
                    ],
                  ),
                ),
              ),
              if (order.status == 'Pesanan baharu') ...[
                const SizedBox(height: AppSpacing.lg),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'Pengesahan penerimaan pesanan belum tersedia.',
                      style: TextStyle(color: AppColors.grey500),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: () => context.go('/pesanan'),
                child: const Text('Kembali ke pesanan'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoadOrderMessage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  const _LoadOrderMessage({
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Cuba lagi',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onRetry,
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
