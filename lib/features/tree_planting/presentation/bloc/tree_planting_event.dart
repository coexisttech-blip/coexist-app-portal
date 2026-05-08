import 'package:equatable/equatable.dart';

abstract class TreePlantingEvent extends Equatable {
  const TreePlantingEvent();
  @override
  List<Object?> get props => [];
}

class FetchTreePriceDataEvent extends TreePlantingEvent {
  const FetchTreePriceDataEvent();
}

class UpdateTreePriceEvent extends TreePlantingEvent {
  final double newPrice;
  const UpdateTreePriceEvent(this.newPrice);
  @override
  List<Object?> get props => [newPrice];
}

class FetchTreeOrdersEvent extends TreePlantingEvent {
  final String? status;
  const FetchTreeOrdersEvent({this.status});
  @override
  List<Object?> get props => [status];
}
