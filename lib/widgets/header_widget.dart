import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aqari_app/views/login_screen.dart';
import 'package:aqari_app/views/registration_screen.dart';
import 'package:aqari_app/views/profile_screen.dart';
import 'package:aqari_app/views/MyProperties_View.dart';
import 'package:aqari_app/views/favorites_view.dart';
import 'package:aqari_app/views/settings_screen.dart';
import 'package:aqari_app/features/property/screens/add_property_screen.dart';
import 'package:aqari_app/views/offices_view.dart';
import 'package:aqari_app/views/companies_view.dart';
import 'package:aqari_app/views/subscription_screen.dart';

enum _HeaderMenuAction {
  login,
  register,
  profile,
  myProperties,
  favorites,
  addProperty,
  settings,
  companies,
  offices,
  subscriptions,
  about,
  terms,
  contact,
  logout,
}

class HeaderWidget extends StatefulWidget {
  const HeaderWidget({super.key});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  static const String _supportPhoneDisplay = '01001289572';
  static const String _supportPhoneInternational = '201001289572';

  late final StreamSubscription<AuthState> _authSubscription;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    final auth = Supabase.instance.client.auth;
    _isAuthenticated = auth.currentSession != null;
    _authSubscription = auth.onAuthStateChange.listen((_) {
      if (mounted) {
        setState(() => _isAuthenticated = auth.currentSession != null);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF002244), Color(0xFF003366), Color(0xFF004080)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // أيقونة مصغرة أو شعار جمالي يعطي طابعاً احترافياً
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // الجانب الأول: النصوص والتفاصيل
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "منصة زهرة العقارية",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Text(
                      "أهلاً بك",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text("•",
                          style:
                              TextStyle(color: Colors.white54, fontSize: 10)),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // القائمة الرئيسية
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: PopupMenuButton<_HeaderMenuAction>(
              tooltip: 'القائمة الرئيسية',
              color: Colors.white,
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onSelected: (action) => _handleMenuSelection(context, action),
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<_HeaderMenuAction>>[
                if (_isAuthenticated) ...[
                  _buildPopupMenuItem(
                      _HeaderMenuAction.profile, 'حسابي', Icons.person_outline),
                  _buildPopupMenuItem(_HeaderMenuAction.myProperties,
                      'إعلاناتي', Icons.apartment_outlined),
                  _buildPopupMenuItem(_HeaderMenuAction.favorites,
                      'المفضلة', Icons.favorite_border),
                  _buildPopupMenuItem(_HeaderMenuAction.addProperty,
                      'إضافة إعلان', Icons.add_business_outlined),
                  _buildPopupMenuItem(
                      _HeaderMenuAction.settings, 'الإعدادات', Icons.settings),
                  const PopupMenuDivider(),
                ] else ...[
                  _buildPopupMenuItem(
                      _HeaderMenuAction.login, 'تسجيل الدخول', Icons.login),
                  _buildPopupMenuItem(_HeaderMenuAction.register,
                      'إنشاء حساب جديد', Icons.person_add_outlined),
                  const PopupMenuDivider(),
                ],
                _buildPopupMenuItem(_HeaderMenuAction.companies,
                    'سجل الشركات العقارية', Icons.business),
                _buildPopupMenuItem(_HeaderMenuAction.offices,
                    'سجل المكاتب العقارية', Icons.store),
                _buildPopupMenuItem(_HeaderMenuAction.subscriptions,
                    'الاشتراكات', Icons.card_membership),
                const PopupMenuDivider(),
                _buildPopupMenuItem(
                    _HeaderMenuAction.about, 'من نحن', Icons.info_outline),
                _buildPopupMenuItem(_HeaderMenuAction.terms,
                    'الاشتراطات العامة', Icons.gavel),
                _buildPopupMenuItem(_HeaderMenuAction.contact, 'اتصل بنا',
                    Icons.phone_outlined),
                if (_isAuthenticated) ...[
                  const PopupMenuDivider(),
                  _buildPopupMenuItem(_HeaderMenuAction.logout,
                      'تسجيل الخروج', Icons.logout, isRed: true),
                ],
              ],
              icon: const Icon(Icons.menu_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<_HeaderMenuAction> _buildPopupMenuItem(
      _HeaderMenuAction action, String text, IconData icon,
      {bool isRed = false}) {
    return PopupMenuItem<_HeaderMenuAction>(
      value: action,
      child: Row(
        children: [
          Icon(icon,
              color: isRed ? Colors.red : const Color(0xFF003366), size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isRed ? Colors.red : Colors.grey[800],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenuSelection(
      BuildContext context, _HeaderMenuAction action) async {
    switch (action) {
      case _HeaderMenuAction.login:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        break;

      case _HeaderMenuAction.register:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegistrationScreen()),
        );
        break;

      case _HeaderMenuAction.profile:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;

      case _HeaderMenuAction.myProperties:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MyPropertiesView()),
        );
        break;

      case _HeaderMenuAction.favorites:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FavoritesView()),
        );
        break;

      case _HeaderMenuAction.addProperty:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
        );
        break;

      case _HeaderMenuAction.settings:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;

      case _HeaderMenuAction.companies:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CompaniesView()),
        );
        break;

      case _HeaderMenuAction.offices:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OfficesView()),
        );
        break;

      case _HeaderMenuAction.subscriptions:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SubscriptionScreen()),
        );
        break;

      case _HeaderMenuAction.about:
        _showInfoDialog(
          context,
          title: 'من نحن - منصة زهرة',
          content:
              'منصة زهرة العقارية تساعدك على استكشاف العقارات والتواصل مع الملاك والشركات والمكاتب العقارية في مكان واحد.',
        );
        break;

      case _HeaderMenuAction.terms:
        _showInfoDialog(
          context,
          title: 'الاشتراطات العامة',
          content:
              'يرجى إدخال بيانات صحيحة ومحدثة للعقار والسعر، وعدم نشر إعلانات مضللة أو مكررة. يتحمل المعلن مسؤولية المحتوى الذي ينشره.',
        );
        break;

      case _HeaderMenuAction.contact:
        _showContactOptions(context);
        break;

      case _HeaderMenuAction.logout:
        await _confirmAndSignOut(context);
        break;
    }
  }

  Future<void> _showContactOptions(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'اتصل بنا',
          style: TextStyle(
            color: Color(0xFF003366),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'تواصل مع دعم منصة زهرة على $_supportPhoneDisplay',
          style: TextStyle(height: 1.5),
          textDirection: ui.TextDirection.rtl,
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _launchContact(
                context,
                Uri(scheme: 'tel', path: '+$_supportPhoneInternational'),
              );
            },
            icon: const Icon(Icons.call_outlined),
            label: const Text('اتصال'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _launchContact(
                context,
                Uri.https('wa.me', _supportPhoneInternational),
              );
            },
            icon: const Icon(Icons.chat_outlined, color: Colors.green),
            label: const Text('واتساب'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchContact(BuildContext context, Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح تطبيق التواصل على هذا الجهاز')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح تطبيق التواصل على هذا الجهاز')),
      );
    }
  }

  void _showInfoDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF003366),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(content, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إغلاق',
                style: TextStyle(color: Color(0xFF003366))),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
    if (shouldSignOut != true || !context.mounted) return;

    try {
      await Supabase.instance.client.auth.signOut();
      if (!context.mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تسجيل الخروج: $error')),
      );
    }
  }
}
