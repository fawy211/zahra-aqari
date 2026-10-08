import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/favorite_service.dart';
import 'package:aqari_app/views/property_details_screen.dart';
import 'package:aqari_app/models/property_models.dart';

class FavoritesView extends StatelessWidget {
  final FavoriteService _service = FavoriteService();

  FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "عقاراتي المفضلة",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.getFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF003366)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "لا توجد عقارات في المفضلة",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "العقارات التي ستعجبك وتحفظها ستظهر هنا",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final favDocs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favDocs.length,
            itemBuilder: (context, index) {
              final favData = favDocs[index];
              final String propertyId =
                  favData['propertyId'] ?? favData['property_id'];

              return FutureBuilder<Map<String, dynamic>?>(
                future: Supabase.instance.client
                    .from('properties')
                    .select()
                    .eq('id', propertyId)
                    .maybeSingle(),
                builder: (context, propertySnapshot) {
                  if (propertySnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Container(
                      height: 90,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF003366),
                          ),
                        ),
                      ),
                    );
                  }

                  if (!propertySnapshot.hasData ||
                      propertySnapshot.data == null) {
                    return const SizedBox.shrink();
                  }

                  final propData = propertySnapshot.data!;
                  // PropertyModel.fromMap now expects a single map argument;
                  // include the id in the map so the model can read it.
                  final mergedData = Map<String, dynamic>.from(propData);
                  mergedData['id'] = propertyId;
                  final property = PropertyModel.fromMap(mergedData);
                  final String imageUrl = (propData['imageUrl'] ??
                      propData['image'] ??
                      '') as String;

                  return Dismissible(
                    key: Key(propertyId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    onDismissed: (direction) {
                      _service.toggleFavorite(propertyId);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailsScreen(property: property),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          width: 75,
                                          height: 75,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stack) =>
                                                  Container(
                                            width: 75,
                                            height: 75,
                                            color: Colors.grey[100],
                                            child: const Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 75,
                                          height: 75,
                                          color: Colors.grey[100],
                                          child: const Icon(
                                            Icons.home_work_outlined,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        property.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF003366),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "${property.price} ج.م",
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.favorite_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () =>
                                      _service.toggleFavorite(propertyId),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
