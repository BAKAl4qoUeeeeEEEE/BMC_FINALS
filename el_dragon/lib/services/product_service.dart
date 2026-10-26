import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getProducts() async {
    final result = await supabase
        .from('products')
        .select()
        .eq('available', true)
        .inFilter('category', ['Monitor', 'Mouse', 'Keyboard'])
        .order('id');

    return List<Map<String, dynamic>>.from(result);
  }
}
