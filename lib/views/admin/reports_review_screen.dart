import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/admin_service.dart';

class ReportsReviewScreen extends StatefulWidget {
  const ReportsReviewScreen({super.key});
  @override
  State<ReportsReviewScreen> createState() => _ReportsReviewScreenState();
}

class _ReportsReviewScreenState extends State<ReportsReviewScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final role = await AdminService().getAdminRole();
    if (role != 'super_admin' && role != 'moderator') {
      throw Exception('هذه الصفحة مخصصة لمشرفي التطبيق فقط.');
    }
    final raw = await _supabase.from('reports')
        .select('id,user_id,target_type,target_id,reason,status,created_at')
        .order('created_at', ascending: false);
    final reports = List<Map<String, dynamic>>.from(raw);
    final ids = reports.where((r) => r['target_type'] == 'property')
        .map((r) => r['target_id'].toString()).toSet().toList();
    if (ids.isEmpty) return reports;
    final properties = await _supabase.from('properties')
        .select('id,title,price,owner_id,status').inFilter('id', ids);
    final byId = {for (final p in properties) p['id'].toString(): p};
    return reports.map((r) => {...r, 'property': byId[r['target_id'].toString()]}).toList();
  }

  Future<void> _changeStatus(Map<String, dynamic> report, String status) async {
    try {
      final result = await _supabase.from('reports').update({'status': status})
          .eq('id', report['id'].toString()).eq('status', 'pending')
          .select('id').maybeSingle();
      if (result == null) throw Exception('البلاغ لم يعد قيد الانتظار أو لا تملك صلاحية معالجته.');
      if (!mounted) return;
      setState(() => _future = _load());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == 'resolved' ? 'تم إغلاق البلاغ.' : 'تم رفض البلاغ.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تعذرت معالجة البلاغ: $e'), backgroundColor: Colors.red,
      ));
    }
  }

  String _date(dynamic value) {
    final d = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (d == null) return 'تاريخ غير متاح';
    return '${d.day}/${d.month}/${d.year} - ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.grey[50],
    appBar: AppBar(
      title: const Text('مراجعة البلاغات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFFB71C1C),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [IconButton(onPressed: () => setState(() => _future = _load()), icon: const Icon(Icons.refresh), tooltip: 'تحديث')],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('تعذر تحميل البلاغات:\n${snap.error}', textAlign: TextAlign.center),
        ));
        final reports = snap.data ?? [];
        if (reports.isEmpty) return const Center(child: Text('لا توجد بلاغات حالياً'));
        return RefreshIndicator(
          onRefresh: () async { final f = _load(); setState(() => _future = f); await f; },
          child: ListView.builder(
            padding: const EdgeInsets.all(14), itemCount: reports.length,
            itemBuilder: (context, i) {
              final r = reports[i];
              final p = r['property'] as Map<String, dynamic>?;
              final status = r['status']?.toString() ?? 'pending';
              final pending = status == 'pending';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.flag, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p?['title']?.toString() ?? 'إعلان غير متاح أو محذوف',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366)))),
                      Chip(label: Text(status == 'pending' ? 'قيد المراجعة' : status == 'resolved' ? 'تمت المعالجة' : 'مرفوض')),
                    ]),
                    if (p != null) Text('السعر: ${p['price'] ?? 'غير متاح'} ج.م'),
                    const SizedBox(height: 10),
                    const Text('سبب البلاغ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(r['reason']?.toString() ?? ''),
                    const SizedBox(height: 8),
                    Text('تاريخ الإرسال: ${_date(r['created_at'])}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    if (pending) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: () => _changeStatus(r, 'dismissed'),
                          icon: const Icon(Icons.close), label: const Text('رفض البلاغ'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: ElevatedButton.icon(
                          onPressed: () => _changeStatus(r, 'resolved'),
                          icon: const Icon(Icons.check), label: const Text('إغلاق البلاغ'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        )),
                      ]),
                    ],
                  ]),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
