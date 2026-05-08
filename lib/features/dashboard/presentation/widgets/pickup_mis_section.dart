import 'package:coexist_app_portal/core/theme/app_colors.dart';
import 'package:coexist_app_portal/core/theme/app_text_styles.dart';
import 'package:coexist_app_portal/core/utils/app_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum MisRange { today, last7, last30, allTime }

class PickupMisSection extends StatefulWidget {
  final bool isWide;
  const PickupMisSection({super.key, this.isWide = true});

  @override
  State<PickupMisSection> createState() => _PickupMisSectionState();
}

class _PickupMisSectionState extends State<PickupMisSection> {
  MisRange _range = MisRange.last30;
  bool _loading = true;
  String? _error;

  Map<String, int> _statusCounts = {};
  double _totalKg = 0;
  int _totalAmount = 0;
  double _avgKg = 0;
  double _cancellationRate = 0;
  Map<String, _ParentStat> _parentStats = {};
  Map<DateTime, int> _completedPerDay = {};
  List<_DriverStat> _topDrivers = const [];

  static const _statuses = [
    'Requested',
    'Scheduled',
    'Approved',
    'Assigned',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime? _rangeStart() {
    final now = DateTime.now();
    switch (_range) {
      case MisRange.today:
        return DateTime(now.year, now.month, now.day);
      case MisRange.last7:
        return DateTime(now.year, now.month, now.day - 6);
      case MisRange.last30:
        return DateTime(now.year, now.month, now.day - 29);
      case MisRange.allTime:
        return null;
    }
  }

  String get _rangeLabel {
    switch (_range) {
      case MisRange.today:
        return 'Today';
      case MisRange.last7:
        return 'Last 7 days';
      case MisRange.last30:
        return 'Last 30 days';
      case MisRange.allTime:
        return 'All time';
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final start = _rangeStart();
      final supabase = Supabase.instance.client;
      var query = supabase.from('waste_pickups').select();
      if (start != null) {
        query = query.gte('created_at', start.toIso8601String());
      }
      final rows = (await query) as List;
      _aggregate(rows.cast<Map<String, dynamic>>());
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load MIS data: $e';
      });
    }
  }

  void _aggregate(List<Map<String, dynamic>> rows) {
    final statusCounts = <String, int>{for (final s in _statuses) s: 0};
    double totalKg = 0;
    int totalAmount = 0;
    int completedCount = 0;
    final parentStats = <String, _ParentStat>{};
    final completedPerDay = <DateTime, int>{};
    final driverAgg = <String, _DriverStat>{};

    for (final m in rows) {
      final status = (m['status'] ?? 'Unknown').toString();
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      if (status == 'Completed') {
        completedCount++;
        final aw = m['actual_weight'];
        final wKg = aw is num ? aw.toDouble() : 0.0;
        totalKg += wKg;

        final me = m['money_earned'];
        if (me is num) totalAmount += me.toInt();

        final completedAt = m['completed_at'];
        if (completedAt != null) {
          final dt = DateTime.tryParse(completedAt.toString());
          if (dt != null) {
            final day = DateTime(dt.year, dt.month, dt.day);
            completedPerDay[day] = (completedPerDay[day] ?? 0) + 1;
          }
        }

        final driverName = (m['assigned_driver_name'] as String?)?.trim();
        if (driverName != null && driverName.isNotEmpty) {
          final cur = driverAgg[driverName] ?? _DriverStat(driverName, 0, 0);
          driverAgg[driverName] = _DriverStat(
            driverName,
            cur.count + 1,
            cur.kg + wKg,
          );
        }

        final wt = (m['waste_type'] ?? '').toString();
        if (wt.isNotEmpty) {
          final parents = wt
              .split('/')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          if (parents.isNotEmpty) {
            final share = wKg / parents.length;
            for (final p in parents) {
              final cur = parentStats[p] ?? _ParentStat(p, 0, 0);
              parentStats[p] = _ParentStat(p, cur.count + 1, cur.kg + share);
            }
          }
        }
      }
    }

    final cancelled = statusCounts['Cancelled'] ?? 0;
    final total = rows.length;
    _statusCounts = statusCounts;
    _totalKg = totalKg;
    _totalAmount = totalAmount;
    _avgKg = completedCount == 0 ? 0 : totalKg / completedCount;
    _cancellationRate = total == 0 ? 0 : cancelled / total;
    _parentStats = parentStats;
    _completedPerDay = completedPerDay;
    final drivers = driverAgg.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    _topDrivers = drivers.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          )
        else ...[
          _buildStatusRow(),
          const SizedBox(height: 16),
          _buildKpiRow(),
          const SizedBox(height: 24),
          _buildWasteTypeBars(),
          const SizedBox(height: 24),
          _buildDailyTrend(),
          const SizedBox(height: 24),
          _buildLeaderboard(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Pickup MIS',
          style: AppTextStyles.bodyLarge.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDarkGreen,
          ),
        ),
        const Spacer(),
        PopupMenuButton<MisRange>(
          initialValue: _range,
          onSelected: (v) {
            setState(() => _range = v);
            _load();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: MisRange.today, child: Text('Today')),
            PopupMenuItem(value: MisRange.last7, child: Text('Last 7 days')),
            PopupMenuItem(value: MisRange.last30, child: Text('Last 30 days')),
            PopupMenuItem(value: MisRange.allTime, child: Text('All time')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.date_range,
                  size: 16,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 6),
                Text(_rangeLabel, style: AppTextStyles.bodySmall),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: _load,
        ),
      ],
    );
  }

  Widget _buildStatusRow() {
    final cards = _statuses.map((s) {
      return _statusCard(s, _statusCounts[s] ?? 0);
    }).toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards
          .map((c) => SizedBox(width: widget.isWide ? 180 : 160, child: c))
          .toList(),
    );
  }

  Widget _statusCard(String status, int value) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go(AppRoutes.dashboardPickups),
      child: Card(
        color: Colors.white,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: _statusColor(status).withAlpha(30),
                    child: Icon(
                      _statusIcon(status),
                      size: 16,
                      color: _statusColor(status),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.neutralDarkerGrey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.primaryDarkGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Requested':
        return Colors.amber.shade700;
      case 'Scheduled':
        return Colors.blue;
      case 'Approved':
        return Colors.indigo;
      case 'Assigned':
        return Colors.teal;
      case 'Completed':
        return AppColors.primaryGreen;
      case 'Cancelled':
        return Colors.red.shade400;
    }
    return Colors.grey;
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Requested':
        return Icons.hourglass_empty;
      case 'Scheduled':
        return Icons.event;
      case 'Approved':
        return Icons.verified;
      case 'Assigned':
        return Icons.local_shipping;
      case 'Completed':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
    }
    return Icons.circle;
  }

  Widget _buildKpiRow() {
    final pct = (_cancellationRate * 100).toStringAsFixed(1);
    final cards = [
      _kpiCard('Total Weight', '${_totalKg.toStringAsFixed(1)} kg',
          Icons.scale, Colors.green),
      _kpiCard('Total Paid', '₹$_totalAmount', Icons.currency_rupee,
          Colors.deepOrange),
      _kpiCard('Avg Weight / Pickup', '${_avgKg.toStringAsFixed(1)} kg',
          Icons.av_timer, Colors.blueGrey),
      _kpiCard('Cancellation Rate', '$pct%', Icons.cancel_schedule_send,
          Colors.red.shade400),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards
          .map((c) => SizedBox(width: widget.isWide ? 240 : 200, child: c))
          .toList(),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.primaryDarkGreen,
                      fontSize: 20,
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

  Widget _buildWasteTypeBars() {
    final entries = _parentStats.values.toList()
      ..sort((a, b) => b.kg.compareTo(a.kg));
    final maxKg = entries.fold<double>(0, (a, e) => e.kg > a ? e.kg : a);

    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Waste-type breakdown (Completed)',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Text(
                'No completed pickups in range.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutralDarkerGrey,
                ),
              )
            else
              ...entries
                  .map((e) => _wasteBar(e, maxKg))
                  .expand((w) => [w, const SizedBox(height: 8)]),
          ],
        ),
      ),
    );
  }

  Widget _wasteBar(_ParentStat e, double maxKg) {
    final fraction = maxKg <= 0 ? 0.0 : (e.kg / maxKg).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(e.parent, style: AppTextStyles.bodySmall),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 18, color: Colors.grey.shade100),
                FractionallySizedBox(
                  widthFactor: fraction.toDouble(),
                  child: Container(
                    height: 18,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 130,
          child: Text(
            '${e.kg.toStringAsFixed(1)} kg · ${e.count} pickup${e.count == 1 ? '' : 's'}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutralDarkerGrey,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyTrend() {
    if (_completedPerDay.isEmpty) {
      return const SizedBox.shrink();
    }

    final start = _rangeStart() ?? _completedPerDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);
    final end = DateTime.now();
    final days = <DateTime>[];
    var d = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!d.isAfter(last)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }
    final spots = <FlSpot>[];
    for (var i = 0; i < days.length; i++) {
      final v = (_completedPerDay[days[i]] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), v));
    }
    final maxY = spots.fold<double>(
      0,
      (a, s) => s.y > a ? s.y : a,
    );

    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completed pickups · daily',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY <= 0 ? 1 : (maxY * 1.2),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) return const SizedBox.shrink();
                          return Text(
                            value.toInt().toString(),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.neutralDarkerGrey,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: (days.length / 6).ceil().clamp(1, 30).toDouble(),
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= days.length) {
                            return const SizedBox.shrink();
                          }
                          final dt = days[i];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('d MMM').format(dt),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.neutralDarkerGrey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primaryGreen,
                      barWidth: 2,
                      dotData: FlDotData(show: spots.length <= 14),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primaryGreen.withAlpha(30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top drivers',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (_topDrivers.isEmpty)
              Text(
                'No driver activity in range.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutralDarkerGrey,
                ),
              )
            else
              ..._topDrivers.asMap().entries.map(
                    (entry) => _leaderboardRow(entry.key + 1, entry.value),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _leaderboardRow(int rank, _DriverStat d) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primaryGreen.withAlpha(30),
            child: Text(
              '$rank',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryDarkGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              d.name,
              style: AppTextStyles.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${d.count} pickup${d.count == 1 ? '' : 's'} · ${d.kg.toStringAsFixed(1)} kg',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutralDarkerGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentStat {
  final String parent;
  final int count;
  final double kg;
  _ParentStat(this.parent, this.count, this.kg);
}

class _DriverStat {
  final String name;
  final int count;
  final double kg;
  _DriverStat(this.name, this.count, this.kg);
}
