import 'package:equatable/equatable.dart';

class WasteCategoryRateModel extends Equatable {
  final String id;
  final String categoryId;
  final double rate;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final bool isCurrent;
  final DateTime createdAt;

  const WasteCategoryRateModel({
    required this.id,
    required this.categoryId,
    required this.rate,
    required this.effectiveFrom,
    this.effectiveTo,
    this.isCurrent = true,
    required this.createdAt,
  });

  factory WasteCategoryRateModel.fromSupabase(Map<String, dynamic> data) {
    return WasteCategoryRateModel(
      id: data['id'] ?? '',
      categoryId: data['category_id'] ?? '',
      rate: (data['rate'] as num?)?.toDouble() ?? 0,
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
  List<Object?> get props => [
        id,
        categoryId,
        rate,
        effectiveFrom,
        effectiveTo,
        isCurrent,
        createdAt,
      ];
}
