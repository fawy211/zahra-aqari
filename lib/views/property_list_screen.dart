import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:aqari_app/features/property/providers/property_provider.dart';
import 'package:aqari_app/models/property_models.dart';
import 'package:aqari_app/views/property_details_screen.dart';

class PropertyListScreen extends ConsumerStatefulWidget {
  const PropertyListScreen({super.key});

  @override
  ConsumerState<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends ConsumerState<PropertyListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // جلب الدفعة التالية تلقائياً عند الاقتراب من نهاية القائمة
        ref.read(propertyProvider.notifier).fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertyState = ref.watch(propertyProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'زهرة العقاري',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF003366),
        centerTitle: true,
        elevation: 0,
      ),
      body: propertyState.properties.isEmpty && propertyState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF003366)),
            )
          : propertyState.properties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        "لا توجد عقارات مضافة حالياً",
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: propertyState.properties.length +
                      (propertyState.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < propertyState.properties.length) {
                      return _PropertyCard(
                          property: propertyState.properties[index]);
                    } else {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF003366)),
                        ),
                      );
                    }
                  },
                ),
    );
  }
}

// كارت العقار بتصميم أنيق
class _PropertyCard extends StatelessWidget {
  final PropertyModel property;
  const _PropertyCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'ar_EG', symbol: 'ج.م');
    final String imageUrl = property.metadata['imageUrl'] ?? '';
    final bool isFeatured = property.isFeatured;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailsScreen(property: property),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 180,
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF003366)),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 180,
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.broken_image_rounded,
                                color: Colors.grey),
                          ),
                        )
                      : Container(
                          height: 180,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: Icon(Icons.home_rounded,
                                size: 50, color: Color(0xFF003366)),
                          ),
                        ),
                ),
                if (isFeatured)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF003366),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded,
                              color: Color(0xFFC5A059), size: 16),
                          SizedBox(width: 4),
                          Text(
                            "مميز",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currencyFormat.format(property.price),
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(0, 51, 102, 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          property.metadata['type'] ?? '',
                          style: const TextStyle(
                            color: Color(0xFF003366),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
