import 'package:flutter/material.dart';

import '../services/product_service.dart';
import 'cart_page.dart';
import '../store_ui.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final ProductService service = ProductService();

  List<Map<String, dynamic>> products = [];
  final Map<int, int> cart = {};
  bool loading = true;
  String? error;
  String query = '';
  String selectedCategory = 'All gear';
  final catalogKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await service.getProducts();
      if (!mounted) return;

      setState(() {
        products = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Please check your connection and try again.';
        loading = false;
      });
    }
  }

  int get cartCount => cart.values.fold(0, (sum, quantity) => sum + quantity);

  String peso(num price) => '₱${price.toStringAsFixed(2)}';

  IconData getIcon(String category) {
    switch (category.toLowerCase()) {
      case 'monitor':
        return Icons.desktop_windows;
      case 'mouse':
        return Icons.mouse;
      case 'keyboard':
        return Icons.keyboard;
      default:
        return Icons.computer;
    }
  }

  void addToCart(Map<String, dynamic> product) {
    final id = (product['id'] as num).toInt();

    setState(() {
      cart[id] = (cart[id] ?? 0) + 1;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${product['name']} added to cart!'),
          action: SnackBarAction(label: 'View cart', onPressed: openCart),
        ),
      );
  }

  void openCart() async {
    final updatedCart = await Navigator.push<Map<int, int>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CartPage(products: products, cart: Map<int, int>.from(cart)),
      ),
    );

    if (updatedCart != null && mounted) {
      setState(() {
        cart
          ..clear()
          ..addAll(updatedCart);
      });
    }
  }

  Widget productCard(Map<String, dynamic> product) {
    final price = (product['price'] as num).toDouble();

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 165,
            width: double.infinity,
            color: surface,
            child: ProductPhoto(product: product),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['category'].toString().toUpperCase(),
                  style: const TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product['name'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product['description']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 12),
                Text(
                  peso(price),
                  style: const TextStyle(
                    fontSize: 22,
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => addToCart(product),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All gear',
      ...products.map((p) => p['category'].toString()).toSet(),
    ];
    final visibleProducts = products
        .where(
          (p) =>
              (selectedCategory == 'All gear' ||
                  p['category'] == selectedCategory) &&
              '${p['name']} ${p['description']} ${p['category']}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EL DRAGON',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3),
        ),
        actions: [
          IconButton(
            onPressed: openCart,
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadProducts,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: surface,
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1547082299-de196ea013d6?auto=format&fit=crop&w=1400&q=85',
                  ),
                  fit: BoxFit.cover,
                  opacity: 0.24,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'THE NEXT LEVEL STARTS HERE',
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your setup.\nYour advantage.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Find the gear that brings your best build to life.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Scrollable.ensureVisible(
                      catalogKey.currentContext!,
                      duration: const Duration(milliseconds: 400),
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Explore the collection'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                Text(
                  '↗ Gear for your next build',
                  style: TextStyle(color: accent),
                ),
                Text(
                  '✓ Checkout with Xendit',
                  style: TextStyle(color: Colors.white60),
                ),
                Text(
                  '✓ No account needed',
                  style: TextStyle(color: Colors.white60),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              'Find your next upgrade',
              key: catalogKey,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search your next upgrade...',
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories
                  .map(
                    (category) => ChoiceChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => selectedCategory = category),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (error != null)
              Column(
                children: [
                  const Text('Unable to load products.'),
                  Text(error!, style: const TextStyle(fontSize: 11)),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        loading = true;
                        error = null;
                      });
                      loadProducts();
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              )
            else if (visibleProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'No products found. Try another search or category.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 850
                      ? 3
                      : constraints.maxWidth >= 550
                      ? 2
                      : 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleProducts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 520,
                    ),
                    itemBuilder: (context, index) =>
                        productCard(visibleProducts[index]),
                  );
                },
              ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'EL DRAGON PC PARTS',
                style: TextStyle(
                  color: Colors.white38,
                  letterSpacing: 3,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
