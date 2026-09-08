import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_property_screen.dart'; // تأكد من إنشاء أو تعديل هذه الشاشة لاحقاً لتتوافق مع Supabase
import '../models/property_models.dart';

// تعريف كلاس الخدمة للتعامل مع قاعدة بيانات Supabase
class PropertyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // دالة تعديل العقار
  Future<void> updateProperty(
      String propertyId, Map<String, dynamic> data) async {
    await _supabase.from('properties').update(data).eq('id', propertyId);
  }

  // دالة حذف العقار
  Future<void> deleteProperty(String propertyId) async {
    await _supabase.from('properties').delete().eq('id', propertyId);
  }
}

class MyPropertiesView extends StatelessWidget {
  MyPropertiesView({super.key});

  final PropertyService _propertyService = PropertyService();
  final String currentUserId =
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  Widget build(BuildContext context) {
    if (currentUserId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("إعلاناتي", style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF003366),
          centerTitle: true,
        ),
        body: const Center(
          child: Text("يرجى تسجيل الدخول لعرض إعلاناتك"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "إعلاناتي",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF003366),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // استخدام StreamBuilder للاستماع الفوري للتغيرات في جدول properties عبر Supabase
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('properties')
            .stream(primaryKey: ['id']).eq('userId', currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF003366),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text("حدث خطأ: ${snapshot.error}"));
          }

          final docs = snapshot.data ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "ليس لديك أي إعلانات مضافة حتى الآن",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];

              final property = PropertyModel(
                id: data['id'].toString(),
                title: data['title'] ?? 'بدون عنوان',
                price: (data['price'] ?? 0.0).toDouble(),
                description: data['description']?.toString() ?? '',
                categoryCode: data['categoryCode']?.toString() ?? '',
                type: data['type']?.toString() ?? '',
                finishing: data['finishing']?.toString() ?? '',
                area: (data['area'] ?? 0).toDouble(),
                gov: data['gov']?.toString() ?? '',
                city: data['city']?.toString() ?? '',
                street: data['street']?.toString() ?? '',
                advertiserType: data['advertiserType']?.toString() ?? '',
                phone: data['phone']?.toString() ?? '',
                images: data['images'] is List
                    ? List<String>.from(data['images'])
                    : <String>[],
                ownerId: data['ownerId']?.toString() ?? currentUserId,
                metadata: data['metadata'] is Map
                    ? Map<String, dynamic>.from(data['metadata'])
                    : <String, dynamic>{},
              );

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    property.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF003366),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "السعر: ${property.price} جنيه",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر التعديل
                      IconButton(
                        icon:
                            const Icon(Icons.edit_rounded, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditPropertyScreen(property: property),
                            ),
                          );
                        },
                      ),
                      // زر الحذف
                      IconButton(
                        icon:
                            const Icon(Icons.delete_rounded, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: const Text("حذف الإعلان"),
                              content: const Text(
                                  "هل أنت متأكد من رغبتك في حذف هذا الإعلان؟"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("إلغاء",
                                      style: TextStyle(color: Colors.grey)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    "حذف",
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await _propertyService
                                  .deleteProperty(property.id!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("تم حذف الإعلان بنجاح"),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("فشل الحذف: $e"),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
