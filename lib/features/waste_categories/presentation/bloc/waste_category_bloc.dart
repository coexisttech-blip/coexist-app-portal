import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/waste_category_repository.dart';
import 'waste_category_event.dart';
import 'waste_category_state.dart';

class WasteCategoryBloc extends Bloc<WasteCategoryEvent, WasteCategoryState> {
  final WasteCategoryRepository _repository;

  WasteCategoryBloc({required WasteCategoryRepository repository})
      : _repository = repository,
        super(const WasteCategoryInitial()) {
    on<FetchCategoriesEvent>(_onFetchCategories);
    on<FetchCategoryDetailEvent>(_onFetchCategoryDetail);
    on<FetchParentCategoriesEvent>(_onFetchParentCategories);
    on<ToggleCategoryActiveEvent>(_onToggleActive);
    on<CreateCategoryEvent>(_onCreateCategory);
    on<UpdateCategoryEvent>(_onUpdateCategory);
    on<FetchRateHistoryEvent>(_onFetchRateHistory);
    on<UpdateRateEvent>(_onUpdateRate);
    on<UpdateDisplayOrdersEvent>(_onUpdateDisplayOrders);
  }

  Future<void> _onFetchCategories(
    FetchCategoriesEvent event,
    Emitter<WasteCategoryState> emit,
  ) async {
    emit(const WasteCategoryLoading());
    try {
      final categories = await _repository.getCategories();
      emit(CategoriesLoaded(categories: categories));
    } catch (e) {
      emit(WasteCategoryError(message: 'Failed to fetch categories: $e'));
    }
  }

  Future<void> _onFetchCategoryDetail(
    FetchCategoryDetailEvent event,
    Emitter<WasteCategoryState> emit,
  ) async {
    emit(const WasteCategoryLoading());
    try {
      final category = await _repository.getCategoryById(event.categoryId);
      if (category != null) {
        emit(CategoryDetailLoaded(category: category));
      } else {
        emit(const WasteCategoryError(message: 'Category not found'));
      }
    } catch (e) {
      emit(WasteCategoryError(message: 'Failed to fetch category: $e'));
    }
  }

  Future<void> _onFetchParentCategories(
    FetchParentCategoriesEvent event,
    Emitter<WasteCategoryState> emit,
  ) async {
    try {
      final parents = await _repository.getParentCategories();
      emit(ParentCategoriesLoaded(parentCategories: parents));
    } catch (e) {
      emit(WasteCategoryError(message: 'Failed to fetch parent categories: $e'));
    }
  }

  Future<void> _onToggleActive(
    ToggleCategoryActiveEvent event,
    Emitter<WasteCategoryState> emit,
  ) async {
    try {
      final success = await _repository.toggleActive(event.categoryId, event.isActive);
      if (success) {
        emit(WasteCategoryActionSuccess(
          message: event.isActive ? 'Category activated' : 'Category deactivated',
        ));
      } else {
        emit(const WasteCategoryError(message: 'Failed to update category'));
      }
    } catch (e) {
      emit(WasteCategoryError(message: 'Failed to update category: $e'));
    }
  }

  Future<void> _onCreateCategory(
    CreateCategoryEvent event,
    Emitter<WasteCategoryState> emit,
  ) async {
    emit(const WasteCategoryLoading());
    try {
      final success = await _repository.createCategory(
        name: event.name,
        parentCategory: event.parentCategory,
        unitOfMeasure: event.unitOfMeasure,
        description: event.description,
        isActive: event.isActive,
        displayOrder: event.displayOrder,
        initialRate: event.initialRate,
        maxWeight: event.maxWeight,
      );
      if (success) {
        emit(const WasteCategoryActionSuccess(message: 'Category created'));
      } else {
        emit(const WasteCategoryError(message: 'Failed to create category'));
      }
    } catch (e) {
      emit(WasteCategoryError(message: 'Failed to create category: $e'));
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategoryEvent event,
    Emitter<WasteCategoryState> emit,
  ) async {
    emit(const WasteCategoryLoading());
    try {
      final success = await _repository.updateCategory(
        id: event.id,
        name: event.name,
        parentCategory: event.parentCategory,
        unitOfMeasure: event.unitOfMeasure,
        description: event.description,
        isActive: event.isActive,
        displayOrder: event.displayOrder,
        maxWeight: event.maxWeight,
      );
      if (success) {
        emit(const WasteCategoryActionSuccess(message: 'Category updated'));
      } else {
        emit(const WasteCategoryError(message: 'Failed to update category'));
      }
    } catch (e) {
      emit(WasteCategoryError(message: 'Failed to update category: $e'));
    }
  }

  Future<void> _onFetchRateHistory(
    FetchRateHistoryEvent event,
    Emitter<WasteCategoryState> emit,
  ) async {
    try {
      final rates = await _repository.getRateHistory(event.categoryId);
      emit(RateHistoryLoaded(rates: rates));
    } catch (e) {
      emit(WasteCategoryError(message: 'Failed to fetch rate history: $e'));
    }
  }

  Future<void> _onUpdateRate(
    UpdateRateEvent event,
    Emitter<WasteCategoryState> emit,
  ) async {
    emit(const WasteCategoryLoading());
    try {
      final success = await _repository.updateRate(
        categoryId: event.categoryId,
        newRate: event.newRate,
      );
      if (success) {
        emit(const WasteCategoryActionSuccess(message: 'Rate updated'));
      } else {
        emit(const WasteCategoryError(message: 'Failed to update rate'));
      }
    } catch (e) {
      emit(WasteCategoryError(message: 'Failed to update rate: $e'));
    }
  }

  Future<void> _onUpdateDisplayOrders(
    UpdateDisplayOrdersEvent event,
    Emitter<WasteCategoryState> emit,
  ) async {
    try {
      final success = await _repository.updateDisplayOrders(event.idToOrder);
      if (success) {
        emit(const WasteCategoryActionSuccess(message: 'Display order updated'));
      } else {
        emit(const WasteCategoryError(message: 'Failed to update display order'));
      }
    } catch (e) {
      emit(WasteCategoryError(message: 'Failed to update display order: $e'));
    }
  }
}
