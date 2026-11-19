import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_models.dart';
import '../../widgets/brand_app_bar.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/primary_button.dart';

/// V20 - Invois berjaya dihantar (Invoice submitted success)
class InvoiceSuccessScreen extends StatelessWidget {
  const InvoiceSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    if (extra is! Invoice) {
      return const Scaffold(
        body: Center(child: Text('Tiada data invois')),
      );
    }

    final invoice = extra;
    
    return Scaffold(
      appBar: const BrandAppBar(),
      body: SuccessView(
        title: 'Invois dihantar',
        subtitle: '${invoice.invoiceNo}\nInvois menunggu semakan kewangan',
        actions: [
          PrimaryButton(
            label: 'Lihat status',
            onPressed: () => context.go('/invois/${invoice.id}/status', extra: invoice),
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Kembali ke utama',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }
}
