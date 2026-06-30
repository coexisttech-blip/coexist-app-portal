import 'dart:html' as html;
import 'package:coexist_app_portal/core/theme/app_colors.dart';
import 'package:coexist_app_portal/core/theme/app_text_styles.dart';
import 'package:coexist_app_portal/core/utils/date_formatter.dart';
import 'package:coexist_app_portal/features/auth/domain/models/user_profile_model.dart';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersSection extends StatefulWidget {
  const UsersSection({super.key});

  @override
  State<UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends State<UsersSection> {
  List<UserProfileModel> _allUsers = [];
  List<UserProfileModel> _filteredUsers = [];
  bool _loading = true;

  // Per-user aggregates fetched alongside the users list
  bool _exporting = false;
  Map<String, int> _addressCounts = {};
  // Customer-side aggregates (keyed by user_id of the requester)
  Map<String, int> _pickupCounts = {};
  Map<String, DateTime?> _lastPickupDate = {};
  // Driver-side aggregates (keyed by driver_id)
  Map<String, int> _driverAssignedCounts = {};
  Map<String, int> _driverCompletedCounts = {};
  Map<String, DateTime?> _lastDriverAssignedDate = {};
  // Wallet aggregates from user_tokens (keyed by user_id)
  Map<String, int> _walletBalance = {};
  Map<String, int> _lifetimeEarnings = {};
  String _searchQuery = '';
  String _selectedRole = 'All';
  final _searchController = TextEditingController();

  // Sorting — joined | wallet | lifetime | pickups
  String _sortBy = 'joined';
  bool _sortAsc = false; // default: joined newest-first (descending)

  static const _roles = ['All', 'admin', 'user', 'volunteer', 'driver'];
  static const _sortLabels = {
    'joined': 'Joined date',
    'wallet': 'Wallet balance',
    'lifetime': 'Lifetime earnings',
    'pickups': 'Pickups requested',
  };

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      // Run the three queries in parallel
      final results = await Future.wait([
        supabase.from('users').select().order('joined_at', ascending: false),
        supabase.from('saved_addresses').select('user_id'),
        supabase
            .from('waste_pickups')
            .select('user_id, driver_id, status, created_at'),
        supabase.from('user_tokens').select('user_id, balance, lifetime_balance'),
      ]);

      final users = (results[0] as List)
          .map((data) => UserProfileModel.fromSupabase(data))
          .toList();

      // Aggregate addresses per user
      final addressCounts = <String, int>{};
      for (final row in (results[1] as List)) {
        final uid = (row as Map)['user_id']?.toString();
        if (uid == null) continue;
        addressCounts[uid] = (addressCounts[uid] ?? 0) + 1;
      }

      // Aggregate pickups — two sides:
      //  - Customer side: pickups they requested (keyed by user_id)
      //  - Driver side: pickups assigned to them (keyed by driver_id)
      final pickupCounts = <String, int>{};
      final lastPickupDate = <String, DateTime?>{};
      final driverAssignedCounts = <String, int>{};
      final driverCompletedCounts = <String, int>{};
      final lastDriverAssignedDate = <String, DateTime?>{};
      for (final row in (results[2] as List)) {
        final m = row as Map;
        final createdRaw = m['created_at']?.toString();
        final created = createdRaw != null ? DateTime.tryParse(createdRaw) : null;

        // Customer-side
        final uid = m['user_id']?.toString();
        if (uid != null) {
          pickupCounts[uid] = (pickupCounts[uid] ?? 0) + 1;
          if (created != null) {
            final existing = lastPickupDate[uid];
            if (existing == null || created.isAfter(existing)) {
              lastPickupDate[uid] = created;
            }
          }
        }

        // Driver-side
        final did = m['driver_id']?.toString();
        if (did != null) {
          driverAssignedCounts[did] = (driverAssignedCounts[did] ?? 0) + 1;
          if (m['status']?.toString() == 'Completed') {
            driverCompletedCounts[did] = (driverCompletedCounts[did] ?? 0) + 1;
          }
          if (created != null) {
            final existing = lastDriverAssignedDate[did];
            if (existing == null || created.isAfter(existing)) {
              lastDriverAssignedDate[did] = created;
            }
          }
        }
      }

      // Aggregate wallet balances per user from user_tokens
      final walletBalance = <String, int>{};
      final lifetimeEarnings = <String, int>{};
      for (final row in (results[3] as List)) {
        final m = row as Map;
        final uid = m['user_id']?.toString();
        if (uid == null) continue;
        walletBalance[uid] = (m['balance'] as num?)?.toInt() ?? 0;
        lifetimeEarnings[uid] = (m['lifetime_balance'] as num?)?.toInt() ?? 0;
      }

      if (!mounted) return;
      setState(() {
        _allUsers = users;
        _addressCounts = addressCounts;
        _pickupCounts = pickupCounts;
        _lastPickupDate = lastPickupDate;
        _driverAssignedCounts = driverAssignedCounts;
        _driverCompletedCounts = driverCompletedCounts;
        _lastDriverAssignedDate = lastDriverAssignedDate;
        _walletBalance = walletBalance;
        _lifetimeEarnings = lifetimeEarnings;
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _allUsers = [];
        _filteredUsers = [];
        _addressCounts = {};
        _pickupCounts = {};
        _lastPickupDate = {};
        _driverAssignedCounts = {};
        _driverCompletedCounts = {};
        _lastDriverAssignedDate = {};
        _walletBalance = {};
        _lifetimeEarnings = {};
        _loading = false;
      });
    }
  }

  Widget _buildUserStatsLine(UserProfileModel user,
      {bool showPickupCount = true}) {
    final addresses = _addressCounts[user.id] ?? 0;
    final parts = <String>[
      '$addresses ${addresses == 1 ? 'address' : 'addresses'}',
    ];

    if (user.role.toLowerCase() == 'driver') {
      final assigned = _driverAssignedCounts[user.id] ?? 0;
      final completed = _driverCompletedCounts[user.id] ?? 0;
      final lastAssigned = _lastDriverAssignedDate[user.id];
      parts.add('$assigned ${assigned == 1 ? 'job' : 'jobs'} assigned');
      parts.add('$completed completed');
      parts.add(lastAssigned != null
          ? 'Last job: ${DateFormatter.formatDate(lastAssigned)}'
          : 'No jobs yet');
    } else {
      final pickups = _pickupCounts[user.id] ?? 0;
      final lastPickup = _lastPickupDate[user.id];
      if (showPickupCount) {
        parts.add('$pickups ${pickups == 1 ? 'pickup' : 'pickups'} requested');
        parts.add(lastPickup != null
            ? 'Last requested: ${DateFormatter.formatDate(lastPickup)}'
            : 'No pickups yet');
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        parts.join('  ·  '),
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primaryDarkGreen,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _applyFilters() {
    var filtered = _allUsers;

    if (_selectedRole != 'All') {
      filtered = filtered.where((u) => u.role == _selectedRole).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((u) {
        return u.name.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query) ||
            (u.mobileNumber?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Copy before sorting so we never mutate _allUsers in place.
    final sorted = List<UserProfileModel>.of(filtered);
    final dir = _sortAsc ? 1 : -1;
    sorted.sort((a, b) {
      switch (_sortBy) {
        case 'wallet':
          return dir *
              (_walletBalance[a.id] ?? 0).compareTo(_walletBalance[b.id] ?? 0);
        case 'lifetime':
          return dir *
              (_lifetimeEarnings[a.id] ?? 0)
                  .compareTo(_lifetimeEarnings[b.id] ?? 0);
        case 'pickups':
          return dir *
              (_pickupCounts[a.id] ?? 0).compareTo(_pickupCounts[b.id] ?? 0);
        case 'joined':
        default:
          return dir * a.joinedAt.compareTo(b.joinedAt);
      }
    });

    _filteredUsers = sorted;
  }

  void _onSortByChanged(String value) {
    setState(() {
      _sortBy = value;
      _applyFilters();
    });
  }

  void _toggleSortDirection() {
    setState(() {
      _sortAsc = !_sortAsc;
      _applyFilters();
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilters();
    });
  }

  void _onRoleChanged(String role) {
    setState(() {
      _selectedRole = role;
      _applyFilters();
    });
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'volunteer':
        return AppColors.primaryGreen;
      case 'driver':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Future<void> _exportToExcel() async {
    setState(() => _exporting = true);
    try {
      // Export the currently filtered list so admins get exactly what they see.
      final rows = _filteredUsers;

      final excel = xl.Excel.createExcel();
      excel.rename('Sheet1', 'Users');
      final sheet = excel['Users'];

      final headers = <String>[
        'User ID',
        'Name',
        'Email',
        'Mobile',
        'Role',
        'Joined',
        'Addresses Saved',
        'Pickups Requested',
        'Last Requested',
        'Jobs Assigned (driver)',
        'Jobs Completed (driver)',
        'Last Job (driver)',
        'Wallet Balance (coins)',
        'Lifetime Earnings (coins)',
      ];
      sheet.appendRow(headers.map<xl.CellValue?>((h) => xl.TextCellValue(h)).toList());

      // Bold + light-green header row
      final headerStyle = xl.CellStyle(
        bold: true,
        backgroundColorHex: xl.ExcelColor.fromHexString('#E9F1EC'),
        horizontalAlign: xl.HorizontalAlign.Center,
      );
      for (var col = 0; col < headers.length; col++) {
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
            .cellStyle = headerStyle;
      }

      final isoFmt = DateFormat('dd MMM yyyy');

      for (final u in rows) {
        final isDriver = u.role.toLowerCase() == 'driver';
        final lastReq = _lastPickupDate[u.id];
        final lastJob = _lastDriverAssignedDate[u.id];
        sheet.appendRow(<xl.CellValue?>[
          xl.TextCellValue(u.id),
          xl.TextCellValue(u.name),
          xl.TextCellValue(u.email),
          xl.TextCellValue(u.mobileNumber ?? ''),
          xl.TextCellValue(u.role),
          xl.TextCellValue(isoFmt.format(u.joinedAt)),
          xl.IntCellValue(_addressCounts[u.id] ?? 0),
          xl.IntCellValue(_pickupCounts[u.id] ?? 0),
          lastReq != null ? xl.TextCellValue(isoFmt.format(lastReq)) : null,
          // Driver-side: leave blank for non-drivers so columns aren't misread
          isDriver ? xl.IntCellValue(_driverAssignedCounts[u.id] ?? 0) : null,
          isDriver ? xl.IntCellValue(_driverCompletedCounts[u.id] ?? 0) : null,
          isDriver && lastJob != null
              ? xl.TextCellValue(isoFmt.format(lastJob))
              : null,
          xl.IntCellValue(_walletBalance[u.id] ?? 0),
          xl.IntCellValue(_lifetimeEarnings[u.id] ?? 0),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Failed to encode spreadsheet');
      }
      final blob = html.Blob([bytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
      html.AnchorElement(href: url)
        ..setAttribute('download', 'users-$stamp.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _buildUserCard(UserProfileModel user) {
    final roleColor = _roleColor(user.role);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryGreen,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Name + email + activity stats
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isNotEmpty ? user.name : 'No Name',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutralDarkerGrey,
                    ),
                  ),
                  _buildUserStatsLine(user, showPickupCount: false),
                ],
              ),
            ),

            // Phone
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: AppColors.neutralDarkerGrey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      user.mobileNumber ?? '--',
                      style: AppTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Pickups requested
            SizedBox(
              width: 130,
              child: _buildWalletField(
                icon: Icons.local_shipping,
                label: 'Pickups',
                value: _pickupCounts[user.id] ?? 0,
                color: Colors.orange.shade700,
                subtitle: _lastRequestedSubtitle(user),
              ),
            ),
            const SizedBox(width: 12),

            // Wallet balance + lifetime earnings
            SizedBox(
              width: 180,
              child: Row(
                children: [
                  Expanded(
                    child: _buildWalletField(
                      icon: Icons.account_balance_wallet,
                      label: 'Wallet',
                      value: _walletBalance[user.id] ?? 0,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildWalletField(
                      icon: Icons.savings,
                      label: 'Lifetime',
                      value: _lifetimeEarnings[user.id] ?? 0,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Role badge
            SizedBox(
              width: 100,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    user.role.isNotEmpty
                        ? user.role[0].toUpperCase() + user.role.substring(1)
                        : 'User',
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Joined date
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Joined',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.neutralDarkerGrey,
                    ),
                  ),
                  Text(
                    DateFormatter.formatDate(user.joinedAt),
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileUserCard(UserProfileModel user) {
    final roleColor = _roleColor(user.role);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryGreen,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isNotEmpty ? user.name : 'No Name',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user.email,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutralDarkerGrey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      _buildUserStatsLine(user, showPickupCount: false),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    user.role.isNotEmpty
                        ? user.role[0].toUpperCase() + user.role.substring(1)
                        : 'User',
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.phone, size: 14, color: AppColors.neutralDarkerGrey),
                const SizedBox(width: 4),
                Text(
                  user.mobileNumber ?? '--',
                  style: AppTextStyles.bodySmall,
                ),
                const Spacer(),
                const Icon(Icons.calendar_today, size: 14, color: AppColors.neutralDarkerGrey),
                const SizedBox(width: 4),
                Text(
                  DateFormatter.formatDate(user.joinedAt),
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildWalletField(
                    icon: Icons.account_balance_wallet,
                    label: 'Wallet Balance',
                    value: _walletBalance[user.id] ?? 0,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildWalletField(
                    icon: Icons.savings,
                    label: 'Lifetime Earnings',
                    value: _lifetimeEarnings[user.id] ?? 0,
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildWalletField(
                    icon: Icons.local_shipping,
                    label: 'Pickups',
                    value: _pickupCounts[user.id] ?? 0,
                    color: Colors.orange.shade700,
                    subtitle: _lastRequestedSubtitle(user),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletField({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppColors.neutralDarkerGrey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$value',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 9,
                      color: AppColors.neutralDarkerGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "Last: 28 Jun 2026" / "No pickups yet" for the Pickups card subtitle.
  String _lastRequestedSubtitle(UserProfileModel user) {
    final last = _lastPickupDate[user.id];
    return last != null
        ? 'Last: ${DateFormatter.formatDate(last)}'
        : 'No pickups yet';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Users',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_loading ? "--" : _allUsers.length} total users',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: _exporting ? null : _exportToExcel,
              icon: _exporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, size: 18),
              label: Text(_exporting ? 'Exporting…' : 'Export Excel'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Search + role filter
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            if (isWide) {
              return Row(
                children: [
                  Expanded(child: _buildSearchField()),
                  const SizedBox(width: 12),
                  _buildRoleFilter(),
                  const SizedBox(width: 12),
                  _buildSortControl(),
                ],
              );
            }
            return Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildRoleFilter(),
                    const SizedBox(width: 10),
                    Expanded(child: _buildSortControl()),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Results count
        if (!_loading)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${_filteredUsers.length} user${_filteredUsers.length == 1 ? '' : 's'} found',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutralDarkerGrey,
              ),
            ),
          ),

        // User list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No users found',
                            style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 700;
                        return ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return isWide
                                ? _buildUserCard(user)
                                : _buildMobileUserCard(user);
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search by name, email, or phone...',
        prefixIcon: const Icon(Icons.search, color: AppColors.neutralDarkerGrey),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
      ),
    );
  }

  Widget _buildRoleFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          items: _roles.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(
                role == 'All'
                    ? 'All Roles'
                    : role[0].toUpperCase() + role.substring(1),
                style: AppTextStyles.bodyMedium,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) _onRoleChanged(value);
          },
          icon: const Icon(Icons.filter_list, color: AppColors.primaryGreen),
        ),
      ),
    );
  }

  Widget _buildSortControl() {
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sort, size: 18, color: AppColors.neutralDarkerGrey),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              items: _sortLabels.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(
                    'Sort: ${e.value}',
                    style: AppTextStyles.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) _onSortByChanged(value);
              },
              icon: const Icon(Icons.arrow_drop_down,
                  color: AppColors.primaryGreen),
            ),
          ),
          IconButton(
            onPressed: _toggleSortDirection,
            visualDensity: VisualDensity.compact,
            tooltip: _sortAsc ? 'Ascending' : 'Descending',
            icon: Icon(
              _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}
