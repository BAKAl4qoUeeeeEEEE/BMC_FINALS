import 'package:flutter/material.dart';

import 'payment_page.dart';
import '../store_ui.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Map<int, int> cart;

  const CartPage({super.key, required this.products, required this.cart});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Map<int, int> cart;

  @override
  void initState() {
    super.initState();
    cart = Map<int, int>.from(widget.cart);
  }

  String peso(num amount) => '₱${amount.toStringAsFixed(2)}';

  double get total {
    double result = 0;

    for (final entry in cart.entries) {
      final product = widget.products.firstWhere(
        (p) => (p['id'] as num).toInt() == entry.key,
      );

      result += (product['price'] as num).toDouble() * entry.value;
    }

    return result;
  }

  void changeQuantity(int id, int amount) {
    setState(() {
      final quantity = (cart[id] ?? 0) + amount;

      if (quantity <= 0) {
        cart.remove(id);
      } else {
        cart[id] = quantity;
      }
    });
  }

  Future<void> proceedToPayment() async {
    final updatedCart = await Navigator.push<Map<int, int>>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          products: widget.products,
          cart: Map<int, int>.from(cart),
        ),
      ),
    );

    if (updatedCart != null && mounted) {
      setState(() {
        cart = updatedCart;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, cart);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shopping Cart'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, cart),
          ),
        ),
        body: cart.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 75,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text('Your cart is empty'),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  ...cart.entries.map((entry) {
                    final product = widget.products.firstWhere(
                      (p) => (p['id'] as num).toInt() == entry.key,
                    );

                    final price = (product['price'] as num).toDouble();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 64,
                                height: 72,
                                child: ProductPhoto(product: product),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'].toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(peso(price)),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            changeQuantity(entry.key, -1),
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                      ),
                                      Text('${entry.value}'),
                                      IconButton(
                                        onPressed: () =>
                                            changeQuantity(entry.key, 1),
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              peso(price * entry.value),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        peso(total),
                        style: const TextStyle(
                          fontSize: 22,
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: proceedToPayment,
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('Continue to checkout'),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
