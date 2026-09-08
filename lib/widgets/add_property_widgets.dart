import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ودجيت للصور والفيديو
class MediaPickerWidget extends StatelessWidget {
  final XFile? file;
  final bool isVideo;
  final VoidCallback onTap;

  const MediaPickerWidget(
      {super.key,
      required this.file,
      required this.isVideo,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8)),
        child: Center(
          child: file != null
              ? (isVideo
                  ? const Icon(Icons.videocam, size: 48)
                  : Image.network(file!.path, fit: BoxFit.cover))
              : Icon(isVideo ? Icons.videocam : Icons.image,
                  size: 48, color: Colors.grey),
        ),
      ),
    );
  }
}

// ودجيت للـ Dropdown
class CustomDropdown extends StatelessWidget {
  final String label;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const CustomDropdown(
      {super.key,
      required this.label,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
