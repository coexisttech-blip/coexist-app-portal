import 'package:equatable/equatable.dart';

class TreePriceModel extends Equatable {
  final String id;
  final double price;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final bool isCurrent;
  final DateTime createdAt;

  const TreePriceModel({
    required this.id,
    required this.price,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.isCurrent,
    required this.createdAt,
  });

  factory TreePriceModel.fromSupabase(Map<String, dynamic> data) {
    return TreePriceModel(
      id: data['id'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      effectiveFrom: DateTime.parse(data['effective_from'].toString()),
      effectiveTo: data['effective_to'] != null
          ? DateTime.parse(data['effective_to'].toString())
          : null,
      isCurrent: data['is_current'] ?? false,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'].toString())
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props =>
      [id, price, effectiveFrom, effectiveTo, isCurrent, createdAt];
}
