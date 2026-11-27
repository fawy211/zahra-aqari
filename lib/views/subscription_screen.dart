import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/subscription_service.dart';
import '../models/subscription_plan.dart';

class SubscriptionScreen extends StatelessWidget {
  final SubscriptionService _subService = SubscriptionService();
  final SupabaseClient _supabase = Supabase.instance.client;

  SubscriptionScreen({super.key});

  // اعرض الحدود الفعلية المخزنة في تعريف الباقة حتى لا تختلف المميزات
  // الظاهرة للمستخدم عن الحدود التي يعتمد عليها التطبيق.
  List<String> _getFeaturesForPlan(SubscriptionPlan plan) {
    final adsLimit = plan.maxAdsPerMonth;
    final videoMinutes = (plan.maxVideoDuration / 60).floor();
    return [
      adsLimit <= 0
          ? "عدد الإعلانات غير محدود"
          : "إضافة حتى $adsLimit إعلانات شهرياً",
      videoMinutes <= 0
          ? "لا يتوفر رفع فيديو لهذه الباقة"
          : "فيديو لكل إعلان بمدة تصل إلى $videoMinutes دقيقة",
    ];
  }

  Future<void> _handleSubscription(BuildContext context, dynamic plan) async {
    // لا نفعّل باقة مدفوعة من العميل قبل ربط بوابة دفع والتحقق server-side.
    if ((plan.price as num) > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              "تفعيل الباقات المدفوعة غير متاح حالياً حتى اكتمال ربط الدفع الآمن."),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
            onPressed: () {
              Navigator.pop(dialogContext);

              // الخطة المجانية لا تُعد عملية دفع ولا تحتاج إلى سجل payments.
              // لا نغيّر اشتراك الحساب من العميل؛ الخطة الافتراضية المجانية متاحة تلقائياً.
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "الخطة المجانية متاحة تلقائياً ولا تحتاج إلى دفع. لم يتم إنشاء عملية مالية أو تغيير بيانات الاشتراك.",
                    ),
                    backgroundColor: Color(0xFF003366),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
          final List<String> planFeatures = _getFeaturesForPlan(plan);

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
