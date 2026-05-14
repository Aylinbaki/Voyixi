import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_tour_screen.dart';
import '../models/guide_tour_model.dart';
import 'guide_tour_service.dart';

void showGuidePanel(BuildContext context) {
  bool showList = false;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- ÜST KISIM (BAŞLIK VE GERİ) ---
                  Row(
                    children: [
                      if (showList)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                          onPressed: () => setState(() => showList = false),
                        ),
                      Expanded(
                        child: Text(
                          showList ? 'Turlarımı Yönet' : 'Rehber Paneli',
                          textAlign: showList ? TextAlign.left : TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2E)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (!showList) ...[
                    // --- ANA SEÇİM EKRANI ---
                    Row(
                      children: [
                        _buildPopupButton(
                          context,
                          title: 'Yeni Tur\nOluştur',
                          icon: Icons.add_location_alt_rounded,
                          color: const Color(0xFF00BFA5),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTourScreen()));
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildPopupButton(
                          context,
                          title: 'Turları\nDüzenle',
                          icon: Icons.edit_calendar_rounded,
                          color: const Color(0xFF4A6060),
                          onTap: () => setState(() => showList = true),
                        ),
                      ],
                    ),
                  ] else ...[
                    // --- TURLARI LİSTELEME EKRANI ---
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: StreamBuilder<List<GuideTour>>(
                        // BURAYI GÜNCELLEDİK: Senin servisindeki gerçek metod
                        stream: GuideTourService().getMyTours(), 
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF00BFA5)));
                          }
                          
                          final tours = snapshot.data ?? [];
                          
                          if (tours.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text("Henüz bir tur oluşturmadınız.", style: TextStyle(color: Colors.grey)),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount: tours.length,
                            separatorBuilder: (_, __) => const Divider(height: 20, color: Color(0xFFE0F0EF)),
                            itemBuilder: (context, index) {
                              final tour = tours[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(tour.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                subtitle: Text(tour.city, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // DÜZENLE BUTONU (Kalem İkonu)
                                    IconButton(
                                      icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF00BFA5)),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.push(context, MaterialPageRoute(
                                          builder: (_) => CreateTourScreen(existing: tour),
                                        ));
                                      },
                                    ),
                                    // SİLME BUTONU (Çöp Kutusu İkonu)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                      onPressed: () => _confirmDelete(context, tour.id),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// Yardımcı buton widget'ı (Diğer kodla aynı)
Widget _buildPopupButton(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    ),
  );
}

// Silme onay diyaloğu
void _confirmDelete(BuildContext context, String tourId) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Turu Sil?", style: TextStyle(fontWeight: FontWeight.bold)),
      content: const Text("Bu turu silmek istediğinize emin misiniz? Bu işlem geri alınamaz."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Vazgeç", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0),
          onPressed: () async {
            await GuideTourService().deleteTour(tourId);
            Navigator.pop(ctx);
          }, 
          child: const Text("Sil", style: TextStyle(color: Colors.white))
        ),
      ],
    ),
  );
}