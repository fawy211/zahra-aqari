import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/subscription_service.dart';

class SubscriptionScreen extends StatelessWidget {
  final SubscriptionService _subService = SubscriptionService();
  final SupabaseClient _supabase = Supabase.instance.client;

  SubscriptionScreen({super.key});

  // دالة لإرجاع مميزات كل باقة بناءً على اسمها بدقة (تدعم المسميات الجديدة والقديمة)
  List<String> _getFeaturesForPlan(String planName) {
    if (planName.contains("المجانية") ||
        planName.contains("المشتركين") ||
        planName.contains("مجانية")) {
      return [
        "إضافة 3 إعلانات شهرياً",
        "فيديو خاص بكل إعلان لا تتجاوز مدته 60 ثانية",
      ];
    } else if (planName.contains("العامة") || planName.contains("عامة")) {
      return [
        "إضافة 10 إعلانات شهرياً",
        "فيديو خاص بكل إعلان لا تتجاوز مدته 180 ثانية",
        "إمكانية زيادة عدد الإعلانات بتكلفة 10 ج.م لكل اعلان",
      ];
    } else if (planName.contains("المميزة") || planName.contains("مكاتب")) {
      return [
        "إضافة 25 اعلان شهريا",
        "فيديو خاص بكل اعلان لا تتجاوز مدته 180 ثانية",
        "إمكانية زيادة عدد الإعلانات بتكلفة 10 ج.م لكل اعلان",
      ];
    } else if (planName.contains("الذهبية") || planName.contains("شركات")) {
      return [
        "اضافة عدد غير محدد من الاعلانات",
        "تميز عدد 5 اعلانات من اختيار العميل",
        "فيديو خاص بكل اعلان لا تتجاوز مدته 300 ثانية",
      ];
    } else {
      return [
        "إضافة إعلانات عقارية مخصصة",
        "عرض تفاصيل التواصل الكاملة",
      ];
    }
  }

  Future<void> _handleSubscription(BuildContext context, dynamic plan) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("يرجى تسجيل الدخول أولاً للاشتراك في الباقة"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final currencyFormat =
        NumberFormat.currency(locale: 'ar_EG', symbol: 'ج.م');
    final String priceText =
        plan.price == 0 ? "مجاناً" : currencyFormat.format(plan.price);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "تأكيد الاشتراك",
          style:
              TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold),
        ),
        content: Text("هل تود الاشتراك في ${plan.name} بقيمة $priceText؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                // 1. تسجيل عملية الدفع في جدول payments
                await _supabase.from('payments').insert({
                  'userId': user.id,
                  'title': 'اشتراك باقة: ${plan.name}',
                  'amount': plan.price,
                  'timestamp': DateTime.now().toIso8601String(),
                });

                // 2. تحديث بيانات المستخدم في جدول users
                await _supabase.from('users').update({
                  'subscriptionPlan': plan.name,
                  'subscriptionDate': DateTime.now().toIso8601String(),
                }).eq('id', user.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("تم الاشتراك في ${plan.name} بنجاح!"),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text("حدث خطأ أثناء عملية الاشتراك: ${e.toString()}"),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'ar_EG', symbol: 'ج.م');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'الاشتراك فى منصة زهره العقارية',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF003366),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _subService.availablePlans.length,
        itemBuilder: (context, index) {
          final plan = _subService.availablePlans[index];
          final bool isFree = plan.price == 0;
          final List<String> planFeatures = _getFeaturesForPlan(plan.name);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          plan.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                      ),
                      // شارة مخصصة للباقات المدفوعة والمجانية
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              (isFree ? Colors.green : const Color(0xFFC5A059))
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isFree ? "خدمة مجانية" : "باقة مميزة",
                          style: TextStyle(
                            color: isFree
                                ? Colors.green.shade700
                                : const Color(0xFFC5A059),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isFree
                        ? "مجاناً"
                        : '${currencyFormat.format(plan.price)} / شهر',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isFree
                          ? Colors.green.shade700
                          : const Color(0xFF003366),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1),
                  ),
                  const Text(
                    "مميزات الباقة:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...planFeatures.map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: isFree
                                    ? Colors.green
                                    : const Color(0xFFC5A059),
                                size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (!isFree) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC5A059),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _handleSubscription(context, plan),
                        child: const Text(
                          'اشترك الآن',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "متاحة لك تلقائياً",
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
