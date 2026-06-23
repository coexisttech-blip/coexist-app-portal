import 'package:equatable/equatable.dart';

// Pickup state transitions (see pickups_section.dart for UI wiring):
//
// ```mermaid
// stateDiagram-v2
//     [*] --> requested
//
//     requested --> scheduled: Schedule
//     requested --> assigned: Accept & Assign
//     requested --> cancelled: Cancel
//
//     scheduled --> approved: Approve
//     scheduled --> scheduled: Reschedule (count++)
//     scheduled --> cancelled: Cancel
//
//     approved --> assigned: Assign Driver
//     approved --> cancelled: Cancel
//
//     assigned --> completed: Complete
//     assigned --> assigned: Reschedule (count++)
//     assigned --> cancelled: Cancel
//
//     completed --> [*]
//     cancelled --> [*]
// ```
enum PickupStatus {
  requested,
  scheduled,
  approved,
  assigned,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case PickupStatus.requested:
        return 'Requested';
      case PickupStatus.scheduled:
        return 'Scheduled';
      case PickupStatus.approved:
        return 'Approved';
      case PickupStatus.assigned:
        return 'Assigned';
      case PickupStatus.completed:
        return 'Completed';
      case PickupStatus.cancelled:
        return 'Cancelled';
    }
  }

  static PickupStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'scheduled':
        return PickupStatus.scheduled;
      case 'approved':
        return PickupStatus.approved;
      case 'assigned':
        return PickupStatus.assigned;
      case 'completed':
        return PickupStatus.completed;
      case 'cancelled':
        return PickupStatus.cancelled;
      default:
        return PickupStatus.requested;
    }
  }
}

