import 'package:equatable/equatable.dart';

import '../../domain/models/pickup_model.dart';

abstract class PickupEvent extends Equatable {
  const PickupEvent();

  @override
  List<Object?> get props => [];
}

class FetchPickupsEvent extends PickupEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const FetchPickupsEvent({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class FetchPickupsByStatusEvent extends PickupEvent {
  final PickupStatus status;
  final DateTime? startDate;
  final DateTime? endDate;

  const FetchPickupsByStatusEvent({
    required this.status,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [status, startDate, endDate];
}

class FetchPickupCountsEvent extends PickupEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const FetchPickupCountsEvent({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class FetchDriversEvent extends PickupEvent {
  const FetchDriversEvent();
}

class AssignPickupEvent extends PickupEvent {
  final String pickupId;
  final String driverId;
  final String driverName;

  const AssignPickupEvent({
    required this.pickupId,
    required this.driverId,
    required this.driverName,
  });

  @override
  List<Object?> get props => [pickupId, driverId, driverName];
}

class ReschedulePickupEvent extends PickupEvent {
  final String pickupId;
  final DateTime newDate;
  final String newTime;

  const ReschedulePickupEvent({
    required this.pickupId,
    required this.newDate,
    required this.newTime,
  });

  @override
  List<Object?> get props => [pickupId, newDate, newTime];
}

class UpdateScheduleEvent extends PickupEvent {
  final String pickupId;
  final DateTime newDate;
  final String newTime;

  const UpdateScheduleEvent({
    required this.pickupId,
    required this.newDate,
    required this.newTime,
  });

  @override
  List<Object?> get props => [pickupId, newDate, newTime];
}

class CompletePickupEvent extends PickupEvent {
  final String pickupId;

  const CompletePickupEvent({required this.pickupId});

  @override
  List<Object?> get props => [pickupId];
}

class CancelPickupEvent extends PickupEvent {
  final String pickupId;

  const CancelPickupEvent({required this.pickupId});

  @override
  List<Object?> get props => [pickupId];
}
