import 'package:equatable/equatable.dart';

import '../../domain/models/waste_category_model.dart';
import '../../domain/models/waste_category_rate_model.dart';

abstract class WasteCategoryState extends Equatable {
  const WasteCategoryState();

  @override
  List<Object?> get props => [];
}

class WasteCategoryInitial extends WasteCategoryState {
  const WasteCategoryInitial();
}

class WasteCategoryLoading extends WasteCategoryState {
  const WasteCategoryLoading();
}

class CategoriesLoaded extends WasteCategoryState {
  final List<WasteCategoryModel> categories;

  const CategoriesLoaded({required this.categories});

  @override
  List<Object?> get props => [categories];
}

class CategoryDetailLoaded extends WasteCategoryState {
  final WasteCategoryModel category;

  const CategoryDetailLoaded({required this.category});

  @override
  List<Object?> get props => [category];
}

class ParentCategoriesLoaded extends WasteCategoryState {
  final List<String> parentCategories;

  const ParentCategoriesLoaded({required this.parentCategories});

  @override
  List<Object?> get props => [parentCategories];
}

class RateHistoryLoaded extends WasteCategoryState {
  final List<WasteCategoryRateModel> rates;

  const RateHistoryLoaded({required this.rates});

  @override
  List<Object?> get props => [rates];
}

class WasteCategoryActionSuccess extends WasteCategoryState {
  final String message;

  const WasteCategoryActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class WasteCategoryError extends WasteCategoryState {
  final String message;

  const WasteCategoryError({required this.message});

  @override
  List<Object?> get props => [message];
}
