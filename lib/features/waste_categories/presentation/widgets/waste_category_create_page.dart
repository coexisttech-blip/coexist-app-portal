import 'package:coexist_app_portal/core/theme/app_colors.dart';
import 'package:coexist_app_portal/core/theme/app_text_styles.dart';
import 'package:coexist_app_portal/features/waste_categories/presentation/bloc/waste_category_bloc.dart';
import 'package:coexist_app_portal/features/waste_categories/presentation/bloc/waste_category_event.dart';
import 'package:coexist_app_portal/features/waste_categories/presentation/bloc/waste_category_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class WasteCategoryCreatePage extends StatefulWidget {
  const WasteCategoryCreatePage({super.key});

  @override
  State<WasteCategoryCreatePage> createState() => _WasteCategoryCreatePageState();
}

class _WasteCategoryCreatePageState extends State<WasteCategoryCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _displayOrderController = TextEditingController(text: '0');
  final _rateController = TextEditingController();
  final _customParentController = TextEditingController();

  String _parentCategory = '';
  String _unitOfMeasure = 'kg';
  bool _isActive = false;
  bool _isCustomParent = false;
  List<String> _parentCategories = [];

  @override
  void initState() {
    super.initState();
    context.read<WasteCategoryBloc>().add(const FetchParentCategoriesEvent());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _displayOrderController.dispose();
    _rateController.dispose();
    _customParentController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final parent = _isCustomParent
        ? _customParentController.text.trim()
        : _parentCategory;

    if (parent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter a parent category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

    final rate = double.tryParse(_rateController.text);
    if (rate == null || rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid initial rate'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<WasteCategoryBloc>().add(CreateCategoryEvent(
      name: _nameController.text.trim(),
      parentCategory: parent,
      unitOfMeasure: _unitOfMeasure,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isActive: _isActive,
      displayOrder: int.tryParse(_displayOrderController.text) ?? 0,
      initialRate: rate,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WasteCategoryBloc, WasteCategoryState>(
      listener: (context, state) {
        if (state is ParentCategoriesLoaded) {
          setState(() => _parentCategories = state.parentCategories);
        } else if (state is WasteCategoryActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
          context.go('/dashboard/categories');
        } else if (state is WasteCategoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      buildWhen: (_, __) => false,
      builder: (context, state) {
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
                    'New Category',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Form(
                key: _formKey,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                            'Categories with the same parent category are grouped together as a tab in the mobile app',
                                        helperMaxLines: 2,
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
                                        helperText:
                                            'Categories with the same parent category are grouped together as a tab in the mobile app',
                                        helperMaxLines: 2,
                                      ),
                                      items: _parentCategories.map((p) {
                                        return DropdownMenuItem(value: p, child: Text(p));
                                      }).toList(),
                                      onChanged: (v) {
                                        if (v != null) setState(() => _parentCategory = v);
                                      },
                                      validator: (v) =>
                                          v == null || v.isEmpty ? 'Required' : null,
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
                            helperText:
                                'This text is displayed to app users when they tap the info icon',
                            helperMaxLines: 2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Initial rate
                        TextFormField(
                          controller: _rateController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Initial Rate (\u20B9) *',
                            border: const OutlineInputBorder(),
                            prefixText: '\u20B9 ',
                            suffixText: 'per $_unitOfMeasure',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Rate is required';
                            if (double.tryParse(v) == null) return 'Enter a valid number';
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
                            if (_isActive)
                              Text(
                                '(will appear in mobile app)',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primaryGreen,
                                ),
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
                            child: const Text('Create Category'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
