import 'package:flutter/material.dart';
import '../trip_result/trip_result_model.dart';
import 'routes_service.dart';

class RoutesWidget extends StatefulWidget {
  final TripResult result;
  const RoutesWidget({super.key, required this.result});

  @override
  State<RoutesWidget> createState() => _RoutesWidget();
}

class _RoutesWidget extends State<RoutesWidget> {
  final _titleCtrl = TextEditingController();
  DateTime? _selectedDate;
  bool _saving = false;
  static const _teal = Color(0xFF00BFA5);
  static const _textDark = Color(0xFF1A2E2E);
  static const _textMid = Color(0xFF4A6060);
  static const _divider = Color(0xFFE0F0EF);

  @override
  void initState() {
    super.initState();
    // Varsayılan başlık
    _titleCtrl.text = '${widget.result.city} Seyahati';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _teal),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
  if (_titleCtrl.text.trim().isEmpty) return;
  setState(() => _saving = true);

  try {
    final id = await RoutesService().saveTrip(
      result: widget.result,
      title: _titleCtrl.text.trim(),
      tripDate: _selectedDate,
    );

    if (mounted) {
      Navigator.pop(context, id); // String id döndür
    }
  } catch (e) {
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return SafeArea( 
    child: Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Başlık
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _teal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bookmark_rounded, color: _teal, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Planı Kaydet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textDark),
            ),
          ]),
          const SizedBox(height: 20),

          // Plan adı
          const Text('Plan Adı',
              style: TextStyle(
                  color: _textMid,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              hintText: '${widget.result.city} Seyahati',
              hintStyle: const TextStyle(color: Color(0xFF8AABAB)),
              filled: true,
              fillColor: const Color(0xFFF0FAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _teal, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tarih (opsiyonel)
          const Text('Gezi Tarihi (İsteğe Bağlı)',
              style: TextStyle(
                  color: _textMid,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAFA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _divider),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    color: _teal, size: 18),
                const SizedBox(width: 10),
                Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Tarih seç...',
                  style: TextStyle(
                    color: _selectedDate != null
                        ? _textDark
                        : const Color(0xFF8AABAB),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (_selectedDate != null)
                  GestureDetector(
                    onTap: () => setState(() => _selectedDate = null),
                    child: const Icon(Icons.close_rounded,
                        color: Color(0xFF8AABAB), size: 18),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 8),

          // Bilgi notu
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: _teal, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Planın özeti yapay zeka tarafından otomatik oluşturulacak ve şehir görseli eklenecek.',
                  style: TextStyle(
                      color: Color(0xFF00897B),
                      fontSize: 12,
                      height: 1.4),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Kaydet butonu
          SafeArea(
            child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                disabledBackgroundColor: _divider,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Text(
                      'Kaydet',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          ),
        ],
      ),
    ),
    );
    
  }
}