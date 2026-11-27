import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aqari_app/features/property/screens/add_property_screen.dart';
import 'package:aqari_app/views/add_delegate_screen.dart';

class CompanyAdminDashboard extends StatelessWidget {
  final String companyId;

  const CompanyAdminDashboard({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "لوحة تحكم الشركة",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildQuickStatsSection(),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildMenuGridItem(
                  context,
                  "المندوبون",
                  Icons.people_rounded,
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddDelegateScreen(companyId: companyId),
                      ),
                    );
                  },
                ),
                _buildMenuGridItem(
                  context,
                  "إضافة عقار",
                  Icons.add_business_rounded,
                  Colors.teal,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddPropertyScreen(companyId: companyId),
                      ),
                    );
                  },
                ),
                _buildMenuGridItem(
                  context,
                  "الرسائل",
                  Icons.chat_bubble_rounded,
                  Colors.orange,
                  () {},
                ),
                _buildMenuGridItem(
                  context,
                  "إحصائيات",
                  Icons.bar_chart_rounded,
                  Colors.purple,
                  () {},
                ),
                _buildMenuGridItem(
                  context,
                  "الاشتراك",
                  Icons.payment_rounded,
                  Colors.green,
                  () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    final supabase = Supabase.instance.client;

    final ownerId = supabase.auth.currentUser?.id;

    if (ownerId == null) {
      return _statsContainer(0, 0);
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('properties')
          .stream(primaryKey: ['id'])
          .eq('owner_id', ownerId)
          .eq('metadata->>company_id', companyId),
      builder: (context, propertySnapshot) {
        final propertiesCount =
            propertySnapshot.hasData ? propertySnapshot.data!.length : 0;

        return FutureBuilder<Map<String, dynamic>?>(
          future: supabase
              .from('workspaces')
              .select('id')
              .eq('company_id', companyId)
              .eq('workspace_type', 'company')
              .maybeSingle(),
          builder: (context, workspaceSnapshot) {
            final workspaceId =
                workspaceSnapshot.data?['id']?.toString();

            if (workspaceId == null) {
              return _statsContainer(propertiesCount, 0);
            }

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('workspace_members')
                  .stream(primaryKey: ['workspace_id', 'user_id'])
                  .eq('workspace_id', workspaceId),
              builder: (context, membersSnapshot) {
                final members = membersSnapshot.data ?? [];
                final delegatesCount =
                    members.where((member) => member['role'] != 'owner').length;
                return _statsContainer(propertiesCount, delegatesCount);
              },
            );
          },
        );
      },
    );
  }

  Widget _statsContainer(int propertiesCount, int delegatesCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(
              "عقارات", propertiesCount.toString(), const Color(0xFF003366)),
          _statItem("رسائل", "0", Colors.orange),
          _statItem("أعضاء الفريق", delegatesCount.toString(), Colors.teal),
        ],
      ),
    );
  }

  Widget _statItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMenuGridItem(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF003366),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
