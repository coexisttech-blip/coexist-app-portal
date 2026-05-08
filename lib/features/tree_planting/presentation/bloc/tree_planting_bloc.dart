import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/tree_planting_repository.dart';
import 'tree_planting_event.dart';
import 'tree_planting_state.dart';

class TreePlantingBloc extends Bloc<TreePlantingEvent, TreePlantingState> {
  final TreePlantingRepository _repository;

  TreePlantingBloc({required TreePlantingRepository repository})
      : _repository = repository,
        super(const TreePlantingInitial()) {
    on<FetchTreePriceDataEvent>(_onFetchPriceData);
    on<UpdateTreePriceEvent>(_onUpdatePrice);
    on<FetchTreeOrdersEvent>(_onFetchOrders);
  }

  Future<void> _onFetchPriceData(
    FetchTreePriceDataEvent event,
    Emitter<TreePlantingState> emit,
  ) async {
    emit(const TreePlantingLoading());
    try {
      final current = await _repository.getCurrentPrice();
      final history = await _repository.getPriceHistory();
      emit(TreePriceLoaded(current: current, history: history));
    } catch (e) {
      emit(TreePlantingError('Failed to load tree price: $e'));
    }
  }

  Future<void> _onUpdatePrice(
    UpdateTreePriceEvent event,
    Emitter<TreePlantingState> emit,
  ) async {
    try {
      final ok = await _repository.updatePrice(event.newPrice);
      if (ok) {
        emit(const TreePlantingActionSuccess('Price updated'));
      } else {
        emit(const TreePlantingError('Failed to update price'));
      }
    } catch (e) {
      emit(TreePlantingError('Failed to update price: $e'));
    }
  }

  Future<void> _onFetchOrders(
    FetchTreeOrdersEvent event,
    Emitter<TreePlantingState> emit,
  ) async {
    emit(const TreePlantingLoading());
    try {
      final orders = await _repository.getOrders(status: event.status);
      emit(TreeOrdersLoaded(orders: orders, statusFilter: event.status));
    } catch (e) {
      emit(TreePlantingError('Failed to load orders: $e'));
    }
  }
}
