import 'package:coexist_app_portal/core/theme/app_colors.dart';
import 'package:coexist_app_portal/core/theme/app_text_styles.dart';
import 'package:coexist_app_portal/core/utils/date_formatter.dart';
import 'package:coexist_app_portal/features/auth/domain/models/user_profile_model.dart';
import 'package:coexist_app_portal/features/pickups/domain/models/pickup_model.dart';
import 'package:coexist_app_portal/features/pickups/presentation/bloc/pickup_bloc.dart';
import 'package:coexist_app_portal/features/pickups/presentation/bloc/pickup_event.dart';
import 'package:coexist_app_portal/features/pickups/presentation/bloc/pickup_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PickupsSection extends StatefulWidget {
  const PickupsSection({super.key});

  @override
  State<PickupsSection> createState() => _PickupsSectionState();
}

class _PickupsSectionState extends State<PickupsSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // null means "All"
  static const _tabs = <PickupStatus?>[
    null,
    PickupStatus.requested,
    PickupStatus.assigned,
    PickupStatus.completed,
    PickupStatus.cancelled,
  ];

  static const _tabLabels = [
    'All',
    'Pending',
    'Assigned',
    'Completed',
    'Cancelled',
  ];

  // Cache drivers list so we don't re-fetch on every dialog
  List<UserProfileModel> _drivers = [];

  // Date range — default: past 7 days including today
  late DateTime _startDate;
  late DateTime _endDate;

  // Counts per status
  Map<PickupStatus, int> _counts = {};
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: 1,
    );
    _tabController.addListener(_onTabChanged);

    final now = DateTime.now();
    _endDate = DateTime(now.year, now.month, now.day);
    _startDate = _endDate.subtract(const Duration(days: 6));

    _fetchCurrentTab();
    _fetchCounts();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _fetchCurrentTab();
  }

  void _fetchCurrentTab() {
    final status = _tabs[_tabController.index];
    if (status == null) {
      context.read<PickupBloc>().add(FetchPickupsEvent(
        startDate: _startDate,
        endDate: _endDate,
      ));
    } else {
      context.read<PickupBloc>().add(FetchPickupsByStatusEvent(
        status: status,
        startDate: _startDate,
        endDate: _endDate,
      ));
    }
  }

  void _fetchCounts() {
    context.read<PickupBloc>().add(FetchPickupCountsEvent(
      startDate: _startDate,
      endDate: _endDate,
    ));
  }

  void _refresh() {
    _fetchCurrentTab();
    _fetchCounts();
  }

  void _applyDateRange(DateTime start, DateTime end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
    _refresh();
  }

  String _dateRangeLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = _endDate.difference(_startDate).inDays;

    if (_endDate == today && diff == 6) return 'Last 7 days';
    if (_endDate == today && diff == 29) return 'Last 30 days';
    if (_startDate == DateTime(now.year, now.month, 1) && _endDate == today) {
      return 'This month';
    }
    return '${DateFormatter.formatDate(_startDate)} - ${DateFormatter.formatDate(_endDate)}';
  }

  void _showCustomDateRangeDialog() {
    DateTime tempStart = _startDate;
    DateTime tempEnd = _endDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Custom Date Range'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, size: 20),
                title: const Text('From', style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(
                  DateFormatter.formatDate(tempStart),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.edit, size: 16),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: tempStart,
                    firstDate: DateTime(2024),
                    lastDate: tempEnd,
                  );
                  if (date != null) {
                    setDialogState(() => tempStart = date);
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, size: 20),
                title: const Text('To', style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(
                  DateFormatter.formatDate(tempEnd),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.edit, size: 16),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: tempEnd,
                    firstDate: tempStart,
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setDialogState(() => tempEnd = date);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _applyDateRange(tempStart, tempEnd);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(PickupStatus status) {
    switch (status) {
      case PickupStatus.requested:
        return Colors.orange;
      case PickupStatus.assigned:
        return Colors.blue;
      case PickupStatus.completed:
        return AppColors.primaryGreen;
      case PickupStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _statusIcon(PickupStatus status) {
    switch (status) {
      case PickupStatus.requested:
        return Icons.schedule;
      case PickupStatus.assigned:
        return Icons.person_pin;
      case PickupStatus.completed:
        return Icons.check_circle;
      case PickupStatus.cancelled:
        return Icons.cancel;
    }
  }

  void _showAcceptDialog(BuildContext context, PickupModel pickup) {
    // Fetch drivers first, then show dialog
    final bloc = context.read<PickupBloc>();

    // Listen for DriversLoaded state
    late void Function(PickupState) listener;
    final subscription = bloc.stream.listen(null);
    listener = (state) {
      if (state is DriversLoaded) {
        subscription.cancel();
        _drivers = state.drivers;
        if (context.mounted) {
          _showAcceptDialogWithDrivers(context, pickup, state.drivers);
        }
      } else if (state is PickupError) {
        subscription.cancel();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    };
    subscription.onData(listener);

    // If we already have drivers cached, use them directly
    if (_drivers.isNotEmpty) {
      subscription.cancel();
      _showAcceptDialogWithDrivers(context, pickup, _drivers);
    } else {
      bloc.add(const FetchDriversEvent());
    }
  }

  void _showAcceptDialogWithDrivers(
    BuildContext context,
    PickupModel pickup,
    List<UserProfileModel> drivers,
  ) {
    UserProfileModel? selectedDriver;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Accept Pickup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign a driver to accept this pickup request.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutralDarkerGrey,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Driver',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserProfileModel>(
                    value: selectedDriver,
                    hint: const Text('Choose a driver...'),
                    isExpanded: true,
                    items: drivers.map((driver) {
                      return DropdownMenuItem(
                        value: driver,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primaryGreen,
                              child: Text(
                                driver.name.isNotEmpty
                                    ? driver.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    driver.name,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    driver.role,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedDriver = value);
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedDriver == null
                  ? null
                  : () {
                      context.read<PickupBloc>().add(AssignPickupEvent(
                        pickupId: pickup.id,
                        driverId: selectedDriver!.id,
                        driverName: selectedDriver!.name,
                      ));
                      Navigator.of(ctx).pop();
                    },
              child: const Text('Accept'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateDateTimeDialog(BuildContext context, PickupModel pickup) {
    DateTime selectedDate = pickup.scheduledDate;
    final timeController = TextEditingController(text: pickup.scheduledTime);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Update Date & Time'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormatter.formatDate(selectedDate)),
                trailing: const Icon(Icons.edit, size: 18),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setDialogState(() => selectedDate = date);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Time (e.g. 10:00 AM)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                context.read<PickupBloc>().add(UpdateScheduleEvent(
                  pickupId: pickup.id,
                  newDate: selectedDate,
                  newTime: timeController.text.trim(),
                ));
                Navigator.of(ctx).pop();
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context, PickupModel pickup) {
    DateTime selectedDate = pickup.scheduledDate;
    final timeController = TextEditingController(text: pickup.scheduledTime);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reschedule Pickup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormatter.formatDate(selectedDate)),
                trailing: const Icon(Icons.edit, size: 18),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setDialogState(() => selectedDate = date);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Time (e.g. 10:00 AM)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                context.read<PickupBloc>().add(ReschedulePickupEvent(
                  pickupId: pickup.id,
                  newDate: selectedDate,
                  newTime: timeController.text.trim(),
                ));
                Navigator.of(ctx).pop();
              },
              child: const Text('Reschedule'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAction(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, PickupModel pickup) {
    final actions = <Widget>[];

    switch (pickup.status) {
      case PickupStatus.requested:
        actions.add(_actionButton(
          'Accept',
          Icons.check_circle_outline,
          AppColors.primaryGreen,
          () => _showAcceptDialog(context, pickup),
        ));
        actions.add(_actionButton(
          'Update Date/Time',
          Icons.edit_calendar,
          Colors.blue,
          () => _showUpdateDateTimeDialog(context, pickup),
        ));
        actions.add(_actionButton(
          'Cancel',
          Icons.cancel_outlined,
          Colors.red,
          () => _confirmAction(
            context,
            'Cancel Pickup',
            'Are you sure you want to cancel this pickup?',
            () => context.read<PickupBloc>().add(
              CancelPickupEvent(pickupId: pickup.id),
            ),
          ),
        ));
        break;
      case PickupStatus.assigned:
        actions.add(_actionButton(
          'Complete',
          Icons.check,
          AppColors.primaryGreen,
          () => _confirmAction(
            context,
            'Complete Pickup',
            'Mark this pickup as completed?',
            () => context.read<PickupBloc>().add(
              CompletePickupEvent(pickupId: pickup.id),
            ),
          ),
        ));
        actions.add(_actionButton(
          'Reschedule',
          Icons.edit_calendar,
          Colors.orange,
          () => _showRescheduleDialog(context, pickup),
        ));
        actions.add(_actionButton(
          'Cancel',
          Icons.cancel_outlined,
          Colors.red,
          () => _confirmAction(
            context,
            'Cancel Pickup',
            'Are you sure you want to cancel this pickup?',
            () => context.read<PickupBloc>().add(
              CancelPickupEvent(pickupId: pickup.id),
            ),
          ),
        ));
        break;
      case PickupStatus.completed:
      case PickupStatus.cancelled:
        break;
    }

    return actions;
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _pickupCard(PickupModel pickup) {
    final statusColor = _statusColor(pickup.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(pickup.status),
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pickup.status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pickup.wasRescheduled) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'Rescheduled x${pickup.rescheduleCount}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  DateFormatter.formatRelativeTime(pickup.createdAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutralDarkerGrey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryGreen,
                  child: Text(
                    pickup.userName.isNotEmpty
                        ? pickup.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickup.userName.isNotEmpty
                            ? pickup.userName
                            : 'Unknown User',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (pickup.userPhone.isNotEmpty)
                        Text(
                          pickup.userPhone,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.neutralDarkerGrey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Details row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _detailItem(
                    Icons.location_on,
                    'Address',
                    pickup.address,
                  ),
                ),
                Expanded(
                  child: _detailItem(
                    Icons.calendar_today,
                    'Date',
                    DateFormatter.formatDate(pickup.scheduledDate),
                  ),
                ),
                Expanded(
                  child: _detailItem(
                    Icons.access_time,
                    'Time',
                    pickup.scheduledTime.isNotEmpty
                        ? pickup.scheduledTime
                        : '--',
                  ),
                ),
              ],
            ),

            // Assigned driver
            if (pickup.assignedDriverName != null &&
                pickup.assignedDriverName!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _detailItem(
                Icons.local_shipping,
                'Assigned Driver',
                pickup.assignedDriverName!,
              ),
            ],

            // Notes
            if (pickup.notes != null && pickup.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _detailItem(Icons.notes, 'Notes', pickup.notes!),
            ],

            // Action buttons
            if (_buildActions(context, pickup).isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                runSpacing: 4,
                children: _buildActions(context, pickup),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: AppColors.primaryGreen),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.neutralDarkerGrey,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _tabLabel(int index) {
    final label = _tabLabels[index];
    final status = _tabs[index];
    final count = status == null ? _totalCount : (_counts[status] ?? 0);
    return '$label ($count)';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with title and actions
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickups',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage waste pickup requests',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Date range dropdown
            PopupMenuButton<String>(
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                switch (value) {
                  case '7d':
                    _applyDateRange(today.subtract(const Duration(days: 6)), today);
                    break;
                  case '30d':
                    _applyDateRange(today.subtract(const Duration(days: 29)), today);
                    break;
                  case 'month':
                    _applyDateRange(DateTime(now.year, now.month, 1), today);
                    break;
                  case 'custom':
                    _showCustomDateRangeDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: '7d', child: Text('Last 7 days')),
                const PopupMenuItem(value: '30d', child: Text('Last 30 days')),
                const PopupMenuItem(value: 'month', child: Text('This month')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'custom', child: Text('Custom range...')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.date_range, size: 16, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      _dateRangeLabel(),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Refresh button
            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, color: AppColors.primaryGreen),
              tooltip: 'Refresh',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tab bar with counts
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: AppColors.neutralDarkerGrey,
            indicatorColor: AppColors.primaryGreen,
            indicatorWeight: 3,
            labelStyle: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppTextStyles.bodyMedium,
            tabAlignment: TabAlignment.start,
            tabs: List.generate(
              _tabs.length,
              (index) => Tab(text: _tabLabel(index)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Pickup list
        Expanded(
          child: BlocConsumer<PickupBloc, PickupState>(
            listener: (context, state) {
              if (state is PickupActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
                // Re-fetch current tab and counts after action
                _refresh();
              } else if (state is PickupCountsLoaded) {
                setState(() {
                  _counts = state.counts;
                  _totalCount = state.total;
                });
              } else if (state is PickupError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            buildWhen: (previous, current) =>
                current is PickupsLoaded || current is PickupLoading,
            builder: (context, state) {
              if (state is PickupLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is PickupsLoaded) {
                if (state.pickups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pickups found',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: state.pickups.length,
                  itemBuilder: (context, index) {
                    return _pickupCard(state.pickups[index]);
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
