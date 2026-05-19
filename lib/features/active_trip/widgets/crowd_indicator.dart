import 'package:flutter/material.dart';
import '../services/crowd_service.dart';

class CrowdIndicator extends StatefulWidget {
  final String placeName;
  final String city;
  final String? placeId;
  final String fallbackLevel;
  final bool showLabel;
  final bool compact;

  const CrowdIndicator({
    super.key,
    required this.placeName,
    required this.city,
    required this.fallbackLevel,
    this.placeId,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  State<CrowdIndicator> createState() => _CrowdIndicatorState();
}

class _CrowdIndicatorState extends State<CrowdIndicator> {
  CrowdLevel _level = CrowdLevel.moderate;
  String? _specialStatus; // Açılış saatini veya özel durumu tutacak
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    _loadCrowdData(); // Ekran açılırken tek seferlik veriyi yükle
  }

  Future<void> _loadCrowdData() async {
    // Record döndüren yeni Future tabanlı servisimizi çağırıyoruz
    final result = await CrowdService().getCrowdLevel(
      placeName: widget.placeName,
      city: widget.city,
      placeId: widget.placeId,
      fallbackLevel: widget.fallbackLevel,
    );

    if (mounted) {
      setState(() {
        _level = result.$1;          // Seviye (enum)
        _specialStatus = result.$2;  // Özel Durum Metni (Açılış: XX:XX)
        _hasData = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // İnternetten veri gelene kadar Gemini'den gelen ilk tahmini göstererek arayüzü doldurur
    final displayLevel = _hasData ? _level : _parseFallback(widget.fallbackLevel);
    
    // Eğer özel bir durum metni (Açılış saati) geldiyse onu yaz, yoksa standart etiketi kullan
    final String labelText = _specialStatus ?? displayLevel.label;

    if (widget.compact) return _buildCompact(displayLevel, labelText);
    return _buildFull(displayLevel, labelText);
  }

  Widget _buildFull(CrowdLevel level, String labelText) => AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: level.bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(level.icon, size: 12, color: level.color),
          const SizedBox(width: 4),
          if (widget.showLabel)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                labelText,
                key: ValueKey(labelText),
                style: TextStyle(
                    fontSize: 11,
                    color: level.color,
                    fontWeight: FontWeight.w600),
              ),
            ),
          if (_hasData && level != CrowdLevel.closed) ...[
            const SizedBox(width: 4),
            Container(
              width: 5, height: 5,
              decoration: BoxDecoration(
                  color: level.color, shape: BoxShape.circle),
            ),
          ],
        ]),
      );

  Widget _buildCompact(CrowdLevel level, String labelText) => AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: level.bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          // Kapalıysa kilit ikonu, açıksa insan ikonu gösteriyoruz
          Icon(
            level == CrowdLevel.closed ? Icons.lock_outline_rounded : Icons.people_rounded, 
            size: 10, 
            color: level.color
          ),
          const SizedBox(width: 3),
          Text(
            labelText,
            style: TextStyle(
                fontSize: 10,
                color: level.color,
                fontWeight: FontWeight.w600),
          ),
        ]),
      );

  CrowdLevel _parseFallback(String level) => switch (level) {
        'Sakin' => CrowdLevel.quiet,
        'Yoğun' => CrowdLevel.busy,
        'Çok Yoğun' => CrowdLevel.veryBusy,
        _ => CrowdLevel.moderate,
      };
}