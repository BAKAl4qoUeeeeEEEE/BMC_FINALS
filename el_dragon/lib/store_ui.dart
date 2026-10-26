import 'package:flutter/material.dart';

const accent = Color(0xFFC8F560);
const surface = Color(0xFF191C22);

class ProductPhoto extends StatelessWidget {
  final Map<String, dynamic> product;
  const ProductPhoto({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final category = (product['category'] ?? '').toString().toLowerCase();
    final photo = category.contains('mouse')
        ? 'photo-1527814050087-3793815479db'
        : category.contains('keyboard')
        ? 'photo-1587829741301-dc798b83add3'
        : 'photo-1527443224154-c4a3942d3acf';
    final custom = (product['image_url'] ?? '').toString().trim();
    Widget stock() => Image.network(
      'https://images.unsplash.com/$photo?auto=format&fit=crop&w=900&q=85',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, error, stack) => Container(
        color: surface,
        alignment: Alignment.center,
        child: Icon(
          category.contains('mouse')
              ? Icons.mouse_outlined
              : category.contains('keyboard')
              ? Icons.keyboard_outlined
              : Icons.desktop_windows_outlined,
          size: 64,
          color: accent,
        ),
      ),
    );
    if (custom.isEmpty) return stock();
    return Image.network(
      custom,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, error, stack) => stock(),
    );
  }
}
