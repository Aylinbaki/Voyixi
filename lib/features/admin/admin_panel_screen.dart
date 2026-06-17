// lib/features/admin/admin_panel_screen.dart

import 'package:flutter/material.dart';
import '../guide/models/guide_application_model.dart';
import 'admin_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  static const _teal = Color(0xFF00BFA5);
  static const _bg = Color(0xFFF0FAFA);
  static const _textDark = Color(0xFF1A2E2E);
  static const _textMid = Color(0xFF4A6060);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _teal, size: 18),
          ),
        ),
        title: const Text('Admin Panel',
            style: TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset('assets/images/app_logo_plan.png',
                height: 30,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.explore_rounded, color: _teal)),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: _teal,
          unselectedLabelColor: _textMid,
          indicatorColor: _teal,
          tabs: const [
            Tab(text: 'Applications'),
            Tab(text: 'Guides'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _ApplicationsTab(),
          _GuidesTab(),
        ],
      ),
    );
  }
}

// ── Başvurular Tab ────────────────────────────────────────────────────────
class _ApplicationsTab extends StatelessWidget {
  static const _teal = Color(0xFF00BFA5);
  static const _textMid = Color(0xFF4A6060);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GuideApplication>>(
      stream: AdminService().getAllApplications(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _teal));
        }
        final apps = snap.data ?? [];
        if (apps.isEmpty) {
          return _empty('No applications found yet');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: apps.length,
          itemBuilder: (_, i) => _AppCard(app: apps[i]),
        );
      },
    );
  }

  Widget _empty(String msg) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.inbox_outlined, color: _teal, size: 48),
        const SizedBox(height: 12),
        Text(msg,
            style: const TextStyle(color: _textMid, fontSize: 15)),
      ],
    ),
  );
}

class _AppCard extends StatelessWidget {
  final GuideApplication app;
  const _AppCard({required this.app});

  static const _teal = Color(0xFF00BFA5);
  static const _textDark = Color(0xFF1A2E2E);
  static const _textMid = Color(0xFF4A6060);

  Color get _statusColor => switch (app.status) {
    'approved' => Colors.green,
    'rejected' => Colors.red,
    _ => Colors.orange,
  };

  String get _statusLabel => switch (app.status) {
    'approved' => 'Approved',
    'rejected' => 'Rejected',
    _ => 'Pending',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: _teal.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              // Avatar
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    color: _teal, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.fullName,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _textDark)),
                    Text('${app.city} • ${app.age} years old',
                        style: const TextStyle(
                            color: _textMid, fontSize: 12)),
                  ],
                ),
              ),
              // Durum etiketi
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel,
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 10),
            // Diller
            Wrap(
              spacing: 6, runSpacing: 4,
              children: app.languages.map((l) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(l,
                    style: const TextStyle(
                        color: _teal,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              )).toList(),
            ),
            const SizedBox(height: 10),

            // Hakkında
            Text(app.about,
                style: const TextStyle(
                    color: _textMid, fontSize: 13, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),

            Text(app.tourIdeas,
                style: const TextStyle(
                    color: _textMid, fontSize: 13, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),

            Text('Contact: ${app.email} • ${app.phone}',
                style: const TextStyle(
                    color: Color(0xFF8AABAB), fontSize: 11)),
            const SizedBox(height: 12),
            if (app.status == 'pending')
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => AdminService().rejectApplication(app),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade200),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        AdminService().approveApplication(app),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

// ── Rehberler Tab ─────────────────────────────────────────────────────────
class _GuidesTab extends StatelessWidget {
  static const _teal = Color(0xFF00BFA5);
  static const _textDark = Color(0xFF1A2E2E);
  static const _textMid = Color(0xFF4A6060);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminService().getAllGuides(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _teal));
        }
        final guides = snap.data ?? [];
        if (guides.isEmpty) {
          return const Center(
            child: Text('No approved guides yet',
                style: TextStyle(color: _textMid)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: guides.length,
          itemBuilder: (_, i) => _GuideCard(guide: guides[i]),
        );
      },
    );
  }
}

class _GuideCard extends StatelessWidget {
  final Map<String, dynamic> guide;
  const _GuideCard({required this.guide});

  static const _teal = Color(0xFF00BFA5);
  static const _textDark = Color(0xFF1A2E2E);
  static const _textMid = Color(0xFF4A6060);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _teal.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: guide['photoURL'] != null
              ? ClipOval(
              child: Image.network(guide['photoURL'],
                  fit: BoxFit.cover))
              : const Icon(Icons.person_rounded, color: _teal, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(guide['displayName'] ?? guide['email'] ?? 'Guide',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                      fontSize: 14)),
              Text(guide['email'] ?? '',
                  style: const TextStyle(
                      color: _textMid, fontSize: 12)),
            ],
          ),
        ),
        // Rehberliği kaldır
        GestureDetector(
          onTap: () => _confirmRemove(context, guide['id']),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Remove',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  void _confirmRemove(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Guide Status',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to remove the guide authorization for this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8AABAB))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(context);
              await AdminService().removeGuide(userId);
            },
            child: const Text('Remove',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}