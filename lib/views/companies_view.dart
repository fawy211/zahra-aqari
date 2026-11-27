import 'package:flutter/material.dart';
import 'package:aqari_app/models/Company_Model.dart';
import 'package:aqari_app/services/Company_Service.dart';
import 'package:aqari_app/widgets/custom_header.dart';
import 'package:aqari_app/views/company_profile_view.dart';

class CompaniesView extends StatefulWidget {
  const CompaniesView({super.key});

  @override
  State<CompaniesView> createState() => _CompaniesViewState();
}

class _CompaniesViewState extends State<CompaniesView> {
  final TextEditingController _searchController = TextEditingController();
  final CompanyService _companyService = CompanyService();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _companyService.currentUserId;

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
            child: StreamBuilder<List<CompanyModel>>(
              stream: _companyService.getCompanies(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF003366),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('تعذر تحميل قائمة الشركات حالياً'),
                  );
                }

                final companies = (snapshot.data ?? []).where((company) {
                  if (company.ownerId != null &&
                      company.ownerId == currentUserId) {
                    return false;
                  }
                  return company.name.toLowerCase().contains(_searchQuery);
                }).toList()
                  ..sort((a, b) => a.name.compareTo(b.name));

                if (companies.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'لا توجد شركات مسجلة حالياً'
                          : 'لا توجد نتائج مطابقة للبحث',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  itemCount: companies.length,
                  itemBuilder: (context, index) =>
                      _buildCompanyCard(companies[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'ابحث عن شركة عقارية...',
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
            borderSide: const BorderSide(
              color: Color(0xFF003366),
              width: 1.5,
            ),
          ),
        ),
        onChanged: (value) => setState(
          () => _searchQuery = value.trim().toLowerCase(),
        ),
      ),
    );
  }

  Widget _buildCompanyCard(CompanyModel company) {
    final name = company.name;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      shadowColor: Colors.black12,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: () {
          final companyId = company.id;
          final ownerId = company.ownerId;
          if (companyId == null ||
              companyId.isEmpty ||
              ownerId == null ||
              ownerId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('بيانات الشركة غير مكتملة لفتح الملف الشخصي'),
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CompanyProfileView(
                companyId: companyId,
                ownerId: ownerId,
                companyName: name,
              ),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF003366).withOpacity(0.1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'C',
            style: const TextStyle(
              color: Color(0xFF003366),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF003366),
          ),
        ),
        subtitle: Text(
          company.businessField?.isNotEmpty == true
              ? company.businessField!
              : 'شركة عقارية',
          style: TextStyle(color: Colors.blue[800], fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_left, color: Color(0xFF003366)),
      ),
    );
  }
}
