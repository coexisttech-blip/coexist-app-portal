import 'package:equatable/equatable.dart';

abstract class WasteCategoryEvent extends Equatable {
  const WasteCategoryEvent();

  @override
  List<Object?> get props => [];
}

class FetchCategoriesEvent extends WasteCategoryEvent {
  const FetchCategoriesEvent();
}

class FetchCategoryDetailEvent extends WasteCategoryEvent {
  final String categoryId;
  const FetchCategoryDetailEvent({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

class FetchParentCategoriesEvent extends WasteCategoryEvent {
  const FetchParentCategoriesEvent();
}

class ToggleCategoryActiveEvent extends WasteCategoryEvent {
  final String categoryId;
  final bool isActive;
  final String? description;

  const ToggleCategoryActiveEvent({
    required this.categoryId,
    required this.isActive,
    this.description,
  });

  @override
  List<Object?> get props => [categoryId, isActive, description];
}

class CreateCategoryEvent extends WasteCategoryEvent {
  final String name;
  final String parentCategory;
  final String unitOfMeasure;
  final String? description;
  final bool isActive;
  final int displayOrder;
  final double initialRate;
  final double? maxWeight;

  const CreateCategoryEvent({
    required this.name,
    required this.parentCategory,
    required this.unitOfMeasure,
    this.description,
    required this.isActive,
    required this.displayOrder,
    required this.initialRate,
    this.maxWeight,
  });

  @override
  List<Object?> get props =>
      [name, parentCategory, unitOfMeasure, description, isActive, displayOrder, initialRate, maxWeight];
}

class UpdateCategoryEvent extends WasteCategoryEvent {
  final String id;
  final String name;
  final String parentCategory;
  final String unitOfMeasure;
  final String? description;
  final bool isActive;
  final int displayOrder;
  final double? maxWeight;

  const UpdateCategoryEvent({
    required this.id,
    required this.name,
    required this.parentCategory,
    required this.unitOfMeasure,
    this.description,
    required this.isActive,
    required this.displayOrder,
    this.maxWeight,
  });

  @override
  List<Object?> get props =>
      [id, name, parentCategory, unitOfMeasure, description, isActive, displayOrder, maxWeight];
}

class FetchRateHistoryEvent extends WasteCategoryEvent {
  final String categoryId;
  const FetchRateHistoryEvent({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

class UpdateRateEvent extends WasteCategoryEvent {
  final String categoryId;
  final double newRate;

  const UpdateRateEvent({required this.categoryId, required this.newRate});

  @override
  List<Object?> get props => [categoryId, newRate];
}

class UpdateDisplayOrdersEvent extends WasteCategoryEvent {
  final Map<String, int> idToOrder;

  const UpdateDisplayOrdersEvent({required this.idToOrder});

  @override
  List<Object?> get props => [idToOrder];
}
