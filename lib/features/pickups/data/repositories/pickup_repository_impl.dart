import 'package:coexist_app_portal/features/auth/domain/models/user_profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/pickup_model.dart';
import '../../domain/repositories/pickup_repository.dart';

class PickupRepositoryImpl implements PickupRepository {
  final SupabaseClient _supabaseClient;

  PickupRepositoryImpl({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  Future<List<PickupModel>> _enrichWithUserData(List<PickupModel> pickups) async {
    if (pickups.isEmpty) return pickups;

    final userIds = pickups
        .where((p) => p.userId.isNotEmpty && p.userName.isEmpty)
        .map((p) => p.userId)
        .toSet()
        .toList();

    if (userIds.isEmpty) return pickups;

    try {
      final usersResponse = await _supabaseClient
          .from('users')
          .select('id, name, mobile_number')
          .inFilter('id', userIds);

      final userMap = <String, Map<String, dynamic>>{};
      for (final user in (usersResponse as List)) {
        userMap[user['id']] = user;
      }

      return pickups.map((pickup) {
        final userData = userMap[pickup.userId];
        if (userData != null) {
          return pickup.copyWith(
            userName: pickup.userName.isEmpty ? (userData['name'] ?? '') : null,
            userPhone: pickup.userPhone.isEmpty ? (userData['mobile_number'] ?? '') : null,
          );
        }
        return pickup;
      }).toList();
    } catch (e) {
      print('Error fetching user data for pickups: $e');
      return pickups;
    }
  }

  @override
  Future<List<PickupModel>> getPickups({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _supabaseClient.from('waste_pickups').select();
    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query = query.lte('created_at', endOfDay.toIso8601String());
    }
    final response = await query.order('created_at', ascending: false);

    final pickups = (response as List)
        .map((data) => PickupModel.fromSupabase(data))
        .toList();
    return _enrichWithUserData(pickups);
  }

  @override
  Future<List<PickupModel>> getPickupsByStatus(
    PickupStatus status, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _supabaseClient
        .from('waste_pickups')
        .select()
        .eq('status', status.label);
    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query = query.lte('created_at', endOfDay.toIso8601String());
    }
    final response = await query.order('created_at', ascending: false);

    final pickups = (response as List)
        .map((data) => PickupModel.fromSupabase(data))
        .toList();
    return _enrichWithUserData(pickups);
  }

  @override
  Future<Map<PickupStatus, int>> getPickupCounts({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _supabaseClient.from('waste_pickups').select('status');
    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query = query.lte('created_at', endOfDay.toIso8601String());
    }
    final response = await query;

    final counts = <PickupStatus, int>{};
    for (final status in PickupStatus.values) {
      counts[status] = 0;
    }
    for (final row in (response as List)) {
      final status = PickupStatus.fromString(row['status'] ?? '');
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<PickupModel?> getPickupById(String pickupId) async {
    final response = await _supabaseClient
        .from('waste_pickups')
        .select()
        .eq('id', pickupId)
        .maybeSingle();

    if (response == null) return null;
    final pickup = PickupModel.fromSupabase(response);
    final enriched = await _enrichWithUserData([pickup]);
    return enriched.first;
  }

  @override
  Future<bool> acceptAndAssignPickup(
    String pickupId,
    DateTime scheduledDate,
    String scheduledTime,
    String driverId,
    String driverName,
  ) async {
    try {
      await _supabaseClient.from('waste_pickups').update({
        'scheduled_date': scheduledDate.toIso8601String(),
        'scheduled_time': scheduledTime,
        'status': PickupStatus.assigned.label,
        'assigned_to': driverId,
        'driver_id': driverId,
        'assigned_driver_name': driverName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', pickupId);
      return true;
    } catch (e) {
      print('Error accepting and assigning pickup: $e');
      return false;
    }
  }

  @override
  Future<bool> approvePickup(String pickupId) async {
    try {
      await _supabaseClient.from('waste_pickups').update({
        'status': PickupStatus.approved.label,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', pickupId);
      return true;
    } catch (e) {
      print('Error approving pickup: $e');
      return false;
    }
  }

  @override
  Future<bool> assignPickup(
    String pickupId,
    String driverId,
    String driverName,
  ) async {
    try {
      await _supabaseClient.from('waste_pickups').update({
        'status': PickupStatus.assigned.label,
        'assigned_to': driverId,
        'driver_id': driverId,
        'assigned_driver_name': driverName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', pickupId);
      return true;
    } catch (e) {
      print('Error assigning pickup: $e');
      return false;
    }
  }

  @override
  Future<bool> reschedulePickup(
    String pickupId,
    DateTime newDate,
    String newTime,
  ) async {
    try {
      final current = await getPickupById(pickupId);
      if (current == null) return false;

      await _supabaseClient.from('waste_pickups').update({
        'scheduled_date': newDate.toIso8601String(),
        'scheduled_time': newTime,
        'reschedule_count': current.rescheduleCount + 1,
        'rescheduled_at': DateTime.now().toIso8601String(),
        'status': PickupStatus.assigned.label,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', pickupId);
      return true;
    } catch (e) {
      print('Error rescheduling pickup: $e');
      return false;
    }
  }

  @override
  Future<bool> updateSchedule(
    String pickupId,
    DateTime newDate,
    String newTime,
  ) async {
    try {
      await _supabaseClient.from('waste_pickups').update({
        'scheduled_date': newDate.toIso8601String(),
        'scheduled_time': newTime,
        'status': PickupStatus.scheduled.label,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', pickupId);
      return true;
    } catch (e) {
      print('Error updating pickup schedule: $e');
      return false;
    }
  }

  @override
  Future<bool> completePickup(String pickupId) async {
    return updatePickupStatus(pickupId, PickupStatus.completed);
  }

  @override
  Future<bool> cancelPickup(String pickupId) async {
    return updatePickupStatus(pickupId, PickupStatus.cancelled);
  }

  @override
  Future<bool> updatePickupStatus(
    String pickupId,
    PickupStatus status,
  ) async {
    try {
      await _supabaseClient.from('waste_pickups').update({
        'status': status.label,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', pickupId);
      return true;
    } catch (e) {
      print('Error updating pickup status: $e');
      return false;
    }
  }

  @override
  Future<List<UserProfileModel>> getDrivers() async {
    final response = await _supabaseClient
        .from('users')
        .select()
        .eq('role', 'driver')
        .order('name', ascending: true);

    return (response as List)
        .map((data) => UserProfileModel.fromSupabase(data))
        .toList();
  }
}
