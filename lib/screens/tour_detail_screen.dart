import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TourDetailScreen extends StatelessWidget {
  final Map<String, dynamic> tour;
  const TourDetailScreen({super.key, required this.tour});

  @override
  Widget build(BuildContext context) {
    final places       = List<String>.from(tour['places'] ?? []);
    final city         = tour['city']         ?? '';
    final description  = tour['description']  ?? '';
    final guideName    = (tour['guideName'] ?? 'Rehber').toString().trim();
    final guideContact = tour['guideContact'] ?? '';
    final guideId      = tour['guideId']      ?? '';
    final maxP         = tour['maxParticipants'];
    final imageUrl     = tour['imageUrl']     ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // ── 1. Resim — tam ekran arka plan ──────────────────────────
          Positioned.fill(
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0DA3A3), Color(0xFFB8F0F0)],
                    ),
                  ),
                ))
                : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0DA3A3), Color(0xFFB8F0F0)],
                ),
              ),
            ),
          ),

          // ── 2. Hafif karartma ────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),

          // ── 3. Geri butonu ───────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18,
                  ),
                ),
              ),
            ),
          ),

          // ── 4. DraggableScrollableSheet — glass card ─────────────────
          // minChildSize = initialChildSize: başta sadece rehber satırı görünür (0.22)
          // maxChildSize: tam açık — tüm bilgiler
          DraggableScrollableSheet(
            initialChildSize: 0.22,
            minChildSize: 0.22,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.22, 0.88],
            builder: (context, scrollController) {
              return ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)), //köşeler
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), //arka resim blur
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.17), //yarı saydam beyaz—glass
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28)),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.28), width: 1),
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
                      children: [

                        // Handle çubuğu
                        Center(
                          child: Container(
                            width: 40, height: 4,
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        // Konum + Tur adı — glass card içinde
                        Row(children: [
                          const Icon(Icons.location_on,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(city,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ]),
                        const SizedBox(height: 4),
                        Text(
                          tour['title'] ?? city,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Rehber satırı — her zaman görünür
                        GestureDetector(
                          onTap: () =>
                              _showGuideSheet(context, guideId, guideName),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(children: [
                              CircleAvatar(
                                backgroundColor:
                                Colors.white.withOpacity(0.25),
                                radius: 20,
                                child: const Icon(Icons.person,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Rehber',
                                      style: TextStyle(
                                          color:
                                          Colors.white.withOpacity(0.7),
                                          fontSize: 11)),
                                  Text(guideName,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                ],
                              ),
                              const Spacer(),
                              Icon(Icons.chevron_right_rounded,
                                  color: Colors.white.withOpacity(0.7)),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Açıklama
                        if (description.isNotEmpty) ...[
                          _sectionTitle('Tur Hakkında'),
                          const SizedBox(height: 8),
                          Text(description,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.6)),
                          const SizedBox(height: 24),
                        ],

                        // Max katılımcı
                        if (maxP != null) ...[
                          Row(children: [
                            const Icon(Icons.group_outlined,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 8),
                            Text('Maksimum $maxP katılımcı',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ]),
                          const SizedBox(height: 24),
                        ],

                        // Gezilecek yerler
                        if (places.isNotEmpty) ...[
                          _sectionTitle('Gezilecek Yerler'),
                          const SizedBox(height: 10),
                          ...places.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(children: [
                              Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(p,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14)),
                              ),
                            ]),
                          )),
                          const SizedBox(height: 24),
                        ],

                        // İletişim
                        if (guideContact.isNotEmpty) ...[
                          _sectionTitle('İletişim'),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () =>
                                launchUrl(Uri.parse('mailto:$guideContact')),
                            child: Row(children: [
                              const Icon(Icons.mail_outline_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text(guideContact,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                  )),
                            ]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  );

  void _showGuideSheet(
      BuildContext context, String guideId, String guideName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _GuideSheet(guideId: guideId, guideName: guideName),
    );
  }
}

// ── Rehber Sheet ──────────────────────────────────────────────────────────────
class _GuideSheet extends StatelessWidget {
  final String guideId;
  final String guideName;
  const _GuideSheet({required this.guideId, required this.guideName});

  static const _teal     = Color(0xFF00BFA5);
  static const _textDark = Color(0xFF1A2E2E);
  static const _textMid  = Color(0xFF4A6060);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
      const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withOpacity(0.97),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('guide_applications')
                .doc(guideId)
                .get(),
            builder: (context, snap) {
              final handle = Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );

              if (snap.connectionState == ConnectionState.waiting) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    handle,
                    const SizedBox(height: 40),
                    const CircularProgressIndicator(color: _teal),
                    const SizedBox(height: 40),
                  ],
                );
              }

              final data = snap.data?.data() as Map<String, dynamic>?;
              final fullName  = data?['fullName']  ?? guideName;
              final about     = data?['about']     ?? '';
              final city      = data?['city']      ?? '';
              final email     = data?['email']     ?? '';
              final phone     = data?['phone']     ?? '';
              final languages =
              List<String>.from(data?['languages'] ?? []);

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    handle,
                    Row(children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: _teal.withOpacity(0.15),
                        child: const Icon(Icons.person,
                            color: _teal, size: 36),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fullName,
                              style: const TextStyle(
                                  color: _textDark,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          if (city.isNotEmpty)
                            Row(children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 13, color: _teal),
                              const SizedBox(width: 3),
                              Text(city,
                                  style: const TextStyle(
                                      color: _textMid, fontSize: 13)),
                            ]),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 20),

                    if (about.isNotEmpty) ...[
                      _label('Hakkında'),
                      const SizedBox(height: 6),
                      Text(about,
                          style: const TextStyle(
                              color: _textMid,
                              fontSize: 14,
                              height: 1.5)),
                      const SizedBox(height: 16),
                    ],

                    if (languages.isNotEmpty) ...[
                      _label('Konuştuğu Diller'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 6,
                        children: languages
                            .map((l) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _teal.withOpacity(0.1),
                            borderRadius:
                            BorderRadius.circular(20),
                            border: Border.all(
                                color: _teal.withOpacity(0.3)),
                          ),
                          child: Text(l,
                              style: const TextStyle(
                                  color: _teal,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (email.isNotEmpty || phone.isNotEmpty) ...[
                      _label('İletişim'),
                      const SizedBox(height: 8),
                      if (email.isNotEmpty)
                        GestureDetector(
                          onTap: () =>
                              launchUrl(Uri.parse('mailto:$email')),
                          child: _contactRow(
                              Icons.mail_outline_rounded, email),
                        ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () =>
                              launchUrl(Uri.parse('tel:$phone')),
                          child: _contactRow(
                              Icons.phone_outlined, phone),
                        ),
                      ],
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          color: _textDark,
          fontWeight: FontWeight.bold,
          fontSize: 15));

  Widget _contactRow(IconData icon, String text) => Row(children: [
    Icon(icon, size: 16, color: _teal),
    const SizedBox(width: 8),
    Text(text,
        style: const TextStyle(
            color: _teal,
            fontSize: 13,
            decoration: TextDecoration.underline)),
  ]);
}