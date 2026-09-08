import 'dart:io' as io;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_compress/video_compress.dart';
import '../../../models/property_models.dart';

// حالة الجلب (State)
class PropertyState {
  final List<PropertyModel> properties;
  final bool isLoading;
  final int page;
  final bool hasMore;

  PropertyState({
    required this.properties,
    required this.isLoading,
    this.page = 0,
    this.hasMore = true,
  });

  PropertyState copyWith({
    List<PropertyModel>? properties,
    bool? isLoading,
    int? page,
    bool? hasMore,
  }) {
    return PropertyState(
      properties: properties ?? this.properties,
      isLoading: isLoading ?? this.isLoading,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// مُدير الحالة (Notifier)
class PropertyNotifier extends StateNotifier<PropertyState> {
  PropertyNotifier() : super(PropertyState(properties: [], isLoading: false)) {
    fetchMore();
  }

  final int limit = 10;

  Future<void> fetchMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final supabase = Supabase.instance.client;
      final int from = state.page * limit;
      final int to = from + limit - 1;

      final response = await supabase
          .from('properties')
          .select()
          .order('created_at', ascending: false)
          .range(from, to);

      final List<dynamic> data = response as List<dynamic>;

      if (data.isEmpty) {
        state = state.copyWith(isLoading: false, hasMore: false);
        return;
      }

      final newProperties = data
          .map((item) => PropertyModel.fromMap(item as Map<String, dynamic>,
              id: item['id']?.toString()))
          .toList();

      state = state.copyWith(
        properties: [...state.properties, ...newProperties],
        isLoading: false,
        page: state.page + 1,
        hasMore: data.length == limit,
      );
    } catch (e) {
      debugPrint("خطأ في جلب تفاصيل العقارات: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> addProperty(
      PropertyModel property, List<String> imagePaths) async {
    try {
      final supabase = Supabase.instance.client;
      List<String> uploadedImageUrls = [];
      String uploadedVideoUrl = '';

      // 1. رفع الصور إلى Bucket الخاص بالصور (property_images)
      for (String path in imagePaths) {
        final String fileName =
            'images/${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';

        if (kIsWeb) {
          final bytes = await XFile(path).readAsBytes();
          await supabase.storage
              .from('property_images')
              .uploadBinary(fileName, bytes);
        } else {
          final io.File file = io.File(path);
          await supabase.storage.from('property_images').upload(fileName, file);
        }

        final String downloadUrl =
            supabase.storage.from('property_images').getPublicUrl(fileName);
        uploadedImageUrls.add(downloadUrl);
      }

      // 2. معالجة ورفع الفيديو إلى Bucket الخاص بالفيديوهات (property_Videos) مع حماية الواجهة من التهنيج
      Map<String, dynamic> propertyMap = property.toMap();
      String localVideoPath = propertyMap['video'] ?? '';

      if (localVideoPath.isNotEmpty && !localVideoPath.startsWith('http')) {
        if (kIsWeb) {
          final String videoName =
              'videos/${DateTime.now().millisecondsSinceEpoch}_video.mp4';
          final bytes = await XFile(localVideoPath).readAsBytes();
          await supabase.storage
              .from('property_Videos')
              .uploadBinary(videoName, bytes);
          uploadedVideoUrl =
              supabase.storage.from('property_Videos').getPublicUrl(videoName);
        } else {
          final io.File videoFile = io.File(localVideoPath);

          // استخدام Isolates أو تشغيل الضغط في الخلفية لمنع تجميد الشاشة
          MediaInfo? mediaInfo;
          try {
            mediaInfo = await VideoCompress.compressVideo(
              videoFile.path,
              quality: VideoQuality.MediumQuality,
              deleteOrigin: false,
              includeAudio: true,
            );
          } catch (compressError) {
            debugPrint(
                "فشل ضغط الفيديو، سيتم رفع الفيديو الأصلي: $compressError");
          }

          final io.File fileToUpload =
              (mediaInfo != null && mediaInfo.file != null)
                  ? mediaInfo.file!
                  : videoFile;

          final String videoName =
              'videos/${DateTime.now().millisecondsSinceEpoch}_video.mp4';

          await supabase.storage
              .from('property_Videos')
              .upload(videoName, fileToUpload);

          uploadedVideoUrl =
              supabase.storage.from('property_Videos').getPublicUrl(videoName);

          try {
            await VideoCompress.deleteAllCache();
          } catch (_) {}
        }
      } else {
        uploadedVideoUrl = localVideoPath;
      }

      // 3. تجهيز البيانات النهائية للرفع وضبط الـ owner_id
      final authUserId = supabase.auth.currentUser?.id;
      final String currentUserId = (authUserId != null && authUserId.isNotEmpty)
          ? authUserId
          : '00000000-0000-0000-0000-000000000000';

      propertyMap['owner_id'] = currentUserId;
      propertyMap['images'] = uploadedImageUrls;
      propertyMap['video'] = uploadedVideoUrl;
      propertyMap['created_at'] = DateTime.now().toIso8601String();

      propertyMap.remove('id');

      final insertedData = await supabase
          .from('properties')
          .insert(propertyMap)
          .select()
          .single();

      PropertyModel createdProperty = PropertyModel.fromMap(
        insertedData,
        id: insertedData['id']?.toString(),
      );

      state = state.copyWith(
        properties: [createdProperty, ...state.properties],
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint("========== خطأ في إضافة ونشر العقار ==========");
      debugPrint(e.toString());
      debugPrint("Stack trace: $stackTrace");
      debugPrint("========================================");
      return false;
    }
  }
}

final propertyProvider = StateNotifierProvider<PropertyNotifier, PropertyState>(
  (ref) => PropertyNotifier(),
);
