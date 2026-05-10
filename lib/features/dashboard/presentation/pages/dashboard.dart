import 'package:coexist_app_portal/core/constants/app_constants.dart';
import 'package:coexist_app_portal/core/utils/app_router.dart';
import 'package:coexist_app_portal/di/injection_container.dart' as di;
import 'package:coexist_app_portal/features/auth/domain/repositories/auth_repository.dart';
import 'package:coexist_app_portal/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:coexist_app_portal/features/auth/presentation/bloc/auth_event.dart';
import 'package:coexist_app_portal/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatefulWidget {
  final Widget child;
  const DashboardPage({super.key, required this.child});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _displayName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final AuthRepository authRepo = di.sl<AuthRepository>();
      final user = await authRepo.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _displayName = user?.name ?? 'User';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _displayName = 'User';
        _loading = false;
      });
    }
  }

  String _currentMenu(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.dashboardEvents)) return 'Events';
    if (location.startsWith(AppRoutes.dashboardPickups)) return 'Pickups';
    if (location.startsWith(AppRoutes.dashboardUsers)) return 'Users';
    if (location.startsWith(AppRoutes.dashboardCategories)) return 'Categories';
    if (location.startsWith(AppRoutes.dashboardTreePlanting)) return 'Plant a Tree';
    return 'Dashboard';
  }

  void _onMenuTap(String label, bool isInDrawer) {
    if (label == 'Dashboard') context.go(AppRoutes.dashboard);
    if (label == 'Events') context.go(AppRoutes.dashboardEvents);
    if (label == 'Pickups') context.go(AppRoutes.dashboardPickups);
    if (label == 'Users') context.go(AppRoutes.dashboardUsers);
    if (label == 'Categories') context.go(AppRoutes.dashboardCategories);
    if (label == 'Plant a Tree') context.go(AppRoutes.dashboardTreePlanting);
    if (label == 'Logout') _showLogoutDialog(context, _displayName ?? 'User');

    if (isInDrawer) Navigator.of(context).pop();
  }

  void _showLogoutDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: Text('Are you sure you want to logout, $name?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is Unauthenticated) {
                  context.go(AppRoutes.login);
                }
              },
              child: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.read<AuthBloc>().add(const LogoutEvent());
                    },
                    child: const Text('Logout'),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;

            if (isWide) {
              return Row(
                children: [
                  Container(
                    width: 260,
                    color: Colors.white,
                    child: _buildSidebar(context),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: widget.child,
                    ),
                  ),
                ],
              );
            }

            return Scaffold(
              drawer: Drawer(child: _buildSidebar(context, isInDrawer: true)),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {bool isInDrawer = false}) {
    final selected = _currentMenu(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/coexist-logo.png', height: 35),
            const SizedBox(height: 50),

            _navItem(
              Icons.dashboard,
              'Dashboard',
              selected == 'Dashboard',
              () => _onMenuTap('Dashboard', isInDrawer),
            ),
            _navItem(
              Icons.event,
              'Events',
              selected == 'Events',
              () => _onMenuTap('Events', isInDrawer),
            ),
            _navItem(
              Icons.local_shipping,
              'Pickups',
              selected == 'Pickups',
              () => _onMenuTap('Pickups', isInDrawer),
            ),
            _navItem(
              Icons.people,
              'Users',
              selected == 'Users',
              () => _onMenuTap('Users', isInDrawer),
            ),
            _navItem(
              Icons.category,
              'Categories',
              selected == 'Categories',
              () => _onMenuTap('Categories', isInDrawer),
            ),
            _navItem(
              Icons.park,
              'Plant a Tree',
              selected == 'Plant a Tree',
              () => _onMenuTap('Plant a Tree', isInDrawer),
            ),

            const Spacer(),

            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              'v${AppConstants.appVersion} • ${AppConstants.env}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutralDarkerGrey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppConstants.baseUrl.replaceFirst('https://', ''),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutralDarkerGrey,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            _navItem(
              Icons.logout,
              'Logout',
              false,
              () => _onMenuTap('Logout', isInDrawer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final bg = selected ? AppColors.primaryGreen : Colors.transparent;
    final textColor = selected ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : AppColors.primaryDarkGreen,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyLarge.copyWith(color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
