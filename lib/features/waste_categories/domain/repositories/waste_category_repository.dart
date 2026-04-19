import '../models/waste_category_model.dart';
import '../models/waste_category_rate_model.dart';

abstract class WasteCategoryRepository {
  Future<List<WasteCategoryModel>> getCategories();

  Future<WasteCategoryModel?> getCategoryById(String id);

  Future<List<String>> getParentCategories();

  Future<bool> createCategory({
    required String name,
    required String parentCategory,
    required String unitOfMeasure,
    String? description,
    required bool isActive,
    required int displayOrder,
    required double initialRate,
  });

  Future<bool> updateCategory({
    required String id,
    required String name,
    required String parentCategory,
    required String unitOfMeasure,
    String? description,
    required bool isActive,
    required int displayOrder,
  });

  Future<bool> toggleActive(String id, bool isActive);

  Future<bool> updateDisplayOrders(Map<String, int> idToOrder);

  Future<List<WasteCategoryRateModel>> getRateHistory(String categoryId);

  Future<bool> updateRate({
    required String categoryId,
    required double newRate,
  });
}
