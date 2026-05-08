import 'package:coexist_app_portal/core/theme/app_colors.dart';
import 'package:coexist_app_portal/core/theme/app_text_styles.dart';
import 'package:coexist_app_portal/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/tree_order_model.dart';
import '../../domain/models/tree_price_model.dart';
import '../bloc/tree_planting_bloc.dart';
import '../bloc/tree_planting_event.dart';
import '../bloc/tree_planting_state.dart';

class TreePlantingSection extends StatefulWidget {
  const TreePlantingSection({super.key});

  @override
  State<TreePlantingSection> createState() => _TreePlantingSectionState();
}

class _TreePlantingSectionState extends State<TreePlantingSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Initial load: price tab.
    context.read<TreePlantingBloc>().add(const FetchTreePriceDataEvent());
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    if (_tabController.index == 0) {
      context.read<TreePlantingBloc>().add(const FetchTreePriceDataEvent());
    } else {
      context.read<TreePlantingBloc>().add(const FetchTreeOrdersEvent());
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plant a Tree',
          style: AppTextStyles.h2.copyWith(color: AppColors.primaryDarkGreen),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage tree-planting price and orders from the mobile app',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          indicatorColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.neutralDarkerGrey,
          tabs: const [
            Tab(icon: Icon(Icons.currency_rupee), text: 'Price & history'),
            Tab(icon: Icon(Icons.list_alt), text: 'Orders'),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BlocConsumer<TreePlantingBloc, TreePlantingState>(
            listener: (context, state) {
              if (state is TreePlantingActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
                // Reload the price tab after a successful update.
                context
                    .read<TreePlantingBloc>()
                    .add(const FetchTreePriceDataEvent());
              } else if (state is TreePlantingError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            buildWhen: (prev, curr) =>
                curr is TreePlantingLoading ||
                curr is TreePriceLoaded ||
                curr is TreeOrdersLoaded,
            builder: (context, state) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildPriceTab(context, state),
                  _buildOrdersTab(context, state),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceTab(BuildContext context, TreePlantingState state) {
    if (state is TreePlantingLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is! TreePriceLoaded) {
      return const SizedBox.shrink();
    }
    final current = state.current;
    final history = state.history;
    return ListView(
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current price per tree',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(
                        current == null
                            ? 'No price set'
                            : '₹${current.price.toStringAsFixed(2)}',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      if (current != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Effective from ${DateFormatter.formatDate(current.effectiveFrom)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.neutralDarkerGrey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showUpdatePriceDialog(context, current),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Update price'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Price history', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No price history yet',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
            ),
          )
        else
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text('Price', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700))),
                      Expanded(flex: 3, child: Text('Effective from', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700))),
                      Expanded(flex: 3, child: Text('Effective to', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700))),
                      Expanded(flex: 2, child: Text('Status', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...history.map(_priceHistoryRow),
              ],
            ),
          ),
      ],
    );
  }

  Widget _priceHistoryRow(TreePriceModel row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text('₹${row.price.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyLarge)),
          Expanded(
              flex: 3,
              child: Text(DateFormatter.formatDate(row.effectiveFrom),
                  style: AppTextStyles.bodyMedium)),
          Expanded(
              flex: 3,
              child: Text(
                  row.effectiveTo == null
                      ? '—'
                      : DateFormatter.formatDate(row.effectiveTo!),
                  style: AppTextStyles.bodyMedium)),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: row.isCurrent
                    ? AppColors.primaryGreen.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                row.isCurrent ? 'Current' : 'Historical',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      row.isCurrent ? AppColors.primaryGreen : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdatePriceDialog(
    BuildContext context,
    TreePriceModel? current,
  ) async {
    final controller = TextEditingController(
      text: current != null ? current.price.toStringAsFixed(2) : '',
    );
    final formKey = GlobalKey<FormState>();
    final bloc = context.read<TreePlantingBloc>();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update tree price'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'New price will become effective from tomorrow. Existing orders are unaffected.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Price per tree (₹)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null) return 'Enter a valid number';
                  if (parsed < 0) return 'Must be ≥ 0';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final value = double.parse(controller.text.trim());
              bloc.add(UpdateTreePriceEvent(value));
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // -------------------- Orders tab --------------------

  Widget _buildOrdersTab(BuildContext context, TreePlantingState state) {
    if (state is TreePlantingLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is! TreeOrdersLoaded) {
      return const SizedBox.shrink();
    }
    final orders = state.orders;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statusFilterRow(state.statusFilter),
        const SizedBox(height: 12),
        Expanded(
          child: orders.isEmpty
              ? Center(
                  child: Text(
                    state.statusFilter == null
                        ? 'No orders yet'
                        : 'No "${state.statusFilter}" orders',
                    style:
                        AppTextStyles.bodyLarge.copyWith(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _orderCard(orders[i]),
                ),
        ),
      ],
    );
  }

  Widget _statusFilterRow(String? selected) {
    final options = ['All', 'Pending', 'Paid', 'Planted', 'Cancelled'];
    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        final isAll = opt == 'All';
        final isSelected = isAll ? selected == null : selected == opt;
        return ChoiceChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: (_) {
            context.read<TreePlantingBloc>().add(
                  FetchTreeOrdersEvent(status: isAll ? null : opt),
                );
          },
        );
      }).toList(),
    );
  }

  Widget _orderCard(TreeOrderModel order) {
    final payment = order.payment;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${order.treeCount} ${order.treeCount == 1 ? 'tree' : 'trees'} • ₹${order.amount.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                _statusChip(order.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${order.userName ?? '(unknown user)'} • ${order.userEmail ?? order.userId}',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.neutralDarkerGrey),
            ),
            const SizedBox(height: 4),
            Text(
              'Placed ${DateFormatter.formatDate(order.createdAt)}',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
            ),
            if (order.isGift) ...[
              const SizedBox(height: 8),
              Text(
                'Gift to ${order.recipientName ?? '(no name)'}'
                '${order.recipientEmail != null ? ' <${order.recipientEmail}>' : ''}'
                '${order.occasion != null ? ' • ${order.occasion}' : ''}',
                style: AppTextStyles.bodySmall,
              ),
              if (order.message != null && order.message!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('"${order.message}"',
                      style: AppTextStyles.bodySmall
                          .copyWith(fontStyle: FontStyle.italic)),
                ),
            ],
            if (payment != null) ...[
              const Divider(height: 20),
              Text('Payment',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'Razorpay status: ${payment.status}'
                '${payment.razorpayPaymentId != null ? ' • ${payment.razorpayPaymentId}' : ''}',
                style: AppTextStyles.bodySmall,
              ),
              if (payment.verifiedAt != null)
                Text(
                  'Verified ${DateFormatter.formatDate(payment.verifiedAt!)}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.primaryGreen),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = Colors.blue;
        break;
      case 'planted':
        color = AppColors.primaryGreen;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'pending':
      default:
        color = Colors.orange;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: AppTextStyles.bodySmall
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
