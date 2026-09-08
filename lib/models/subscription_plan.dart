class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final int maxAdsPerMonth;
  final int maxVideoDuration; // بالثواني

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.maxAdsPerMonth,
    required this.maxVideoDuration,
  });

  // تعريف الباقات الثابتة مع إضافة الـ ID
  static const List<SubscriptionPlan> availablePlans = [
    SubscriptionPlan(
      id: 'free',
      name: 'مجانية',
      price: 0,
      maxAdsPerMonth: 1,
      maxVideoDuration: 60,
    ),
    SubscriptionPlan(
      id: 'general',
      name: 'عامة',
      price: 150,
      maxAdsPerMonth: 5,
      maxVideoDuration: 180,
    ),
    SubscriptionPlan(
      id: 'offices',
      name: 'مكاتب',
      price: 250,
      maxAdsPerMonth: 10,
      maxVideoDuration: 300,
    ),
    SubscriptionPlan(
      id: 'companies',
      name: 'شركات',
      price: 500,
      maxAdsPerMonth: 20,
      maxVideoDuration: 300,
    ),
  ];
}
