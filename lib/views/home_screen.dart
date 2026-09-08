import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aqari_app/widgets/header_widget.dart';
import 'package:aqari_app/widgets/property_card.dart';
import 'package:aqari_app/models/property_models.dart';
import 'package:aqari_app/views/property_details_screen.dart';
import 'package:aqari_app/views/favorites_view.dart';
import 'package:aqari_app/views/profile_screen.dart';
import 'package:aqari_app/features/property/screens/add_property_screen.dart';
import 'package:aqari_app/views/filter_bottom_sheet.dart';
import 'package:aqari_app/utils/property_mapper.dart';

// -----------------------------------------------------------------------------
// تعريف كلاس لتمرير الفلاتر وترتيب البحث
// -----------------------------------------------------------------------------
class FilterParams {
  final Map<String, dynamic> advancedFilters;
  final String sortFilter;

  const FilterParams({
    required this.advancedFilters,
    required this.sortFilter,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterParams &&
          runtimeType == other.runtimeType &&
          sortFilter == other.sortFilter &&
          _mapEquals(advancedFilters, other.advancedFilters);

  @override
  int get hashCode => advancedFilters.hashCode ^ sortFilter.hashCode;

  bool _mapEquals(Map map1, Map map2) {
    if (map1.length != map2.length) return false;
    for (var key in map1.keys) {
      if (!map2.containsKey(key) || map2[key] != map1[key]) return false;
    }
    return true;
  }
}

// -----------------------------------------------------------------------------
// مزود البيانات المحدث للفلترة من سيرفر Supabase
// -----------------------------------------------------------------------------
final filteredPropertiesProvider = FutureProvider.autoDispose
    .family<List<PropertyModel>, FilterParams>((ref, params) async {
  final supabase = Supabase.instance.client;

  var query = supabase.from('properties').select('*');
  final filters = params.advancedFilters;

  // 1. فلتر المحافظة
  if (filters['gov'] != null && filters['gov'].toString().isNotEmpty) {
    query = query.eq('metadata->>المحافظة', filters['gov']);
  }

  // 2. فلتر التصنيف الرئيسي
  if (filters['category'] != null &&
      filters['category'].toString().isNotEmpty) {
    query = query.eq('category_code', filters['category']);
  }

  // 3. فلتر النوع الفرعي
  if (filters['type'] != null && filters['type'].toString().isNotEmpty) {
    query = query.or(
        'metadata->>نوع العقار.eq.${filters['type']},metadata->>type.eq.${filters['type']}');
  }

  // 4. فلتر مستوى التشطيب
  if (filters['finishing'] != null &&
      filters['finishing'].toString().isNotEmpty) {
    query = query.or(
        'metadata->>التشطيب.eq.${filters['finishing']},metadata->>finishing.eq.${filters['finishing']}');
  }

  // 5. فلتر أقل سعر
  if (filters['min_price'] != null &&
      filters['min_price'].toString().isNotEmpty) {
    final minP = double.tryParse(filters['min_price'].toString());
    if (minP != null) query = query.gte('price', minP);
  }

  // 6. فلتر أعلى سعر
  if (filters['max_price'] != null &&
      filters['max_price'].toString().isNotEmpty) {
    final maxP = double.tryParse(filters['max_price'].toString());
    if (maxP != null) query = query.lte('price', maxP);
  }

  // 7. فلتر أقل مساحة
  if (filters['min_area'] != null &&
      filters['min_area'].toString().isNotEmpty) {
    final minA = double.tryParse(filters['min_area'].toString());
    if (minA != null) {
      query = query.gte('metadata->>المساحة', minA);
    }
  }

  // 8. فلتر أكبر مساحة
  if (filters['max_area'] != null &&
      filters['max_area'].toString().isNotEmpty) {
    final maxA = double.tryParse(filters['max_area'].toString());
    if (maxA != null) {
      query = query.lte('metadata->>المساحة', maxA);
    }
  }

  // 9. صفة المعلن
  if (filters['advertiser_type'] != null &&
      filters['advertiser_type'].toString().isNotEmpty) {
    query = query.eq('metadata->>صفة المعلن', filters['advertiser_type']);
  }

  // 10. قابل للتفاوض
  if (filters['is_negotiable'] != null &&
      filters['is_negotiable'].toString().isNotEmpty) {
    query = query.or(
        'metadata->>قابل للتفاوض.eq.${filters['is_negotiable']},metadata->>is_negotiable.eq.${filters['is_negotiable']}');
  }

  // 11. الترتيب بناءً على الفلتر المحدد (افتراضياً الأحدث)
  bool isAscending = params.sortFilter != 'أحدث';
  final orderedQuery = query.order('created_at', ascending: isAscending);

  final response = await orderedQuery.limit(100);
  return (response as List).map((doc) => PropertyModel.fromMap(doc)).toList();
});

// -----------------------------------------------------------------------------
// الشاشة الرئيسية
// -----------------------------------------------------------------------------
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  String _selectedFilter = 'أحدث';
  Map<String, dynamic> _advancedFilters = {};

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PropertyFilterBottomSheet(
          initialFilters: _advancedFilters,
          onApplyFilters: (filters) {
            setState(() {
              _advancedFilters = filters;
            });
          },
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _advancedFilters.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeBody(),
      FavoritesView(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _currentIndex == 0
          ? PreferredSize(
              preferredSize: Size.fromHeight(110),
              child: HeaderWidget(),
            )
          : null,
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFF003366),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: "الرئيسية"),
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite_rounded), label: "المفضلة"),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: "حسابي"),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF003366),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "إضافة إعلان",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHomeBody() {
    final filterParams = FilterParams(
      advancedFilters: _advancedFilters,
      sortFilter: _selectedFilter,
    );

    final propertyAsyncValue =
        ref.watch(filteredPropertiesProvider(filterParams));

    return Column(
      children: [
        _buildFilterHeader(),
        Expanded(
          child: propertyAsyncValue.when(
            data: (filteredProperties) {
              if (filteredProperties.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off_rounded,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        "لا توجد عقارات مطابقة للبحث حالياً",
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.w500),
                      ),
                      if (_advancedFilters.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text("إلغاء الفلاتر وعرض الكل"),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF003366),
                          ),
                        ),
                      ]
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: filteredProperties.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildAdBannerSection();

                  final property = filteredProperties[index - 1];

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsScreen(property: property),
                      ),
                    ),
                    child: PropertyCard(
                      title: property.title,
                      price: "${property.price.toStringAsFixed(0)} ج.م",
                      location: [
                        PropertyMapper.displayFieldValue(
                            'governorate', property.gov),
                        PropertyMapper.displayValue(property.city),
                      ].where((value) => value.trim().isNotEmpty).join(' - '),
                      area: property.area > 0
                          ? property.area.toStringAsFixed(0)
                          : property.metadata['المساحة']?.toString() ?? '0',
                      type: PropertyMapper.displayValue(property.categoryCode),
                      features: _extractFeatures(property),
                      imageUrl: property.images.isNotEmpty
                          ? property.images.first
                          : null,
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF003366)),
            ),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'حدث خطأ في تحميل البيانات: $err',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterHeader() {
    final int activeFiltersCount = _advancedFilters.values
        .where((v) => v != null && v.toString().isNotEmpty)
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF003366),
                side: const BorderSide(color: Color(0xFF003366)),
                backgroundColor: _advancedFilters.isNotEmpty
                    ? const Color(0xFF003366).withOpacity(0.15)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _openFilterBottomSheet,
              icon: const Icon(Icons.filter_list, size: 18),
              label: Text(
                _advancedFilters.isNotEmpty
                    ? "فلتر مفعل ($activeFiltersCount)"
                    : "بحث متقدم",
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (_advancedFilters.isNotEmpty) ...[
            const SizedBox(width: 6),
            IconButton(
              onPressed: _clearFilters,
              icon:
                  const Icon(Icons.close_rounded, color: Colors.red, size: 20),
              tooltip: "إلغاء الفلاتر",
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF003366),
                side: const BorderSide(color: Color(0xFF003366)),
                backgroundColor: _selectedFilter == 'أحدث'
                    ? const Color(0xFF003366).withOpacity(0.15)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  _selectedFilter = _selectedFilter == 'أحدث' ? 'الكل' : 'أحدث';
                });
              },
              icon: Icon(
                _selectedFilter == 'أحدث'
                    ? Icons.check_circle_rounded
                    : Icons.history_rounded,
                size: 18,
              ),
              label: Text(
                _selectedFilter == 'أحدث' ? "الأحدث أولاً" : "ترتيب عادي",
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdBannerSection() {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003366), Color(0xFF004080)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003366).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          "إعلان مميز لشركاء زهرة",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<String> _extractFeatures(PropertyModel property) {
    List<String> features = [];

    final rooms = property.metadata['عدد الغرف'] ??
        property.metadata['rooms'] ??
        property.metadata['عدد_الغرف'];
    if (rooms != null && rooms.toString().trim().isNotEmpty) {
      features.add("${PropertyMapper.displayValue(rooms)} غرف");
    }

    final furnished = property.metadata['مفروش'] ?? property.metadata['is_furnished'];
    if (PropertyMapper.displayValue(furnished) == 'نعم') {
      features.add("مفروش");
    }

    return features;
  }
}
