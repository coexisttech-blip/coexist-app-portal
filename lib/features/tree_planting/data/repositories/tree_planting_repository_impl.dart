import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/tree_order_model.dart';
import '../../domain/models/tree_price_model.dart';
import '../../domain/repositories/tree_planting_repository.dart';

class TreePlantingRepositoryImpl implements TreePlantingRepository {
  final SupabaseClient _supabaseClient;

  TreePlantingRepositoryImpl({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  @override
  Future<TreePriceModel?> getCurrentPrice() async {
    final response = await _supabaseClient
        .from('tree_prices')
        .select()
        .eq('is_current', true)
        .maybeSingle();
    if (response == null) return null;
    return TreePriceModel.fromSupabase(response);
  }

  @override
  Future<List<TreePriceModel>> getPriceHistory() async {
    final response = await _supabaseClient
        .from('tree_prices')
        .select()
        .order('effective_from', ascending: false)
        .order('created_at', ascending: false);
    return (response as List)
        .map((data) => TreePriceModel.fromSupabase(data))
        .toList();
  }

  @override
  Future<bool> updatePrice(double newPrice) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final tomorrow = DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String()
          .split('T')[0];

      // Close the current row first.
      await _supabaseClient
          .from('tree_prices')
          .update({
            'is_current': false,
            'effective_to': today,
          })
          .eq('is_current', true);

      // Insert new current row.
      final inserted = await _supabaseClient
          .from('tree_prices')
          .insert({
            'price': newPrice,
            'effective_from': tomorrow,
            'is_current': true,
          })
          .select()
          .single();

      return inserted.isNotEmpty;
    } catch (e) {
      // ignore: avoid_print
      print('Error updating tree price: $e');
      return false;
    }
  }

  @override
  Future<List<TreeOrderModel>> getOrders({String? status}) async {
    // tree_planting_orders has a FK to tree_payments but NOT to public.users,
    // so we can't ask PostgREST to embed users. Fetch the orders, then look up
    // the user names/emails for the distinct user_ids in a second query.
    var query = _supabaseClient.from('tree_planting_orders').select(
        '*, tree_payments(id,razorpay_payment_id,razorpay_order_id,amount,status,verified_at)');
    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    final response = await query.order('created_at', ascending: false);
    final rows = (response as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return const [];

    final userIds =
        rows.map((r) => r['user_id']?.toString()).whereType<String>().toSet();
    final userInfo = <String, Map<String, String?>>{};
    if (userIds.isNotEmpty) {
      final usersResponse = await _supabaseClient
          .from('users')
          .select('id,name,email')
          .inFilter('id', userIds.toList());
      for (final u in (usersResponse as List)) {
        final m = u as Map<String, dynamic>;
        userInfo[m['id'].toString()] = {
          'name': m['name']?.toString(),
          'email': m['email']?.toString(),
        };
      }
    }

    return rows.map((data) {
      final uid = data['user_id']?.toString();
      final info = uid != null ? userInfo[uid] : null;
      if (info != null) {
        // Inject under the same shape the model expects from a join.
        data['users'] = {
          'name': info['name'],
          'email': info['email'],
        };
      }
      return TreeOrderModel.fromSupabase(data);
    }).toList();
  }
}
