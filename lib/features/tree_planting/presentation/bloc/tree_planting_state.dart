import 'package:equatable/equatable.dart';

import '../../domain/models/tree_order_model.dart';
import '../../domain/models/tree_price_model.dart';

abstract class TreePlantingState extends Equatable {
  const TreePlantingState();
  @override
  List<Object?> get props => [];
}

class TreePlantingInitial extends TreePlantingState {
  const TreePlantingInitial();
}

class TreePlantingLoading extends TreePlantingState {
  const TreePlantingLoading();
}

class TreePriceLoaded extends TreePlantingState {
  final TreePriceModel? current;
  final List<TreePriceModel> history;
  const TreePriceLoaded({required this.current, required this.history});
  @override
  List<Object?> get props => [current, history];
}

class TreeOrdersLoaded extends TreePlantingState {
  final List<TreeOrderModel> orders;
  final String? statusFilter;
  const TreeOrdersLoaded({required this.orders, this.statusFilter});
  @override
  List<Object?> get props => [orders, statusFilter];
}

class TreePlantingActionSuccess extends TreePlantingState {
  final String message;
  const TreePlantingActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class TreePlantingError extends TreePlantingState {
  final String message;
  const TreePlantingError(this.message);
  @override
  List<Object?> get props => [message];
}
