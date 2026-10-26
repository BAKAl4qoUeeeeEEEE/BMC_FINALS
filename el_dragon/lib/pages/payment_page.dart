import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../store_ui.dart';

class PaymentPage extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Map<int, int> cart;

  const PaymentPage({super.key, required this.products, required this.cart});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool paying = false;

  String peso(num amount) => '₱${amount.toStringAsFixed(2)}';

  double get total {
    double result = 0;

    for (final entry in widget.cart.entries) {
      final product = widget.products.firstWhere(
        (p) => (p['id'] as num).toInt() == entry.key,
      );

      result += (product['price'] as num).toDouble() * entry.value;
    }

    return result;
  }

  Future<void> payWithXendit() async {
    if (paying || widget.cart.isEmpty) return;

    setState(() => paying = true);

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.functions.invoke(
        'create-invoice',
        body: {
          'items': widget.cart.entries.map((entry) {
            return {'product_id': entry.key, 'quantity': entry.value};
          }).toList(),
        },
      );

      final data = response.data;

      if (data is! Map || data['invoice_url'] == null) {
        throw Exception('No checkout URL returned.');
      }

      final uri = Uri.tryParse(data['invoice_url'].toString());

      if (uri == null ||
          uri.scheme != 'https' ||
          !(uri.host == 'checkout.xendit.co' ||
              uri.host.endsWith('.xendit.co'))) {
        throw Exception('Invalid Xendit checkout URL.');
      }

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened) {
        throw Exception('Unable to open the payment page.');
      }
    } catch (e) {
      if (!mounted) return;

      final errorDetails = e.toString();
      final message =
          errorDetails.contains('status: 0') ||
              errorDetails.contains('status 0')
          ? 'Hindi maabot ang Supabase checkout. Tingnan kung may internet, '
              'at kung naka-deploy ang create-invoice function. '
                'Details: $errorDetails'
          : 'Payment error: $errorDetails';
      debugPrint('Xendit checkout error: $errorDetails');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 8)),
      );
    } finally {
      if (mounted) {
        setState(() => paying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(Icons.lock_outline, size: 50, color: accent),
                SizedBox(height: 12),
                Text(
                  'Secure Checkout',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Just your gear. No account needed.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...widget.cart.entries.map((entry) {
            final product = widget.products.firstWhere(
              (p) => (p['id'] as num).toInt() == entry.key,
            );

            final price = (product['price'] as num).toDouble();

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ProductPhoto(product: product),
                ),
              ),
              title: Text(product['name'].toString()),
              subtitle: Text('Quantity: ${entry.value}'),
              trailing: Text(peso(price * entry.value)),
            );
          }),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                peso(total),
                style: const TextStyle(
                  fontSize: 23,
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Payment method',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            child: const ListTile(
              leading: Icon(
                Icons.account_balance_wallet_outlined,
                color: accent,
                size: 32,
              ),
              title: Text('Xendit'),
              subtitle: Text(
                'Available payment options depend on your Xendit setup.',
              ),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: paying ? null : payWithXendit,
              icon: paying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.payment),
              label: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  paying ? 'Preparing payment...' : 'Pay with Xendit',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'You will be redirected to Xendit to complete your payment. '
            'Your order is confirmed after payment verification.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
