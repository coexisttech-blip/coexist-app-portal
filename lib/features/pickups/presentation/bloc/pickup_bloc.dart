import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/pickup_repository.dart';
import 'pickup_event.dart';
import 'pickup_state.dart';

class PickupBloc extends Bloc<PickupEvent, PickupState> {
  final PickupRepository _pickupRepository;

  PickupBloc({required PickupRepository pickupRepository})
      : _pickupRepository = pickupRepository,
        super(const PickupInitial()) {
    on<FetchPickupsEvent>(_onFetchPickups);
    on<FetchPickupsByStatusEvent>(_onFetchPickupsByStatus);
    on<FetchPickupCountsEvent>(_onFetchPickupCounts);
    on<FetchDriversEvent>(_onFetchDrivers);
    on<AssignPickupEvent>(_onAssignPickup);
    on<ReschedulePickupEvent>(_onReschedulePickup);
    on<UpdateScheduleEvent>(_onUpdateSchedule);
    on<CompletePickupEvent>(_onCompletePickup);
    on<CancelPickupEvent>(_onCancelPickup);
  }

  Future<void> _onFetchPickups(
    FetchPickupsEvent event,
    Emitter<PickupState> emit,
  ) async {
    emit(const PickupLoading());
    try {
      final pickups = await _pickupRepository.getPickups(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(PickupsLoaded(pickups: pickups));
    } catch (e) {
      emit(PickupError(message: 'Failed to fetch pickups: ${e.toString()}'));
    }
  }

  Future<void> _onFetchPickupsByStatus(
    FetchPickupsByStatusEvent event,
    Emitter<PickupState> emit,
  ) async {
    emit(const PickupLoading());
    try {
      final pickups = await _pickupRepository.getPickupsByStatus(
        event.status,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(PickupsLoaded(pickups: pickups));
    } catch (e) {
      emit(PickupError(message: 'Failed to fetch pickups: ${e.toString()}'));
    }
  }

  Future<void> _onFetchPickupCounts(
    FetchPickupCountsEvent event,
    Emitter<PickupState> emit,
  ) async {
    try {
      final counts = await _pickupRepository.getPickupCounts(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(PickupCountsLoaded(counts: counts));
    } catch (e) {
      emit(PickupError(message: 'Failed to fetch counts: ${e.toString()}'));
    }
  }

  Future<void> _onFetchDrivers(
    FetchDriversEvent event,
    Emitter<PickupState> emit,
  ) async {
    try {
      final drivers = await _pickupRepository.getDrivers();
      emit(DriversLoaded(drivers: drivers));
    } catch (e) {
      emit(PickupError(message: 'Failed to fetch drivers: ${e.toString()}'));
    }
  }

  Future<void> _onAssignPickup(
    AssignPickupEvent event,
    Emitter<PickupState> emit,
  ) async {
    emit(const PickupLoading());
    try {
      final success = await _pickupRepository.assignPickup(
        event.pickupId,
        event.driverId,
        event.driverName,
      );
      if (success) {
        emit(const PickupActionSuccess(message: 'Pickup accepted and assigned'));
      } else {
        emit(const PickupError(message: 'Failed to accept pickup'));
      }
    } catch (e) {
      emit(PickupError(message: 'Failed to accept pickup: ${e.toString()}'));
    }
  }

  Future<void> _onReschedulePickup(
    ReschedulePickupEvent event,
    Emitter<PickupState> emit,
  ) async {
    emit(const PickupLoading());
    try {
      final success = await _pickupRepository.reschedulePickup(
        event.pickupId,
        event.newDate,
        event.newTime,
      );
      if (success) {
        emit(const PickupActionSuccess(
          message: 'Pickup rescheduled successfully',
        ));
      } else {
        emit(const PickupError(message: 'Failed to reschedule pickup'));
      }
    } catch (e) {
      emit(PickupError(
        message: 'Failed to reschedule pickup: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateSchedule(
    UpdateScheduleEvent event,
    Emitter<PickupState> emit,
  ) async {
    emit(const PickupLoading());
    try {
      final success = await _pickupRepository.updateSchedule(
        event.pickupId,
        event.newDate,
        event.newTime,
      );
      if (success) {
        emit(const PickupActionSuccess(
          message: 'Pickup date/time updated',
        ));
      } else {
        emit(const PickupError(message: 'Failed to update pickup schedule'));
      }
    } catch (e) {
      emit(PickupError(
        message: 'Failed to update pickup schedule: ${e.toString()}',
      ));
    }
  }

  Future<void> _onCompletePickup(
    CompletePickupEvent event,
    Emitter<PickupState> emit,
  ) async {
    emit(const PickupLoading());
    try {
      final success = await _pickupRepository.completePickup(event.pickupId);
      if (success) {
        emit(const PickupActionSuccess(
          message: 'Pickup marked as completed',
        ));
      } else {
        emit(const PickupError(message: 'Failed to complete pickup'));
      }
    } catch (e) {
      emit(PickupError(
        message: 'Failed to complete pickup: ${e.toString()}',
      ));
    }
  }

  Future<void> _onCancelPickup(
    CancelPickupEvent event,
    Emitter<PickupState> emit,
  ) async {
    emit(const PickupLoading());
    try {
      final success = await _pickupRepository.cancelPickup(event.pickupId);
      if (success) {
        emit(const PickupActionSuccess(message: 'Pickup cancelled'));
      } else {
        emit(const PickupError(message: 'Failed to cancel pickup'));
      }
    } catch (e) {
      emit(PickupError(
        message: 'Failed to cancel pickup: ${e.toString()}',
      ));
    }
  }
}
