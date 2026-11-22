import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/admin_service.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final AdminService _adminService = AdminService();
  late Future<List<Map<String, dynamic>>> _adminsFuture;
  bool _authorized = false;
  bool _checkingAccess = true;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      final allowed = await _adminService.isSuperAdmin();
      if (!mounted) return;
      setState(() {
        _authorized = allowed;
        _checkingAccess = false;
        if (allowed) _adminsFuture = _loadAdmins();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _authorized = false;
        _checkingAccess = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadAdmins() {
    return _adminService.listAdmins();
  }

  void _refresh() {
    setState(() => _adminsFuture = _loadAdmins());
  }

  Future<void> _showAddAdminDialog() async {
    final idController = TextEditingController();
    String selectedRole = 'moderator';
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة مشرف'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'أدخل معرّف المستخدم (UUID) لحساب موجود بالفعل في التطبيق.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: idController,
                  decoration: const InputDecoration(
                    labelText: 'معرّف المستخدم',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final id = value?.trim() ?? '';
                    final uuid = RegExp(
                      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
                    );
                    if (!uuid.hasMatch(id)) return 'أدخل UUID صحيحاً.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'الدور',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'moderator',
                      child: Text('مشرف'),
                    ),
                    DropdownMenuItem(
                      value: 'super_admin',
                      child: Text('مشرف أعلى'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedRole = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      try {
        await _adminService.addAdmin(idController.text, selectedRole);
        if (!mounted) return;
        _refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة المشرف بنجاح.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذرت إضافة المشرف: $e')),
        );
      }
    }
    idController.dispose();
  }

  Future<void> _changeRole(Map<String, dynamic> admin, String role) async {
    final userId = admin['user_id'].toString();
    try {
      await _adminService.updateAdminRole(userId, role);
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث دور المشرف.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تغيير الدور: $e')),
      );
    }
  }

  Future<void> _removeAdmin(Map<String, dynamic> admin) async {
    final userId = admin['user_id'].toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف صلاحية المشرف'),
        content: const Text('هل تريد إزالة صلاحية الإشراف عن هذا المستخدم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _adminService.removeAdmin(userId);
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إزالة صلاحية المشرف.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حذف المشرف: $e')),
      );
    }
  }

  String _roleLabel(String role) =>
      role == 'super_admin' ? 'مشرف أعلى' : 'مشرف';

  @override
  Widget build(BuildContext context) {
    if (_checkingAccess) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_authorized) {
      return Scaffold(
        appBar: AppBar(title: const Text('إدارة المشرفين')),
        body: const Center(
          child: Text('هذه الصفحة مخصصة للمشرف الأعلى فقط.'),
        ),
      );
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'إدارة المشرفين',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF003366),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAdminDialog,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('إضافة مشرف'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _adminsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'تعذر تحميل قائمة المشرفين:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final admins = snapshot.data ?? [];
          if (admins.isEmpty) {
            return const Center(child: Text('لا يوجد مشرفون حالياً.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              final future = _loadAdmins();
              setState(() => _adminsFuture = future);
              await future;
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
              itemCount: admins.length,
              itemBuilder: (context, index) {
                final admin = admins[index];
                final userId = admin['user_id'].toString();
                final role = admin['role'].toString();
                final isSelf = currentUserId == userId;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFE8EEF5),
                              child: Icon(
                                Icons.admin_panel_settings,
                                color: Color(0xFF003366),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _roleLabel(role),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF003366),
                                ),
                              ),
                            ),
                            if (isSelf)
                              const Chip(
                                label: Text('حسابك الحالي'),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          userId,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'تاريخ الإضافة: ${admin['created_at'] ?? 'غير متاح'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (!isSelf) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: role,
                                  decoration: const InputDecoration(
                                    labelText: 'تغيير الدور',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'moderator',
                                      child: Text('مشرف'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'super_admin',
                                      child: Text('مشرف أعلى'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null && value != role) {
                                      _changeRole(admin, value);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'حذف المشرف',
                                color: Colors.red,
                                onPressed: () => _removeAdmin(admin),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
