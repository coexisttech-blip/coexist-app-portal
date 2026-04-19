import 'package:equatable/equatable.dart';

class WasteCategoryModel extends Equatable {
  final String id;
  final String name;
  final String parentCategory;
  final String unitOfMeasure;
  final String? description;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final double? currentRate;

  const WasteCategoryModel({
    required this.id,
    required this.name,
    required this.parentCategory,
    required this.unitOfMeasure,
    this.description,
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
    this.currentRate,
  });

  String get rateDisplay {
    if (currentRate == null) return 'No rate set';
    return '\u20B9${currentRate!.toStringAsFixed(0)}/$unitOfMeasure';
  }

  factory WasteCategoryModel.fromSupabase(Map<String, dynamic> data) {
    double? rate;
    if (data['waste_category_rates'] is List &&
        (data['waste_category_rates'] as List).isNotEmpty) {
      rate = (data['waste_category_rates'][0]['rate'] as num?)?.toDouble();
    }

    return WasteCategoryModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      parentCategory: data['parent_category'] ?? '',
      unitOfMeasure: data['unit_of_measure'] ?? 'kg',
      description: data['description'],
      isActive: data['is_active'] ?? true,
      displayOrder: data['display_order'] ?? 0,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'].toString())
          : DateTime.now(),
      currentRate: rate,
    );
  }

  WasteCategoryModel copyWith({
    String? id,
    String? name,
    String? parentCategory,
    String? unitOfMeasure,
    String? description,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    double? currentRate,
  }) {
    return WasteCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentCategory: parentCategory ?? this.parentCategory,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      currentRate: currentRate ?? this.currentRate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        parentCategory,
        unitOfMeasure,
        description,
        isActive,
        displayOrder,
        createdAt,
        currentRate,
      ];
}
