
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/category_provider.dart';
import '../../../../core/constants/app_colors.dart';

class CategoryAdminScreen extends ConsumerStatefulWidget {
  const CategoryAdminScreen({super.key});

  @override
  ConsumerState<CategoryAdminScreen> createState() => _CategoryAdminScreenState();
}

class _CategoryAdminScreenState extends ConsumerState<CategoryAdminScreen> {
  final _serviceController = TextEditingController();
  final _retailController = TextEditingController();

  @override
  void dispose() {
    _serviceController.dispose();
    _retailController.dispose();
    super.dispose();
  }

  void _addCategory(String type, String name) async {
    if (name.trim().isEmpty) return;
    try {
      await ref.read(categoryAdminProvider).addCategory(type, name.trim());
      if (type == 'service') _serviceController.clear();
      if (type == 'retail') _retailController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Category added!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error')));
      }
    }
  }

  void _removeCategory(String type, String name) async {
    try {
      await ref.read(categoryAdminProvider).removeCategory(type, name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Category removed!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(appCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: categoriesAsync.when(
        data: (categories) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCategorySection('Service Categories', 'service', categories.serviceCategories, _serviceController, isDark),
              const SizedBox(height: 32),
              _buildCategorySection('Retail Categories', 'retail', categories.retailCategories, _retailController, isDark),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading categories')),
      ),
    );
  }

  Widget _buildCategorySection(String title, String type, List<String> items, TextEditingController controller, bool isDark) {
    return Card(
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'New  category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _addCategory(type, controller.text),
                  icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32),
                )
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((cat) => Chip(
                label: Text(cat),
                onDeleted: () => _removeCategory(type, cat),
                deleteIcon: const Icon(Icons.close, size: 16),
              )).toList(),
            )
          ],
        ),
      ),
    );
  }
}

