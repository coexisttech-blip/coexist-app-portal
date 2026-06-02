import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/waste_category_model.dart';
import '../../domain/models/waste_category_rate_model.dart';
import '../../domain/repositories/waste_category_repository.dart';

class WasteCategoryRepositoryImpl implements WasteCategoryRepository {
  final SupabaseClient _supabaseClient;

  WasteCategoryRepositoryImpl({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  @override
  Future<List<WasteCategoryModel>> getCategories() async {
    final response = await _supabaseClient
        .from('waste_categories')
        .select('*, waste_category_rates!inner(rate)')
        .eq('waste_category_rates.is_current', true)
        .order('parent_category')
        .order('display_order');

    // Also fetch categories with no rates
    final allResponse = await _supabaseClient
        .from('waste_categories')
        .select()
        .order('parent_category')
        .order('display_order');

    final withRates = <String, Map<String, dynamic>>{};
    for (final row in (response as List)) {
      withRates[row['id']] = row;
    }

    return (allResponse as List).map((data) {
      if (withRates.containsKey(data['id'])) {
        return WasteCategoryModel.fromSupabase(withRates[data['id']]!);
      }
      return WasteCategoryModel.fromSupabase(data);
    }).toList();
  }

  @override
  Future<WasteCategoryModel?> getCategoryById(String id) async {
    final response = await _supabaseClient
        .from('waste_categories')
        .select('*, waste_category_rates(rate)')
        .eq('id', id)
        .eq('waste_category_rates.is_current', true)
        .maybeSingle();

    if (response == null) return null;
    return WasteCategoryModel.fromSupabase(response);
  }

  @override
  Future<List<String>> getParentCategories() async {
    final response = await _supabaseClient
        .from('waste_categories')
        .select('parent_category')
        .order('parent_category');

    final categories = <String>{};
    for (final row in (response as List)) {
      categories.add(row['parent_category'] as String);
    }
    return categories.toList();
  }

  @override
  Future<bool> createCategory({
    required String name,
    required String parentCategory,
    required String unitOfMeasure,
    String? description,
    required bool isActive,
    required int displayOrder,
    required double initialRate,
  }) async {
    try {
      final categoryResponse = await _supabaseClient
          .from('waste_categories')
          .insert({
            'name': name,
            'parent_category': parentCategory,
            'unit_of_measure': unitOfMeasure,
            'description': description,
            'is_active': isActive,
            'display_order': displayOrder,
          })
          .select()
          .single();

      await _supabaseClient.from('waste_category_rates').insert({
        'category_id': categoryResponse['id'],
        'rate': initialRate,
        'effective_from': DateTime.now().toIso8601String().split('T')[0],
        'is_current': true,
      });

      return true;
    } catch (e) {
      print('Error creating category: $e');
      return false;
    }
  }

  @override
  Future<bool> updateCategory({
    required String id,
    required String name,
    required String parentCategory,
    required String unitOfMeasure,
    String? description,
    required bool isActive,
    required int displayOrder,
  }) async {
    try {
      await _supabaseClient.from('waste_categories').update({
        'name': name,
        'parent_category': parentCategory,
        'unit_of_measure': unitOfMeasure,
        'description': description,
        'is_active': isActive,
        'display_order': displayOrder,
      }).eq('id', id);
      return true;
    } catch (e) {
      print('Error updating category: $e');
      return false;
    }
  }

  @override
  Future<bool> toggleActive(String id, bool isActive) async {
    try {
      await _supabaseClient.from('waste_categories').update({
        'is_active': isActive,
      }).eq('id', id);
      return true;
    } catch (e) {
      print('Error toggling category active status: $e');
      return false;
    }
  }

  @override
  Future<bool> updateDisplayOrders(Map<String, int> idToOrder) async {
    try {
      for (final entry in idToOrder.entries) {
        await _supabaseClient.from('waste_categories').update({
          'display_order': entry.value,
        }).eq('id', entry.key);
      }
      return true;
    } catch (e) {
      print('Error updating display orders: $e');
      return false;
    }
  }

  @override
  Future<List<WasteCategoryRateModel>> getRateHistory(String categoryId) async {
    final response = await _supabaseClient
        .from('waste_category_rates')
        .select()
        .eq('category_id', categoryId)
        .order('effective_from', ascending: false);

    return (response as List)
        .map((data) => WasteCategoryRateModel.fromSupabase(data))
        .toList();
  }

  @override
  Future<bool> updateRate({
    required String categoryId,
    required double newRate,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final tomorrowStr = DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String()
          .split('T')[0];

      // 1. Close the current rate (if any) so only the new row is current.
      //    Filter out the future-effective row we're about to upsert.
      await _supabaseClient
          .from('waste_category_rates')
          .update({
            'effective_to': today,
            'is_current': false,
          })
          .eq('category_id', categoryId)
          .eq('is_current', true)
          .neq('effective_from', tomorrowStr);

      // 2. Upsert the new rate row keyed by (category_id, effective_from).
      //    Lets the user click Update Rate multiple times in the same day —
      //    later clicks overwrite the earlier same-day attempt instead of
      //    failing with a unique-constraint conflict.
      await _supabaseClient.from('waste_category_rates').upsert({
        'category_id': categoryId,
        'rate': newRate,
        'effective_from': tomorrowStr,
        'effective_to': null,
        'is_current': true,
      }, onConflict: 'category_id,effective_from');

      return true;
    } catch (e) {
      print('Error updating rate: $e');
      return false;
    }
  }
}
