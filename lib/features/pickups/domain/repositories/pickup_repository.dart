import 'package:coexist_app_portal/features/auth/domain/models/user_profile_model.dart';

import '../models/pickup_model.dart';

abstract class PickupRepository {
  Future<List<PickupModel>> getPickups({DateTime? startDate, DateTime? endDate});

  Future<List<PickupModel>> getPickupsByStatus(
    PickupStatus status, {
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Map<PickupStatus, int>> getPickupCounts({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<PickupModel?> getPickupById(String pickupId);

  Future<bool> approvePickup(String pickupId);

  Future<bool> acceptAndAssignPickup(
    String pickupId,
    DateTime scheduledDate,
    String scheduledTime,
    String driverId,
    String driverName,
  );

  Future<bool> assignPickup(String pickupId, String driverId, String driverName);

  Future<bool> reschedulePickup(
    String pickupId,
    DateTime newDate,
    String newTime,
  );

  Future<bool> updateSchedule(
    String pickupId,
    DateTime newDate,
    String newTime,
  );

  Future<bool> completePickup(String pickupId);

  Future<bool> cancelPickup(String pickupId);

  Future<bool> updatePickupStatus(String pickupId, PickupStatus status);

  Future<List<UserProfileModel>> getDrivers();
}
