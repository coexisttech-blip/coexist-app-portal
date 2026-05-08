import '../models/tree_order_model.dart';
import '../models/tree_price_model.dart';

abstract class TreePlantingRepository {
  Future<TreePriceModel?> getCurrentPrice();
  Future<List<TreePriceModel>> getPriceHistory();

  /// Closes the current price (sets is_current = false, effective_to = today)
  /// and inserts a new row effective tomorrow with is_current = true.
  Future<bool> updatePrice(double newPrice);

  /// All orders, newest first. Optionally filter by status.
  Future<List<TreeOrderModel>> getOrders({String? status});
}
