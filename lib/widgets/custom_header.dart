import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("زهرة عقاري"),
      // تم حذف الـ actions التي كانت تحتوي على القائمة القديمة غير الفعالة
      // الآن سيظهر زر القائمة الجانبية (Drawer) تلقائياً إذا كان معرفاً في الـ Scaffold
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
