import 'package:coexist_app_portal/core/theme/app_colors.dart';
import 'package:coexist_app_portal/core/theme/app_text_styles.dart';
import 'package:coexist_app_portal/core/utils/date_formatter.dart';
import 'package:coexist_app_portal/features/auth/domain/models/user_profile_model.dart';
import 'package:flutter/material.dart';
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
  String _searchQuery = '';
  String _selectedRole = 'All';
  final _searchController = TextEditingController();

  static const _roles = ['All', 'admin', 'user', 'volunteer'];

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
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .order('joined_at', ascending: false);

      final users = (response as List)
          .map((data) => UserProfileModel.fromSupabase(data))
          .toList();

      if (!mounted) return;
      setState(() {
        _allUsers = users;
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _allUsers = [];
        _filteredUsers = [];
        _loading = false;
      });
    }
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

    _filteredUsers = filtered;
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
      default:
        return Colors.blue;
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

            // Name + email
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
          ],
        ),
      ),
    );
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
                ],
              );
            }
            return Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildRoleFilter(),
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
}
