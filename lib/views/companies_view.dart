import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aqari_app/widgets/custom_header.dart';

class CompaniesView extends StatefulWidget {
  const CompaniesView({super.key});

  @override
  State<CompaniesView> createState() => _CompaniesViewState();
}

class _CompaniesViewState extends State<CompaniesView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final SupabaseClient _supabase = Supabase.instance.client;
  late final String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = _supabase.auth.currentUser?.id;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: const HeaderWidget(),
      ),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // الشركات محفوظة في جدول companies، لا في جدول users القديم.
              stream: _supabase.from('companies').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF003366)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "حدث خطأ في تحميل البيانات:\n${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ),
                  );
                }

                final allData = snapshot.data ?? [];

                if (allData.isEmpty) {
                  return const Center(
                    child: Text("لا توجد شركات مسجلة حالياً",
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                // استبعاد شركة المستخدم الحالي، ثم البحث والترتيب محلياً.
                final docs = allData.where((data) {
                  final ownerId = data['owner_id']?.toString() ?? '';
                  if (ownerId.isNotEmpty && ownerId == currentUserId) {
                    return false;
                  }
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList()
                  ..sort((a, b) {
                    final nameA = (a['name'] ?? '').toString();
                    final nameB = (b['name'] ?? '').toString();
                    return nameA.compareTo(nameB);
                  });

                if (docs.isEmpty) {
                  return const Center(
                    child: Text("لا توجد نتائج مطابقة للبحث",
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    return _buildCompanyCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // شريط البحث بتصميم أنيق
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'ابحث عن شركة عقارية...',
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF003366)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF003366), width: 1.5),
          ),
        ),
        onChanged: (value) =>
            setState(() => _searchQuery = value.trim().toLowerCase()),
      ),
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> data) {
    final rawName = data['name']?.toString().trim() ?? '';
    final displayName = rawName.isEmpty ? 'شركة عقارية' : rawName;
    final commercialRegister =
        data['commercial_register']?.toString().trim() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      shadowColor: Colors.black12,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF003366).withOpacity(0.1),
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C',
            style: const TextStyle(
              color: Color(0xFF003366),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF003366),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            commercialRegister.isNotEmpty
                ? 'السجل التجاري: $commercialRegister'
                : 'شركة عقارية',
            style: TextStyle(
              color: Colors.blue[800],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
