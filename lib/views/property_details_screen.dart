import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart' as intl;
import '../models/property_models.dart';
import 'Chat_Screen.dart';
import 'payment_screen.dart';
import 'Edit_Property_Screen.dart' as edit;
import '../services/property_service.dart';
import '../services/favorite_service.dart';
import '../utils/property_mapper.dart';

class DetailsScreen extends StatefulWidget {
  final PropertyModel property;

  const DetailsScreen({super.key, required this.property});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  int _currentImageIndex = 0;
  final PropertyService _propertyService = PropertyService();
  final FavoriteService _favoriteService = FavoriteService();
  bool _isLoading = false;
  late PropertyModel _currentProperty;
  late final Stream<bool> _favoriteStream;

  @override
  void initState() {
    super.initState();
    _currentProperty = widget.property;
    _favoriteStream = _favoriteService.isFavorite(_currentProperty.id ?? '');
  }

  String formatPrice(dynamic price) {
    if (price == null) return '0';
    final numPrice = num.tryParse(price.toString()) ?? 0;
    final formatter = intl.NumberFormat('#,###', 'en_US');
    return formatter.format(numPrice);
  }

  String _translateKey(String key) {
    final translated = PropertyMapper.translateKey(key);
    if (translated != key) return translated;

    switch (key.toLowerCase().trim()) {
      case 'bathrooms':
      case 'عدد الحمامات':
        return 'عدد الحمامات';
      case 'transaction_type':
      case 'نوع المعاملة':
        return 'نوع المعاملة';
      case 'property_category':
      case 'category':
      case 'category_code':
      case 'التصنيف':
        return 'التصنيف';
      case 'area':
      case 'المساحة':
        return 'المساحة';
      case 'price':
      case 'السعر':
        return 'السعر';
      default:
        return key;
    }
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("حذف الإعلان", style: TextStyle(color: Colors.red)),
        content: const Text(
            "هل أنت متأكد من رغبتك في حذف هذا الإعلان؟ لا يمكن التراجع عن هذا الإجراء."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("حذف"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _propertyService.deleteProperty(_currentProperty.id ?? '');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("✅ تم حذف الإعلان بنجاح"),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("❌ حدث خطأ أثناء الحذف: $e"),
              backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToEdit() async {
    final updatedProperty = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => edit.EditPropertyScreen(
          property: _currentProperty.copyWith(),
        ),
      ),
    );

    if (updatedProperty is PropertyModel) {
      setState(() {
        _currentProperty = updatedProperty;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ تم تحديث تفاصيل الإعلان بنجاح"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// التعامل مع عملية تبديل المفضلة مع معالجة الأخطاء محسّنة
  void _handleToggleFavorite() async {
    final propertyId = _currentProperty.id;
    
    // تحقق أولاً من أن الـ ID موجود
    if (propertyId == null || propertyId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ خطأ: معرّف العقار غير موجود"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      await _favoriteService.toggleFavorite(propertyId);
      if (!mounted) return;
      // رسالة نجاح إضافية (اختيارية)
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text("✅ تم تحديث المفضلة"),
      //     backgroundColor: Colors.green,
      //     duration: Duration(seconds: 1),
      //   ),
      // );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;
    final bool isOwner =
        currentUserId != null && currentUserId == _currentProperty.ownerId;

    final String propertyTitle = _currentProperty.title;
    final String formattedPrice = formatPrice(_currentProperty.price);
    final String propertyType =
        PropertyMapper.displayValue(_currentProperty.type);
    final String propertyArea = _currentProperty.area.toStringAsFixed(0);

    final List<MapEntry<String, String>> detailsList = [];
    final Set<String> addedKeys = {};

    void addDetail(String key, dynamic value, {String? valueKey}) {
      if (value != null) {
        final valStr = PropertyMapper.displayFieldValue(valueKey ?? key, value);
        final canonical = PropertyMapper.canonicalKey(key);

        if (valStr.isNotEmpty &&
            valStr.toLowerCase() != 'null' &&
            valStr.toUpperCase() != 'EMPTY' &&
            !addedKeys.contains(canonical)) {
          addedKeys.add(canonical);
          detailsList.add(MapEntry(key, valStr));
        }
      }
    }

    addDetail('التشطيب', _currentProperty.finishing, valueKey: 'finishing');
    addDetail('المدينة', _currentProperty.city);

    final String govValue = _currentProperty.gov.isNotEmpty
        ? _currentProperty.gov
        : _currentProperty.metadata['gov']?.toString() ??
            _currentProperty.metadata['governorate']?.toString() ??
            '';
    if (govValue.isNotEmpty) {
      addDetail('المحافظة', govValue, valueKey: 'governorate');
    }

    addDetail('الشارع', _currentProperty.street);
    addDetail('صفة المعلن', _currentProperty.advertiserType,
        valueKey: 'advertiser_type');

    final Map<String, dynamic> meta = _currentProperty.metadata;

    dynamic firstMetadataValue(List<String> aliases) {
      for (final alias in aliases) {
        for (final entry in meta.entries) {
          if (PropertyMapper.canonicalKey(entry.key) ==
              PropertyMapper.canonicalKey(alias)) {
            final value = entry.value;
            if (value != null && value.toString().trim().isNotEmpty) {
              return value;
            }
          }
        }
      }
      return null;
    }

    addDetail('الدور', firstMetadataValue(
        ['floor', 'floors', 'الطابق', 'الطوابق', 'الدور']),
        valueKey: 'floor');
    addDetail('عدد الغرف',
        firstMetadataValue(['rooms', 'room', 'عدد الغرف', 'عدد_الغرف']),
        valueKey: 'rooms');
    addDetail('المرافق',
        firstMetadataValue(
            ['utilities', 'utility', 'المرافق', 'المرافق العامة']),
        valueKey: 'utilities');
    addDetail('الكماليات',
        firstMetadataValue(
            ['amenities', 'amenties', 'amenity', 'الكماليات']),
        valueKey: 'amenities');
    addDetail('قابل للتفاوض',
        firstMetadataValue(
            ['is_negotiable', 'قابل للتفاوض', 'قابل_للتفاوض']),
        valueKey: 'is_negotiable');
    addDetail('مفروش',
        firstMetadataValue(['is_furnished', 'مفروش']),
        valueKey: 'is_furnished');
    addDetail('نوع المعاملة',
        firstMetadataValue(['transaction_type', 'نوع المعاملة']),
        valueKey: 'transaction_type');
    addDetail('طريقة التواصل',
        firstMetadataValue(['contact_method', 'طريقة التواصل']),
        valueKey: 'contact_method');

    meta.forEach((key, value) {
      final canonicalKey = PropertyMapper.canonicalKey(key);

      const ignoredKeys = {
        'type',
        'property_type',
        'category',
        'category_code',
        'property_category',
        'area',
        'price',
        'title',
        'description',
        'phone',
        'images',
        'imageurl',
        'finishing',
        'التشطيب',
        'city',
        'المدينة',
        'gov',
        'governorate',
        'المحافظة',
        'street',
        'الشارع',
        'advertiser_type',
        'صفة المعلن',
        'contact_method',
        'rooms',
        'room',
        'عدد الغرف',
        'floor',
        'floors',
        'الطابق',
        'الطوابق',
        'owner_id',
        'id',
        'created_at',
        'is_negotiable',
        'قابل للتفاوض',
        'قابل_للتفاوض',
        'is_furnished',
        'مفروش',
        'amenities',
        'amenties',
        'amenity',
        'الكماليات',
        'utilities',
        'utility',
        'المرافق',
        'المرافق العامة',
        'transaction_type',
        'نوع المعاملة',
        'code',
      };

      if (!ignoredKeys.contains(key.toLowerCase().trim()) &&
          !{
            'finishing',
            'city',
            'governorate',
            'street',
            'advertiser_type',
            'contact_method',
            'rooms',
            'floor',
            'is_negotiable',
            'is_furnished',
            'amenities',
            'utilities',
            'transaction_type',
          }.contains(canonicalKey)) {
        String readableKey = _translateKey(key);
        addDetail(readableKey, value, valueKey: key);
      }
    });

    List<String> imagesList = _currentProperty.images;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: const Color(0xFF003366),
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      imagesList.isNotEmpty
                          ? PageView.builder(
                              itemCount: imagesList.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return CachedNetworkImage(
                                  imageUrl: imagesList[index],
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(
                                    child: CircularProgressIndicator(
                                        color: Color(0xFF003366)),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                          Icons.broken_image_rounded,
                                          size: 48,
                                          color: Colors.grey)),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported,
                                  size: 48, color: Colors.grey),
                            ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black54, Colors.transparent],
                            stops: [0.0, 0.4],
                          ),
                        ),
                      ),
                      if (imagesList.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: imagesList.asMap().entries.map((entry) {
                              return Container(
                                width: _currentImageIndex == entry.key ? 20 : 8,
                                height: 8,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: _currentImageIndex == entry.key
                                      ? const Color(0xFFC5A059)
                                      : Colors.white.withOpacity(0.5),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  if (isOwner) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.4),
                          shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 20),
                        tooltip: 'تعديل الإعلان',
                        onPressed: _navigateToEdit,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.4),
                          shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.delete_rounded,
                            color: Colors.white, size: 20),
                        tooltip: 'حذف الإعلان',
                        onPressed: _confirmAndDelete,
                      ),
                    ),
                  ],
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded,
                          color: Colors.white),
                      onPressed: () {
                        Share.share(
                            'شاهد هذا العقار الرائع "$propertyTitle" بسعر $formattedPrice ج.م على تطبيق زهرة العقاري.');
                      },
                    ),
                  ),
                  StreamBuilder<bool>(
                    stream: _favoriteStream,
                    builder: (context, snapshot) => Container(
                      margin: const EdgeInsets.only(left: 12, right: 4),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle),
                      child: IconButton(
                        icon: Icon(
                          snapshot.data == true
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: Colors.redAccent,
                        ),
                        onPressed: _handleToggleFavorite,
                      ),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        propertyTitle,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$formattedPrice ج.م',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003366).withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF003366).withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildQuickFeature(
                                Icons.category_rounded, "النوع", propertyType),
                            if (propertyArea.isNotEmpty &&
                                propertyArea != '0.0')
                              _buildQuickFeature(Icons.square_foot_rounded,
                                  "المساحة", "$propertyArea م²"),
                          ],
                        ),
                      ),
                      const Divider(height: 35, thickness: 1),
                      if (isOwner) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: const Icon(
                                Icons.workspace_premium_rounded,
                                color: Color(0xFFC5A059)),
                            label: const Text(
                              "تمييز هذا الإعلان وزيادة مشاهداته",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentScreen(
                                      propertyId: _currentProperty.id ?? ''),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      if (detailsList.isNotEmpty) ...[
                        const Text(
                          "تفاصيل إضافية",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: detailsList.map((entry) {
                            return Chip(
                              avatar: const Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: Color(0xFFC5A059)),
                              label: Text("${entry.key}: ${entry.value}",
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              backgroundColor: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                    color: Colors.grey.shade300),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                      const Text(
                        "وصف العقار",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentProperty.description.isNotEmpty
                            ? _currentProperty.description
                            : "لا يوجد وصف إضافي لهذا العقار.",
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                            height: 1.6),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFC5A059)),
              ),
            ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: isOwner
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.delete_rounded),
                      label: const Text("حذف الإعلان",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: _confirmAndDelete,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text("تعديل الإعلان",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: _navigateToEdit,
                    ),
                  ),
                ],
              )
            : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5A059),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.forum_rounded),
                label: const Text("تواصل مع المعلن",
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                onPressed: () => _showContactOptions(context),
              ),
      ),
    );
  }

  Widget _buildQuickFeature(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF003366), size: 26),
        const SizedBox(height: 6),
        Text(title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF003366))),
      ],
    );
  }

  void _showContactOptions(BuildContext context) {
    final String phone = _currentProperty.phone;
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text(
              "اختر وسيلة التواصل المناسبة",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFF003366).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.chat_bubble_rounded,
                    color: Color(0xFF003366)),
              ),
              title: const Text("محادثة فورية داخل التطبيق",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("دردشة مباشرة مع مالك العقار",
                  style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId:
                          "chat_${currentUserId}_${_currentProperty.ownerId}",
                      otherUserName: "مالك العقار",
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 15),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.message_rounded, color: Colors.green),
              ),
              title: const Text("مراسلة عبر واتساب",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("فتح المحادثة فوراً على الواتساب",
                  style: TextStyle(fontSize: 12)),
              onTap: () async {
                Navigator.pop(context);
                if (phone.isNotEmpty) {
                  String formattedPhone = phone.replaceAll(RegExp(r'\s+'), '');
                  if (formattedPhone.startsWith('01')) {
                    formattedPhone = '+20$formattedPhone';
                  }
                  final whatsappUrl = Uri.parse(
                      "https://wa.me/$formattedPhone?text=${Uri.encodeComponent('مرحباً، أنا مهتم بالعقار "${_currentProperty.title}" المعروض على تطبيق زهرة العقاري.')}");
                  if (await canLaunchUrl(whatsappUrl)) {
                    await launchUrl(whatsappUrl,
                        mode: LaunchMode.externalApplication);
                  }
                }
              },
            ),
            const Divider(height: 15),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.phone_rounded, color: Colors.blue),
              ),
              title: const Text("اتصال هاتفي مباشر",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("التواصل عبر الاتصال العادي",
                  style: TextStyle(fontSize: 12)),
              onTap: () async {
                Navigator.pop(context);
                if (phone.isNotEmpty) {
                  final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
                  final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);
                  if (await canLaunchUrl(launchUri)) {
                    await launchUrl(launchUri);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
