import 'package:flutter/material.dart';
import '../services/favorite_service.dart';

class FavoriteButton extends StatelessWidget {
  final String propertyId;
  final FavoriteService _favoriteService = FavoriteService();

  FavoriteButton({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _favoriteService.isFavorite(propertyId),
      builder: (context, snapshot) {
        // حالة التحقق أو الافتراضية إذا لم تتوفر البيانات بعد
        final isFavorite = snapshot.data ?? false;

        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? Colors.red : Colors.grey,
          ),
          onPressed: () async {
            try {
              await _favoriteService.toggleFavorite(propertyId);
            } catch (e) {
              // إذا لم يكن مسجل الدخول، سيظهر الخطأ الذي أرسلته في الخدمة
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll("Exception: ", "")),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }
}
