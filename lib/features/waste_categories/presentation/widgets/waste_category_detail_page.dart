import 'package:coexist_app_portal/core/theme/app_colors.dart';
import 'package:coexist_app_portal/core/theme/app_text_styles.dart';
import 'package:coexist_app_portal/core/utils/date_formatter.dart';
import 'package:coexist_app_portal/features/waste_categories/domain/models/waste_category_model.dart';
import 'package:coexist_app_portal/features/waste_categories/domain/models/waste_category_rate_model.dart';
import 'package:coexist_app_portal/features/waste_categories/presentation/bloc/waste_category_bloc.dart';
import 'package:coexist_app_portal/features/waste_categories/presentation/bloc/waste_category_event.dart';
import 'package:coexist_app_portal/features/waste_categories/presentation/bloc/waste_category_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class WasteCategoryDetailPage extends StatefulWidget {
  final String categoryId;
  const WasteCategoryDetailPage({super.key, required this.categoryId});

  @override
  State<WasteCategoryDetailPage> createState() => _WasteCategoryDetailPageState();
}

class _WasteCategoryDetailPageState extends State<WasteCategoryDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _displayOrderController = TextEditingController();
  final _maxWeightController = TextEditingController();

  String _parentCategory = '';
  String _unitOfMeasure = 'kg';
  bool _isActive = false;
  WasteCategoryModel? _category;
  List<WasteCategoryRateModel> _rates = [];
  List<String> _parentCategories = [];
  bool _isCustomParent = false;
  final _customParentController = TextEditingController();
  String? _originalParent;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<WasteCategoryBloc>();
    bloc.add(FetchCategoryDetailEvent(categoryId: widget.categoryId));
    bloc.add(FetchRateHistoryEvent(categoryId: widget.categoryId));
    bloc.add(const FetchParentCategoriesEvent());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _displayOrderController.dispose();
    _maxWeightController.dispose();
    _customParentController.dispose();
    super.dispose();
  }

  void _populateFields(WasteCategoryModel category) {
    _category = category;
    _nameController.text = category.name;
    _descriptionController.text = category.description ?? '';
    _displayOrderController.text = category.displayOrder.toString();
    _maxWeightController.text = category.maxWeight != null
        ? (category.maxWeight! % 1 == 0
            ? category.maxWeight!.toInt().toString()
            : category.maxWeight!.toString())
        : '';
    _parentCategory = category.parentCategory;
    _originalParent = category.parentCategory;
    _unitOfMeasure = category.unitOfMeasure;
    _isActive = category.isActive;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final parent = _isCustomParent
        ? _customParentController.text.trim()
        : _parentCategory;

    if (_isActive && _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Description is required for active categories. '
            'The description is displayed to end users in the mobile app.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_originalParent != null && parent != _originalParent) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Change Parent Category?'),
          content: const Text(
            'Changing the parent category will affect how this item is '
            'grouped in the mobile app tabs.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _submitUpdate(parent);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    } else {
      _submitUpdate(parent);
    }
  }

  void _submitUpdate(String parent) {
    context.read<WasteCategoryBloc>().add(UpdateCategoryEvent(
      id: widget.categoryId,
      name: _nameController.text.trim(),
      parentCategory: parent,
      unitOfMeasure: _unitOfMeasure,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isActive: _isActive,
      displayOrder: int.tryParse(_displayOrderController.text) ?? 0,
      maxWeight: _maxWeightController.text.trim().isEmpty
          ? null
          : double.tryParse(_maxWeightController.text.trim()),
    ));
  }

  void _showUpdateRateDialog() {
    final rateController = TextEditingController();
    final currentRate = _category?.currentRate;
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentRate != null)
              Text(
                'Current rate: \u20B9${currentRate.toStringAsFixed(0)}/${_category!.unitOfMeasure}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutralDarkerGrey,
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'New Rate (\u20B9)',
                border: const OutlineInputBorder(),
                prefixText: '\u20B9 ',
                suffixText: 'per ${_category?.unitOfMeasure ?? "unit"}',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Effective from: ${DateFormatter.formatDate(tomorrow)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutralDarkerGrey,
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
              final newRate = double.tryParse(rateController.text);
              if (newRate == null || newRate <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid rate'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.of(ctx).pop();
              _confirmRateChange(currentRate, newRate, tomorrow);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmRateChange(double? oldRate, double newRate, DateTime effectiveDate) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Rate Change'),
        content: Text(
          'Change rate from \u20B9${oldRate?.toStringAsFixed(0) ?? "0"} to '
          '\u20B9${newRate.toStringAsFixed(0)} effective from '
          '${DateFormatter.formatDate(effectiveDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<WasteCategoryBloc>().add(UpdateRateEvent(
                categoryId: widget.categoryId,
                newRate: newRate,
              ));
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WasteCategoryBloc, WasteCategoryState>(
      listener: (context, state) {
        if (state is CategoryDetailLoaded) {
          setState(() => _populateFields(state.category));
        } else if (state is RateHistoryLoaded) {
          setState(() => _rates = state.rates);
        } else if (state is ParentCategoriesLoaded) {
          setState(() => _parentCategories = state.parentCategories);
        } else if (state is WasteCategoryActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
          // Refresh data
          final bloc = context.read<WasteCategoryBloc>();
          bloc.add(FetchCategoryDetailEvent(categoryId: widget.categoryId));
          bloc.add(FetchRateHistoryEvent(categoryId: widget.categoryId));
        } else if (state is WasteCategoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      buildWhen: (_, __) => false,
      builder: (context, state) {
        if (_category == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back + title
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/dashboard/categories'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Edit Category',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Form
              Form(
                key: _formKey,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category Info', style: AppTextStyles.h3),
                        const SizedBox(height: 16),

                        // Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Parent category
                        Row(
                          children: [
                            Expanded(
                              child: _isCustomParent
                                  ? TextFormField(
                                      controller: _customParentController,
                                      decoration: const InputDecoration(
                                        labelText: 'New Parent Category *',
                                        border: OutlineInputBorder(),
                                        helperText:
                                            'Categories with the same parent are grouped as a tab in the mobile app',
                                      ),
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty ? 'Required' : null,
                                    )
                                  : DropdownButtonFormField<String>(
                                      value: _parentCategories.contains(_parentCategory)
                                          ? _parentCategory
                                          : null,
                                      decoration: const InputDecoration(
                                        labelText: 'Parent Category *',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: _parentCategories.map((p) {
                                        return DropdownMenuItem(value: p, child: Text(p));
                                      }).toList(),
                                      onChanged: (v) {
                                        if (v != null) setState(() => _parentCategory = v);
                                      },
                                    ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isCustomParent = !_isCustomParent;
                                  if (!_isCustomParent) {
                                    _customParentController.clear();
                                  }
                                });
                              },
                              child: Text(_isCustomParent ? 'Use existing' : '+ New'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Unit of measure
                        DropdownButtonFormField<String>(
                          value: _unitOfMeasure,
                          decoration: const InputDecoration(
                            labelText: 'Unit of Measure *',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(value: 'unit', child: Text('unit')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _unitOfMeasure = v);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            helperText: 'This text is displayed to app users',
                            helperMaxLines: 2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Max weight the customer can enter on the schedule
                        // slider for this category (blank = default 25).
                        TextFormField(
                          controller: _maxWeightController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Max Weight (slider limit)',
                            hintText: 'Leave blank for default (25)',
                            border: const OutlineInputBorder(),
                            suffixText: _unitOfMeasure,
                            helperText:
                                'Upper limit for this category on the customer schedule slider',
                            helperMaxLines: 2,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final parsed = double.tryParse(v.trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Display order + Active toggle
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: TextFormField(
                                controller: _displayOrderController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Display Order',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            const Text('Active'),
                            const SizedBox(width: 8),
                            Switch(
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v),
                              activeColor: AppColors.primaryGreen,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Current rate section
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Current Rate', style: AppTextStyles.h3),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: _showUpdateRateDialog,
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Update Rate'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _category!.currentRate != null
                            ? '\u20B9${_category!.currentRate!.toStringAsFixed(0)} per ${_category!.unitOfMeasure}'
                            : 'No rate set',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.primaryDarkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Rate history
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rate History', style: AppTextStyles.h3),
                      const SizedBox(height: 16),
                      if (_rates.isEmpty)
                        Text(
                          'No rate history',
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                        )
                      else
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(2),
                            3: FlexColumnWidth(2),
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              children: [
                                _tableHeader('Rate'),
                                _tableHeader('Effective From'),
                                _tableHeader('Effective To'),
                                _tableHeader('Created At'),
                              ],
                            ),
                            ..._rates.map((rate) => TableRow(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.grey.shade200),
                                    ),
                                  ),
                                  children: [
                                    _tableCell(
                                      '\u20B9${rate.rate.toStringAsFixed(0)}',
                                      bold: rate.isCurrent,
                                    ),
                                    _tableCell(DateFormatter.formatDate(rate.effectiveFrom)),
                                    _tableCell(
                                      rate.effectiveTo != null
                                          ? DateFormatter.formatDate(rate.effectiveTo!)
                                          : 'Current',
                                      color: rate.isCurrent ? AppColors.primaryGreen : null,
                                    ),
                                    _tableCell(DateFormatter.formatDate(rate.createdAt)),
                                  ],
                                )),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.neutralDarkerGrey,
        ),
      ),
    );
  }

  Widget _tableCell(String text, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }
}
