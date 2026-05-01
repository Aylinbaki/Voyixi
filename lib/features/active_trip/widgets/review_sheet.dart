import 'package:flutter/material.dart';

class ReviewSheet extends StatefulWidget {
  final String placeName;
  final int? initialRating;
  final String? initialReview;
  final void Function(int rating, String review) onSave;

  const ReviewSheet({
    super.key,
    required this.placeName,
    required this.onSave,
    this.initialRating,
    this.initialReview,
  });

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  int _rating = 0;
  late final TextEditingController _ctrl;
  static const _teal = Color(0xFF00BFA5);
  static const _textDark = Color(0xFF1A2E2E);
  static const _textMid = Color(0xFF4A6060);

  final _labels = ['', 'Berbat', 'Kötü', 'İyi', 'Çok İyi', 'Harika!'];

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 0;
    _ctrl = TextEditingController(text: widget.initialReview ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              child: const Icon(Icons.star_rounded, color: _teal, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Değerlendirme',
                      style: TextStyle(fontSize: 17,
                          fontWeight: FontWeight.w800, color: _textDark)),
                  Text(widget.placeName,
                      style: const TextStyle(color: _textMid, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // Yıldızlar
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < _rating ? Colors.amber : Colors.grey[300],
                    size: 44,
                  ),
                ),
              )),
            ),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                _labels[_rating],
                style: const TextStyle(color: _teal,fontWeight: FontWeight.w700,fontSize: 15),
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Yorum kutusu
          TextField(
            controller: _ctrl,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Deneyiminizi paylaşın... (isteğe bağlı)',
              hintStyle:
                  TextStyle(color: Colors.grey[400], fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF0FAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: _teal, width: 1.5),
              ),
              counterStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _rating == 0
                  ? null : () {
                      widget.onSave(_rating, _ctrl.text.trim());
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                disabledBackgroundColor: Colors.grey[200],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Değerlendirmeyi Kaydet',
                  style: TextStyle(color: Colors.white,fontWeight: FontWeight.w700,fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}