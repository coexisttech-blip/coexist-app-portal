import 'package:coexist_app_portal/features/auth/domain/models/user_profile_model.dart';
import 'package:equatable/equatable.dart';

import '../../domain/models/pickup_model.dart';

abstract class PickupState extends Equatable {
  const PickupState();

  @override
  List<Object?> get props => [];
}

class PickupInitial extends PickupState {
  const PickupInitial();
}

class PickupLoading extends PickupState {
  const PickupLoading();
}

class PickupsLoaded extends PickupState {
  final List<PickupModel> pickups;

  const PickupsLoaded({required this.pickups});

  @override
  List<Object?> get props => [pickups];
}

class PickupCountsLoaded extends PickupState {
  final Map<PickupStatus, int> counts;

  const PickupCountsLoaded({required this.counts});

  int get total => counts.values.fold(0, (a, b) => a + b);

  @override
  List<Object?> get props => [counts];
}

class DriversLoaded extends PickupState {
  final List<UserProfileModel> drivers;

  const DriversLoaded({required this.drivers});

  @override
  List<Object?> get props => [drivers];
}

class PickupActionSuccess extends PickupState {
  final String message;

  const PickupActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class PickupError extends PickupState {
  final String message;

  const PickupError({required this.message});

  @override
  List<Object?> get props => [message];
}
