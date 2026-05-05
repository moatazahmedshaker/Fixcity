import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'main.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    // Mark all as read
    await _supabase.from('notifications').update({'is_read': true}).eq('user_id', user.id);
    final res = await _supabase.from('notifications').select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);
    return res.cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';
    final user = _supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kDark,
        title: Text(isAr ? 'الإشعارات' : 'Notifications',
            style: const TextStyle(color: kWhite, fontWeight: FontWeight.w700)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: user == null
          ? _GuestView(isAr: isAr)
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchNotifications(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kRed));
                }
                final notifs = snap.data ?? [];
                if (notifs.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.notifications_none_outlined, size: 64, color: kGrey),
                    const SizedBox(height: 12),
                    Text(isAr ? 'لا توجد إشعارات' : 'No notifications yet',
                        style: const TextStyle(color: kGrey, fontSize: 14)),
                  ]));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifs.length,
                  itemBuilder: (context, i) {
                    final n    = notifs[i];
                    final date = DateTime.tryParse(n['created_at'] ?? '') ?? DateTime.now();
                    final read = n['is_read'] == true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: read ? Colors.grey.shade100 : kRed.withOpacity(0.3)),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: kBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_outlined, color: kBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kDark)),
                          const SizedBox(height: 4),
                          Text(n['body'] ?? '', style: const TextStyle(fontSize: 12, color: kGrey)),
                          const SizedBox(height: 4),
                          Text('${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                        ])),
                        if (!read)
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle)),
                      ]),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _GuestView extends StatelessWidget {
  final bool isAr;
  const _GuestView({required this.isAr});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(color: kBlue.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.notifications_outlined, size: 44, color: kBlue),
          ),
          const SizedBox(height: 20),
          Text(isAr ? 'سجّل دخول لعرض الإشعارات 🔔' : 'Login to see your alerts 🔔',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kDark)),
          const SizedBox(height: 8),
          Text(isAr ? 'ستصلك إشعارات عند تحديث حالة بلاغاتك'
                    : "You'll get notified when your report status changes",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: kGrey, height: 1.6)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/login'),
              child: Text(isAr ? 'تسجيل الدخول' : 'Log In',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pushNamed('/signup'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kBlue, side: const BorderSide(color: kBlue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isAr ? 'إنشاء حساب' : 'Create Account',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}
