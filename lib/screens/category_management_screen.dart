import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milk_ledger/models/milk_category.dart';
import 'package:milk_ledger/providers.dart';
import 'package:uuid/uuid.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});
  static const String route = '/categories';

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  final Map<String, TextEditingController> _priceControllers = {};

  @override
  void dispose() {
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final notifier = ref.read(categoriesProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Milk Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context, notifier),
            tooltip: 'Add Category',
          ),
        ],
      ),
      body: categories.isEmpty
          ? const Center(child: Text('No categories found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isDefault = category.id == MilkCategory.cowMilkId || category.id == MilkCategory.buffaloMilkId;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Color(category.colorValue),
                              child: Text(
                                category.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  if (isDefault) const Text('Default category', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            if (!isDefault)
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditCategoryDialog(context, notifier, category);
                                  } else if (value == 'delete') {
                                    _showDeleteCategoryDialog(context, notifier, category);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Default Price per Liter: '),
                            Expanded(
                              child: TextField(
                                controller: _getPriceController(category.id, category.defaultPricePerLiter),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  hintText: 'Enter price',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                onSubmitted: (value) async {
                                  final price = double.tryParse(value);
                                  if (price != null && price > 0) {
                                    final updatedCategory = category.copyWith(defaultPricePerLiter: price);
                                    await notifier.update(updatedCategory);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('₹', style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  TextEditingController _getPriceController(String categoryId, double initialPrice) {
    if (!_priceControllers.containsKey(categoryId)) {
      _priceControllers[categoryId] = TextEditingController(text: initialPrice.toStringAsFixed(2));
    }
    return _priceControllers[categoryId]!;
  }

  Future<void> _showAddCategoryDialog(BuildContext context, CategoriesNotifier notifier) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController(text: '60.00');
    Color selectedColor = Colors.blue;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Default Price per Liter (₹)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              const Text('Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.teal,
                  Colors.pink,
                  Colors.indigo,
                ].map((color) => GestureDetector(
                  onTap: () => setState(() => selectedColor = color),
                  child: CircleAvatar(
                    backgroundColor: color,
                    radius: 16,
                    child: selectedColor == color
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text);
                if (name.isEmpty || price == null || price <= 0) return;

                final category = MilkCategory(
                  id: const Uuid().v4(),
                  name: name,
                  colorValue: selectedColor.value,
                  defaultPricePerLiter: price,
                );

                await notifier.add(category);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditCategoryDialog(BuildContext context, CategoriesNotifier notifier, MilkCategory category) async {
    final nameController = TextEditingController(text: category.name);
    final priceController = TextEditingController(text: category.defaultPricePerLiter.toStringAsFixed(2));
    Color selectedColor = Color(category.colorValue);

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Default Price per Liter (₹)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              const Text('Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.teal,
                  Colors.pink,
                  Colors.indigo,
                ].map((color) => GestureDetector(
                  onTap: () => setState(() => selectedColor = color),
                  child: CircleAvatar(
                    backgroundColor: color,
                    radius: 16,
                    child: selectedColor == color
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text);
                if (name.isEmpty || price == null || price <= 0) return;

                final updatedCategory = category.copyWith(
                  name: name,
                  colorValue: selectedColor.value,
                  defaultPricePerLiter: price,
                );

                await notifier.update(updatedCategory);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteCategoryDialog(BuildContext context, CategoriesNotifier notifier, MilkCategory category) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await notifier.remove(category.id);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
