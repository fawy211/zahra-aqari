import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription_plan.dart';

class SubscriptionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // مصدر موحد لتعريفات الباقات حتى لا تختلف الأسماء والأسعار
  // والحدود بين شاشة الاشتراك والخدمات الأخرى.
  List<SubscriptionPlan> get availablePlans => SubscriptionPlan.availablePlans;

  /// جلب الخطط من قاعدة بيانات Supabase (مع العودة للقائمة المحلية عند حدوث خطأ)
  Future<List<SubscriptionPlan>> fetchPlans() async {
    try {
      final response = await _supabase.from('subscription_plans').select();

      if ((response as List).isNotEmpty) {
        return (response as List).map((data) {
          return SubscriptionPlan(
            id: data['id']?.toString() ?? '',
            name: data['name'] as String? ?? '',
            price: data['price'] is num
                ? (data['price'] as num).toDouble()
                : double.tryParse('${data['price']}') ?? 0,
            maxAdsPerMonth: data['max_ads_per_month'] is num
                ? (data['max_ads_per_month'] as num).toInt()
                : int.tryParse('${data['max_ads_per_month']}') ?? 0,
            maxVideoDuration: data['max_video_duration'] is num
                ? (data['max_video_duration'] as num).toInt()
                : int.tryParse('${data['max_video_duration']}') ?? 0,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("خطأ في جلب خطط الاشتراكات من الخادم: $e");
    }
    return availablePlans; // العودة للقائمة المحلية في حال الخطأ أو عدم وجود اتصال
  }

  SubscriptionPlan getPlanByName(String planName) {
    return availablePlans.firstWhere(
      (plan) => plan.name == planName,
      orElse: () => availablePlans[0],
    );
  }

  DateTime getExpiryDate({int days = 90}) {
    return DateTime.now().add(Duration(days: days));
  }

  bool canPostNewAd(int currentAdsCount, SubscriptionPlan plan) {
    // The subscription screen treats zero or a negative limit as unlimited.
    // Keep the posting check consistent with the plan description.
    if (plan.maxAdsPerMonth <= 0) return true;
    return currentAdsCount < plan.maxAdsPerMonth;
  }

  bool isVideoValid(int durationSeconds, SubscriptionPlan plan) {
    return durationSeconds <= plan.maxVideoDuration;
  }

  double calculateDiscountedPrice(double originalPrice, int months) {
    double monthlyTotal = originalPrice * months;
    if (months >= 12) return monthlyTotal * 0.80; // خصم 20%
    if (months >= 6) return monthlyTotal * 0.85; // خصم 15%
    if (months >= 3) return monthlyTotal * 0.90; // خصم 10%
    return monthlyTotal;
  }
}
