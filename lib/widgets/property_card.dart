import 'package:flutter/material.dart';

class PropertyCard extends StatelessWidget {
  final String title;
  final String price;
  final String location;
  final String area;
  final String type;
  final List<String> features; // هذه تبقى كما هي للميزات الإضافية
  final String? imageUrl;

  const PropertyCard({
    Key? key,
    required this.title,
    required this.price,
    required this.location,
    required this.area,
    required this.type,
    required this.features,
    this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة العقار
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image,
                          size: 50, color: Colors.grey),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(price,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800])),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(type,
                          style: TextStyle(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(location,
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis))
                ]),
                const Divider(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 5,
                  children: [
                    _featureChip(Icons.square_foot, "$area م²"),
                    ...features
                        .map((f) => _featureChip(Icons.check_circle_outline, f))
                        .toList(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.blueAccent),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey[100],
      visualDensity: VisualDensity.compact,
    );
  }
}
