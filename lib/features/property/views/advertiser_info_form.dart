import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/add_property_controller.dart';

class AdvertiserInfoForm extends ConsumerWidget {
  const AdvertiserInfoForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPropertyProvider);

    if (state.selectedCategory == null) return const SizedBox.shrink();

    return Column(
      children: state.selectedCategory!.fields.map((field) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            decoration: InputDecoration(
              labelText: field,
              border: const OutlineInputBorder(),
            ),
            // حفظ القيمة فوراً في الـ Provider أول ما المستخدم يكتب
            onChanged: (value) {
              ref
                  .read(addPropertyProvider.notifier)
                  .updateDynamicField(field, value);
            },
          ),
        );
      }).toList(),
    );
  }
}

extension _PropertyCategoryFields on PropertyCategory {
  Iterable<String> get fields {
    try {
      final value = (this as dynamic).fields;
      if (value is Iterable<String>) return value;
      if (value is List) return value.map((element) => element.toString());
      if (value is String) return [value];
    } catch (_) {}
    return const [];
  }
}
