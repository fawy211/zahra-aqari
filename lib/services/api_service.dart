import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// دالة لضغط الصورة محلياً قبل رفعها لتسريع العملية وتقليل المساحة
  static Future<File?> compressImage(File file) async {
    try {
      final filePath = file.path;

      // التأكد من أن الملف بصيغة صورة مدعومة
      if (!filePath.toLowerCase().endsWith('.jpg') &&
          !filePath.toLowerCase().endsWith('.jpeg') &&
          !filePath.toLowerCase().endsWith('.png')) {
        return file;
      }

      final lastIndex = filePath.lastIndexOf(RegExp(r'\.jp'));
      if (lastIndex == -1) {
        final targetPath = '${filePath}_compressed.jpg';
        var result = await FlutterImageCompress.compressAndGetFile(
          filePath,
          targetPath,
          quality: 75,
          minWidth: 1200,
          minHeight: 800,
        );
        if (result == null) return file;
        return File(result.path);
      }

      final splitted = filePath.substring(0, lastIndex);
      final targetPath = '${splitted}_compressed.jpg';

      var compressedFile = await FlutterImageCompress.compressAndGetFile(
        filePath,
        targetPath,
        quality: 75, // ضغط الجودة لـ 75% لتوفير سرعة الرفع
        minWidth: 1200,
        minHeight: 800,
      );

      if (compressedFile == null) return file;
      return File(compressedFile.path);
    } catch (e) {
      debugPrint('خطأ أثناء ضغط الصورة محلياً: $e');
      return file; // في حال حدث خطأ، استخدم الصورة الأصلية
    }
  }

  /// دالة رفع الصورة مباشرة إلى Supabase Storage (Bucket: properties)
  static Future<String?> uploadPropertyImage(File imageFile) async {
    try {
      // 1. ضغط الصورة أولاً
      File? processedImage = await compressImage(imageFile);
      processedImage ??= imageFile;

      // 2. إعداد اسم الملف الفريد
      final String fileName =
          'images/${DateTime.now().millisecondsSinceEpoch}_${processedImage.path.split('/').last}';

      // 3. الرفع مباشرة إلى Supabase Storage
      await _supabase.storage
          .from('properties')
          .upload(fileName, processedImage);

      // 4. الحصول على الرابط العام للصورة (Public URL)
      final String downloadUrl =
          _supabase.storage.from('properties').getPublicUrl(fileName);

      debugPrint('تم رفع الصورة بنجاح إلى Supabase: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('حدث خطأ أثناء رفع الصورة إلى Supabase: $e');
      return null;
    }
  }
}
