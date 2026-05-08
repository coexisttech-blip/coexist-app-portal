import 'package:coexist_app_portal/core/constants/app_constants.dart';
import 'package:coexist_app_portal/core/theme/app_colors.dart';
import 'package:coexist_app_portal/core/theme/app_text_styles.dart';
import 'package:coexist_app_portal/di/injection_container.dart' as di;
import 'package:coexist_app_portal/features/auth/domain/repositories/auth_repository.dart';
import 'package:coexist_app_portal/core/utils/app_router.dart';
import 'package:coexist_app_portal/features/dashboard/presentation/widgets/pickup_mis_section.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardSection extends StatefulWidget {
  final bool isWide;
  final String name;
  final double headingSize;
  final double subHeadingSize;

  const DashboardSection({
    super.key,
    required this.isWide,
    required this.name,
    required this.headingSize,
    required this.subHeadingSize,
  });

  @override
  State<DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> {
  bool statsLoading = false;
  Map<String, int> stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      statsLoading = true;
    });

    try {
      // Use current Supabase client
      final supabase = Supabase.instance.client;

      // Run queries in parallel
      final results = await Future.wait([
        supabase.from('users').select(),
        supabase.from('events').select().eq('status', 'Approved'),
        supabase.from('communities').select(),
        supabase.from('waste_pickups').select().eq('status', 'Completed'),
        supabase.from('tree_planting_orders').select('tree_count'),
        supabase.from('event_registrations').select(),
      ]);

      final usersList = results[0] as List? ?? [];
      final eventsList = results[1] as List? ?? [];
      final communitiesList = results[2] as List? ?? [];
      final pickupsCompletedList = results[3] as List? ?? [];
      final treeOrdersList = results[4] as List? ?? [];
      final registrationsList = results[5] as List? ?? [];

      // Sum tree_count from orders
      int treesPlanted = 0;
      for (final item in treeOrdersList) {
        try {
          final tc = item['tree_count'];
          if (tc is int) treesPlanted += tc;
          if (tc is String) treesPlanted += int.tryParse(tc) ?? 0;
          if (tc is double) treesPlanted += tc.toInt();
        } catch (_) {}
      }

      final totalEvents = eventsList.length;
      final totalRegistrations = registrationsList.length;
      final eventsPerVolunteer = totalEvents == 0
          ? 0
          : (totalRegistrations / totalEvents).round();

      final data = <String, int>{
        'Total Users': usersList.length,
        'Pickups Completed': pickupsCompletedList.length,
        'Communities': communitiesList.length,
        'Trees Planted': treesPlanted,
        'Avg Volunteers/Event': eventsPerVolunteer,
      };

      if (!mounted) return;
      setState(() {
        stats = data;
        statsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        stats = {};
        statsLoading = false;
      });
    }
  }

  Widget _statCard(String title, int? value, IconData icon, Color color) {
    final display = value == null ? '--' : value.toString();
    final route = _routeForStat(title);
    final card = Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(30),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutralDarkerGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    display,
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (route == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go(route),
      child: card,
    );
  }

  String? _routeForStat(String key) {
    final k = key.toLowerCase();
    if (k.contains('user')) return AppRoutes.dashboardUsers;
    if (k.contains('tree')) return AppRoutes.dashboardTreePlanting;
    if (k.contains('pickup')) return AppRoutes.dashboardPickups;
    return null;
  }

  IconData _iconForStat(String key) {
    if (key.toLowerCase().contains('user')) return Icons.people;
    if (key.toLowerCase().contains('tree')) return Icons.nature;
    if (key.toLowerCase().contains('pickup')) return Icons.shopping_bag;
    if (key.toLowerCase().contains('event')) return Icons.event;
    if (key.toLowerCase().contains('community')) return Icons.location_city;
    return Icons.insights;
  }

  Color _colorForStat(String key) {
    if (key.toLowerCase().contains('user')) return Colors.indigo;
    if (key.toLowerCase().contains('tree')) return Colors.green;
    if (key.toLowerCase().contains('pickup')) return Colors.orange;
    if (key.toLowerCase().contains('event')) return Colors.teal;
    if (key.toLowerCase().contains('community')) return Colors.purple;
    return AppColors.primaryGreen;
  }

  @override
  Widget build(BuildContext context) {
    Widget statsSection;
    if (statsLoading) {
      statsSection = const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: SizedBox(
          height: 24,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else {
      final keys = [
        'Total Users',
        'Trees Planted',
        'Pickups Completed',
        'Communities',
      ];
      final cards = keys
          .map((k) => _statCard(k, stats[k], _iconForStat(k), _colorForStat(k)))
          .toList(growable: false);

      print('stats: $stats');

      if (widget.isWide) {
        statsSection = Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards.map((c) => SizedBox(width: 260, child: c)).toList(),
        );
      } else {
        statsSection = GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3.4,
          children: cards,
        );
      }
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${widget.name}',
            style: AppTextStyles.h1.copyWith(
              color: AppColors.primaryDarkGreen,
              fontSize: widget.headingSize,
            ),
          ),
          Text(
            'Welcome to the COExist Portal Admin Dashboard.',
            style: AppTextStyles.bodyLarge.copyWith(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'Statistics',
            style: AppTextStyles.bodyLarge.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDarkGreen,
            ),
          ),
          const SizedBox(height: 18),
          statsSection,
          const SizedBox(height: 36),
          PickupMisSection(isWide: widget.isWide),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
