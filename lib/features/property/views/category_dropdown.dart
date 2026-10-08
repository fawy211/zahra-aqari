import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/property_categories.dart' as category_data;
import '../controllers/add_property_controller.dart' as add_property_controller;

class CategoryDropdown extends ConsumerWidget {
  const CategoryDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // نراقب الحالة لنعرف التصنيف المختار حالياً
    final state = ref.watch(add_property_controller.addPropertyProvider);
    final categories = category_data.propertyCategories
        .cast<add_property_controller.PropertyCategory>();

    return DropdownButtonFormField<add_property_controller.PropertyCategory>(
      decoration: const InputDecoration(
        labelText: 'التصنيف',
        border: OutlineInputBorder(),
      ),
      value: state.selectedCategory, // القيمة الحالية من الـ State
      items: categories.map((cat) {
        return DropdownMenuItem<add_property_controller.PropertyCategory>(
          value: cat,
          child: Text(cat.name),
        );
      }).toList(),
      onChanged: (add_property_controller.PropertyCategory? val) {
        if (val != null) {
          // تحديث التصنيف في الـ Controller
          ref
              .read(add_property_controller.addPropertyProvider.notifier)
              .selectCategory(val);
        }
      },
    );
  }
}
