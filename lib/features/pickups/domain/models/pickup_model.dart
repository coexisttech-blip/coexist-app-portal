import 'package:equatable/equatable.dart';

enum PickupStatus {
  requested,
  assigned,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case PickupStatus.requested:
        return 'Requested';
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
  final DateTime scheduledDate;
  final String scheduledTime;
  final PickupStatus status;
  final String? assignedTo;
  final String? assignedDriverName;
  final String? notes;
  final int rescheduleCount;
  final DateTime? rescheduledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PickupModel({
    required this.id,
    required this.userId,
    this.userName = '',
    this.userPhone = '',
    required this.address,
    required this.scheduledDate,
    required this.scheduledTime,
    this.status = PickupStatus.requested,
    this.assignedTo,
    this.assignedDriverName,
    this.notes,
    this.rescheduleCount = 0,
    this.rescheduledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == PickupStatus.requested;
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
      scheduledDate: data['scheduled_date'] != null
          ? DateTime.parse(data['scheduled_date'].toString())
          : DateTime.now(),
      scheduledTime: data['time_slot'] ?? data['scheduled_time'] ?? '',
      status: PickupStatus.fromString(data['status'] ?? 'requested'),
      assignedTo: data['assigned_to'],
      assignedDriverName: data['assigned_driver_name'],
      notes: data['notes'],
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
    DateTime? scheduledDate,
    String? scheduledTime,
    PickupStatus? status,
    String? assignedTo,
    String? assignedDriverName,
    String? notes,
    int? rescheduleCount,
    DateTime? rescheduledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PickupModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      address: address ?? this.address,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      notes: notes ?? this.notes,
      rescheduleCount: rescheduleCount ?? this.rescheduleCount,
      rescheduledAt: rescheduledAt ?? this.rescheduledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userPhone,
        address,
        scheduledDate,
        scheduledTime,
        status,
        assignedTo,
        assignedDriverName,
        notes,
        rescheduleCount,
        rescheduledAt,
        createdAt,
        updatedAt,
      ];
}
