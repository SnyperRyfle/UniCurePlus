import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/app_models.dart';
import '../services/orders_api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/common_widgets.dart';

/// V09 - Pesanan tempatan (Local orders list)
class PesananListScreen extends StatefulWidget {
  final OrdersApi? ordersApi;

  const PesananListScreen({super.key, this.ordersApi});

  @override
  State<PesananListScreen> createState() => _PesananListScreenState();
}

class _PesananListScreenState extends State<PesananListScreen> {
  late final OrdersApi _ordersApi;
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersApi = widget.ordersApi ?? OrdersApi();
    _ordersFuture = _ordersApi.fetchOrders();
  }

  void _retry() {
    setState(() {
      _ordersFuture = _ordersApi.fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandAppBar(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _LoadOrdersMessage(onRetry: _retry);
          }

          final orders = snapshot.data ?? const <Order>[];
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const Text(
                'Pesanan tempatan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Text(
                      'Tiada pesanan',
                      style: TextStyle(color: AppColors.grey500),
                    ),
                  ),
                )
              else
                ...orders.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppSpacing.radius),
                        onTap: () => context.go('/pesanan/${order.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      order.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
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
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      order.agency,
                                      style: const TextStyle(
                                        color: AppColors.grey700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'RM${order.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LoadOrdersMessage extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadOrdersMessage({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pesanan tidak dapat dimuat daripada server.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onRetry,
              child: const Text('Cuba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