class PickupModel extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String address;
  final String? wasteType;
  final double? weight;
  final DateTime? pickupDate;
  final String timeSlot;
  final DateTime scheduledDate;
  final String scheduledTime;
  final PickupStatus status;
  final String? assignedTo;
  final String? assignedDriverName;
  final String? notes;
  final String? proofImageUrl;
  final String? proofImageUrl2;
  final int rescheduleCount;
  final DateTime? rescheduledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? categoryWeights;
  final String? rejectedMaterialImageUrl;
  final double? actualWeight;
  final String? flatNumber;
  final String? buildingName;
  final String? city;
  final String? pincode;
  final int? moneyEarned;
  final DateTime? completedAt;

  const PickupModel({
    required this.id,
    required this.userId,
    this.userName = '',
    this.userPhone = '',
    required this.address,
    this.wasteType,
    this.weight,
    this.pickupDate,
    this.timeSlot = '',
    required this.scheduledDate,
    required this.scheduledTime,
    this.status = PickupStatus.requested,
    this.assignedTo,
    this.assignedDriverName,
    this.notes,
    this.proofImageUrl,
    this.proofImageUrl2,
    this.rescheduleCount = 0,
    this.rescheduledAt,
    required this.createdAt,
    required this.updatedAt,
    this.categoryWeights,
    this.rejectedMaterialImageUrl,
    this.actualWeight,
    this.flatNumber,
    this.buildingName,
    this.city,
    this.pincode,
    this.moneyEarned,
    this.completedAt,
  });

  /// Composed full address: flat, building, address, city, pincode.
  /// Strips out empty/missing parts so we don't render leading commas.
  String get fullAddress {
    final parts = <String>[
      if (flatNumber != null && flatNumber!.trim().isNotEmpty) flatNumber!.trim(),
      if (buildingName != null && buildingName!.trim().isNotEmpty) buildingName!.trim(),
      if (address.trim().isNotEmpty) address.trim(),
      if (city != null && city!.trim().isNotEmpty) city!.trim(),
      if (pincode != null && pincode!.trim().isNotEmpty) pincode!.trim(),
    ];
    return parts.join(', ');
  }

  bool get isPending => status == PickupStatus.requested;
  bool get isScheduled => status == PickupStatus.scheduled;
  bool get isApproved => status == PickupStatus.approved;
  bool get isAssigned => status == PickupStatus.assigned;
  bool get isCompleted => status == PickupStatus.completed;
  bool get isCancelled => status == PickupStatus.cancelled;
  bool get wasRescheduled => rescheduleCount > 0;

  factory PickupModel.fromSupabase(Map<String, dynamic> data) {
    return PickupModel(
      id: data['id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      userPhone: data['user_phone'] ?? '',
      address: data['address'] ?? '',
      wasteType: data['waste_type'],
      weight: data['weight'] != null ? (data['weight'] as num).toDouble() : null,
      pickupDate: data['pickup_date'] != null
          ? DateTime.parse(data['pickup_date'].toString())
          : null,
      timeSlot: data['time_slot'] ?? '',
      scheduledDate: data['scheduled_date'] != null
          ? DateTime.parse(data['scheduled_date'].toString())
          : DateTime.now(),
      scheduledTime: data['scheduled_time'] ?? '',
      status: PickupStatus.fromString(data['status'] ?? 'requested'),
      assignedTo: data['assigned_to'],
      assignedDriverName: data['assigned_driver_name'],
      notes: data['notes'],
      proofImageUrl: data['proof_image_url'],
      proofImageUrl2: data['proof_image_url_2'],
      rescheduleCount: data['reschedule_count'] ?? 0,
      rescheduledAt: data['rescheduled_at'] != null
          ? DateTime.parse(data['rescheduled_at'].toString())
          : null,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'].toString())
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'].toString())
          : DateTime.now(),
      categoryWeights: data['category_weights'] is Map
          ? Map<String, dynamic>.from(data['category_weights'] as Map)
          : null,
      rejectedMaterialImageUrl: data['rejected_material_image_url'],
      actualWeight: data['actual_weight'] != null
          ? (data['actual_weight'] as num).toDouble()
          : null,
      flatNumber: data['flat_number'],
      buildingName: data['building_name'],
      city: data['city'],
      pincode: data['pincode'],
      moneyEarned: data['money_earned'] != null
          ? (data['money_earned'] as num).toInt()
          : null,
      completedAt: data['completed_at'] != null
          ? DateTime.parse(data['completed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_phone': userPhone,
      'address': address,
      'scheduled_date': scheduledDate.toIso8601String(),
      'scheduled_time': scheduledTime,
      'status': status.label,
      'assigned_to': assignedTo,
      'assigned_driver_name': assignedDriverName,
      'notes': notes,
      'reschedule_count': rescheduleCount,
      'rescheduled_at': rescheduledAt?.toIso8601String(),
    };
  }

  PickupModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? address,
    String? wasteType,
    double? weight,
    DateTime? pickupDate,
    String? timeSlot,
    DateTime? scheduledDate,
    String? scheduledTime,
    PickupStatus? status,
    String? assignedTo,
    String? assignedDriverName,
    String? notes,
    String? proofImageUrl,
    String? proofImageUrl2,
    int? rescheduleCount,
    DateTime? rescheduledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? categoryWeights,
    String? rejectedMaterialImageUrl,
    double? actualWeight,
    String? flatNumber,
    String? buildingName,
    String? city,
    String? pincode,
    int? moneyEarned,
    DateTime? completedAt,
  }) {
    return PickupModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      address: address ?? this.address,
      wasteType: wasteType ?? this.wasteType,
      weight: weight ?? this.weight,
      pickupDate: pickupDate ?? this.pickupDate,
      timeSlot: timeSlot ?? this.timeSlot,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      notes: notes ?? this.notes,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      proofImageUrl2: proofImageUrl2 ?? this.proofImageUrl2,
      rescheduleCount: rescheduleCount ?? this.rescheduleCount,
      rescheduledAt: rescheduledAt ?? this.rescheduledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryWeights: categoryWeights ?? this.categoryWeights,
      rejectedMaterialImageUrl:
          rejectedMaterialImageUrl ?? this.rejectedMaterialImageUrl,
      actualWeight: actualWeight ?? this.actualWeight,
      flatNumber: flatNumber ?? this.flatNumber,
      buildingName: buildingName ?? this.buildingName,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      moneyEarned: moneyEarned ?? this.moneyEarned,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userPhone,
        address,
        wasteType,
        weight,
        pickupDate,
        timeSlot,
        scheduledDate,
        scheduledTime,
        status,
        assignedTo,
        assignedDriverName,
        notes,
        proofImageUrl,
        proofImageUrl2,
        rescheduleCount,
        rescheduledAt,
        createdAt,
        updatedAt,
        categoryWeights,
        rejectedMaterialImageUrl,
        actualWeight,
        flatNumber,
        buildingName,
        city,
        pincode,
        moneyEarned,
        completedAt,
      ];
}
