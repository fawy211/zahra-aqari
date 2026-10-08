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
import 'package:aqari_app/features/property/config/app_config.dart';
import 'package:aqari_app/utils/constants_data.dart';
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
  int get hashCode {
    final entries = advancedFilters.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
    return Object.hash(
      sortFilter,
      Object.hashAll(entries.map((entry) => Object.hash(entry.key, entry.value))),
    );
  }

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

  // Use actual database columns and tolerate legacy governorate/category values.
  final selectedGov = filters['gov']?.toString().trim() ?? '';
  if (selectedGov.isNotEmpty) {
    final govName = ConstantsData.governorates[selectedGov];
    final govCodes = ConstantsData.governorates.entries
        .where((entry) => entry.value == selectedGov)
        .map((entry) => entry.key)
        .toList();
    query = query.inFilter('gov', {
      selectedGov,
      if (govName != null) govName,
      if (govCodes.isNotEmpty) govCodes.first,
    }.toList());
  }

  final selectedCategory = filters['category']?.toString().trim() ?? '';
  if (selectedCategory.isNotEmpty) {
    final categoryName = AppConfig.mainCategories[selectedCategory];
    final categoryCodes = AppConfig.mainCategories.entries
        .where((entry) => entry.value == selectedCategory)
        .map((entry) => entry.key)
        .toList();
    query = query.inFilter('category', {
      selectedCategory,
      if (categoryName != null) categoryName,
      if (categoryCodes.isNotEmpty) categoryCodes.first,
    }.toList());
  }

  final selectedType = filters['type']?.toString().trim() ?? '';
  if (selectedType.isNotEmpty) {
    query = query.eq('type', selectedType);
  }

  // Database rows may use legacy English finishing values.
  final selectedFinishing = filters['finishing']?.toString().trim() ?? '';
  if (selectedFinishing.isNotEmpty) {
    const finishingAliases = <String, List<String>>{
      'متشطب': ['finished'],
      'نصف تشطيب': ['semi_finished'],
      'محارة وحلوق': ['core_shell'],
      'على المحارة': ['core_shell'],
      'بدون تشطيب': ['unfinished'],
      'لوكس': ['lux'],
      'سوبر لوكس': ['super_lux'],
      'الترا سوبر لوكس': ['ultra_super_lux'],
    };
    query = query.inFilter('finishing', {
      selectedFinishing,
      ...(finishingAliases[selectedFinishing] ?? const <String>[]),
    }.toList());
  }

  final selectedCity = filters['city']?.toString().trim() ?? '';
  if (selectedCity.isNotEmpty) {
    query = query.ilike('city', '%$selectedCity%');
  }

  if (filters['min_price'] != null &&
      filters['min_price'].toString().isNotEmpty) {
    final minPrice = double.tryParse(filters['min_price'].toString());
    if (minPrice != null) query = query.gte('price', minPrice);
  }

  if (filters['max_price'] != null &&
      filters['max_price'].toString().isNotEmpty) {
    final maxPrice = double.tryParse(filters['max_price'].toString());
    if (maxPrice != null) query = query.lte('price', maxPrice);
  }

  if (filters['min_area'] != null &&
      filters['min_area'].toString().isNotEmpty) {
    final minArea = double.tryParse(filters['min_area'].toString());
    if (minArea != null) query = query.gte('area', minArea);
  }

  if (filters['max_area'] != null &&
      filters['max_area'].toString().isNotEmpty) {
    final maxArea = double.tryParse(filters['max_area'].toString());
    if (maxArea != null) query = query.lte('area', maxArea);
  }

  if (filters['advertiser_type'] != null &&
      filters['advertiser_type'].toString().isNotEmpty) {
    query = query.eq('advertiser_type', filters['advertiser_type']);
  }

  if (filters['is_negotiable'] != null &&
      filters['is_negotiable'].toString().isNotEmpty) {
    final value = filters['is_negotiable'].toString().toLowerCase();
    final isNegotiable =
        value == 'نعم' || value == 'true' || value == 'yes' || value == '1';
    query = query.eq('is_negotiable', isNegotiable);
  }

  final bool isAscending = params.sortFilter == 'الأقدم';
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
  String _selectedFilter = 'الأحدث';
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
      // Replace the map instead of mutating it: FilterParams uses its contents
      // for Riverpod family equality and hashing.
      _advancedFilters = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeBody(),
      FavoritesView(),
      const SizedBox.shrink(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _currentIndex == 0
          ? PreferredSize(
              preferredSize: Size.fromHeight(110),
              child: HeaderWidget(),
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
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
          onTap: (index) {
            if (index == 2) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              return;
            }
            setState(() => _currentIndex = index);
          },
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
                backgroundColor: _selectedFilter == 'الأحدث'
                    ? const Color(0xFF003366).withOpacity(0.15)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  _selectedFilter =
                      _selectedFilter == 'الأحدث' ? 'الأقدم' : 'الأحدث';
                });
              },
              icon: Icon(
                _selectedFilter == 'الأحدث'
                    ? Icons.check_circle_rounded
                    : Icons.history_rounded,
                size: 18,
              ),
              label: Text(
                _selectedFilter == 'الأحدث' ? "الأحدث أولاً" : "الأقدم أولاً",
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
