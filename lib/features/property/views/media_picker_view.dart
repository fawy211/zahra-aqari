import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/add_property_controller.dart';

// (اختياري) إذا كنت نقلت addMediaUrl داخل الـ AddPropertyNotifier الأساسي، يمكنك الاستغناء عن هذا الـ Extension
extension AddPropertyNotifierMediaUrlExtension on AddPropertyNotifier {
  void addMediaUrl(String downloadUrl) {
    final notifier = this as dynamic;
    final currentState = notifier.state;
    final currentMediaUrls = currentState.mediaUrls;
    final updatedMediaUrls = [...currentMediaUrls, downloadUrl];
    notifier.state = currentState.copyWith(mediaUrls: updatedMediaUrls);
  }

  // إضافة ميثود لحذف صورة بالخطأ
  void removeMediaUrl(int index) {
    final notifier = this as dynamic;
    final currentState = notifier.state;
    final updatedMediaUrls = List<String>.from(currentState.mediaUrls)
      ..removeAt(index);
    notifier.state = currentState.copyWith(mediaUrls: updatedMediaUrls);
  }
}

class MediaPickerView extends ConsumerStatefulWidget {
  const MediaPickerView({super.key});

  @override
  ConsumerState<MediaPickerView> createState() => _MediaPickerViewState();
}

class _MediaPickerViewState extends ConsumerState<MediaPickerView> {
  bool _isUploading = false;

  Future<void> _uploadMedia(File file, String folder) async {
    setState(() => _isUploading = true);
    try {
      final supabase = Supabase.instance.client;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final filePath = '$folder/$fileName';

      // رفع الملف إلى Supabase Storage
      await supabase.storage.from('properties').upload(filePath, file);

      // جلب الرابط العام للملف المرفوع
      final downloadUrl =
          supabase.storage.from('properties').getPublicUrl(filePath);

      // إضافة الرابط للـ State
      ref.read(addPropertyProvider.notifier).addMediaUrl(downloadUrl);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addPropertyProvider);
    final picker = ImagePicker();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isUploading) const LinearProgressIndicator(),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploading
                    ? null
                    : () async {
                        final image =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          await _uploadMedia(File(image.path), 'images');
                        }
                      },
                icon: const Icon(Icons.add_a_photo),
                label: const Text("إضافة صور العقار"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // عرض الصور المرفوعة مع زر للحذف
        if (state.mediaUrls.isNotEmpty)
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.mediaUrls.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        state.mediaUrls[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // زر حذف الصورة الصغيرة
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          ref
                              .read(addPropertyProvider.notifier)
                              .removeMediaUrl(index);
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
