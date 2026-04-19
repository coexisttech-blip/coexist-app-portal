import 'package:coexist_app_portal/core/theme/app_colors.dart';
import 'package:coexist_app_portal/core/theme/app_text_styles.dart';
import 'package:coexist_app_portal/features/waste_categories/domain/models/waste_category_model.dart';
import 'package:coexist_app_portal/features/waste_categories/presentation/bloc/waste_category_bloc.dart';
import 'package:coexist_app_portal/features/waste_categories/presentation/bloc/waste_category_event.dart';
import 'package:coexist_app_portal/features/waste_categories/presentation/bloc/waste_category_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class WasteCategoriesSection extends StatefulWidget {
  const WasteCategoriesSection({super.key});

  @override
  State<WasteCategoriesSection> createState() => _WasteCategoriesSectionState();
}

class _WasteCategoriesSectionState extends State<WasteCategoriesSection> {
  @override
  void initState() {
    super.initState();
    context.read<WasteCategoryBloc>().add(const FetchCategoriesEvent());
  }

  Map<String, List<WasteCategoryModel>> _groupByParent(
    List<WasteCategoryModel> categories,
  ) {
    final grouped = <String, List<WasteCategoryModel>>{};
    for (final cat in categories) {
      grouped.putIfAbsent(cat.parentCategory, () => []).add(cat);
    }
    return grouped;
  }

  void _toggleActive(WasteCategoryModel category) {
    final newActive = !category.isActive;

    if (newActive && (category.description == null || category.description!.isEmpty)) {
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

    context.read<WasteCategoryBloc>().add(ToggleCategoryActiveEvent(
      categoryId: category.id,
      isActive: newActive,
    ));
  }

  Color _parentColor(String parent) {
    switch (parent.toLowerCase()) {
      case 'plastic':
        return Colors.blue;
      case 'paper':
        return Colors.orange;
      case 'electronics':
        return Colors.purple;
      default:
        return Colors.teal;
    }
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
                    'Waste Categories',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage waste types, categories, and pricing',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => context.go('/dashboard/categories/create'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Category'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                context.read<WasteCategoryBloc>().add(const FetchCategoriesEvent());
              },
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

        // Categories list
        Expanded(
          child: BlocConsumer<WasteCategoryBloc, WasteCategoryState>(
            listener: (context, state) {
              if (state is WasteCategoryActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
                context.read<WasteCategoryBloc>().add(const FetchCategoriesEvent());
              } else if (state is WasteCategoryError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            buildWhen: (previous, current) =>
                current is CategoriesLoaded || current is WasteCategoryLoading,
            builder: (context, state) {
              if (state is WasteCategoryLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is CategoriesLoaded) {
                if (state.categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No categories found',
                          style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final grouped = _groupByParent(state.categories);
                return ListView(
                  children: grouped.entries.map((entry) {
                    final parentColor = _parentColor(entry.key);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Parent category header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: parentColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: parentColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.folder_outlined, size: 18, color: parentColor),
                              const SizedBox(width: 8),
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: parentColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${entry.value.length} categories',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: parentColor.withValues(alpha: 0.7),
                                ),
                              ),
                              const Spacer(),
                              _tabPreview(entry.key, entry.value),
                            ],
                          ),
                        ),
                        // Category rows
                        ...entry.value.map((cat) => _categoryRow(cat)),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _tabPreview(String parent, List<WasteCategoryModel> categories) {
    final hasActive = categories.any((c) => c.isActive);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: hasActive ? AppColors.primaryGreen.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasActive ? AppColors.primaryGreen.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        hasActive ? 'Tab enabled' : 'Coming soon',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: hasActive ? AppColors.primaryGreen : Colors.grey,
        ),
      ),
    );
  }

  Widget _categoryRow(WasteCategoryModel category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6, left: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.go('/dashboard/categories/${category.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Name + description
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (category.description != null && category.description!.isNotEmpty)
                      Text(
                        category.description!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutralDarkerGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Unit
              SizedBox(
                width: 60,
                child: Text(
                  category.unitOfMeasure,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutralDarkerGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Rate
              SizedBox(
                width: 100,
                child: Text(
                  category.rateDisplay,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Order
              SizedBox(
                width: 40,
                child: Text(
                  '#${category.displayOrder}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutralDarkerGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Active toggle
              SizedBox(
                width: 60,
                child: Switch(
                  value: category.isActive,
                  onChanged: (_) => _toggleActive(category),
                  activeColor: AppColors.primaryGreen,
                ),
              ),

              // Arrow
              const Icon(Icons.chevron_right, color: AppColors.neutralDarkerGrey),
            ],
          ),
        ),
      ),
    );
  }
}
