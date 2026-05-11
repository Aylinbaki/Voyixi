import 'package:flutter/material.dart';
import '../services/audio_guide_service.dart';

class AudioGuideButton extends StatefulWidget {
  final String placeName;
  final String city;
  final String description;
  final Color color;
  final bool compact; // true = küçük buton (kart içi), false = geniş

  const AudioGuideButton({
    super.key,
    required this.placeName,
    required this.city,
    required this.description,
    this.color = const Color(0xFF9C6FDE),
    this.compact = false,
  });

  @override
  State<AudioGuideButton> createState() => _AudioGuideButtonState();
}

class _AudioGuideButtonState extends State<AudioGuideButton>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  bool _playing = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseCtrl.stop();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_loading) return;

    if (_playing) {
      await AudioGuideService().stop();
      setState(() => _playing = false);
      _pulseCtrl.stop();
      return;
    }

    setState(() => _loading = true);

    await AudioGuideService().playGuide(
      placeName: widget.placeName,
      city: widget.city,
      description: widget.description,
      onStart: () {
        if (mounted) {
          setState(() {
            _loading = false;
            _playing = true;
          });
          _pulseCtrl.repeat(reverse: true);
        }
      },
      onFinish: () {
        if (mounted) {
          setState(() => _playing = false);
          _pulseCtrl.stop();
        }
      },
      onError: () {
        if (mounted) {
          setState(() {
            _loading = false;
            _playing = false;
          });
          _pulseCtrl.stop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesli rehber yüklenemedi'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) return _buildCompact();
    return _buildFull();
  }

  // Geniş buton — aktif kart içi
  Widget _buildFull() {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Transform.scale(
          scale: _playing ? _pulse.value : 1.0,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _playing
                ? widget.color.withOpacity(0.85)
                : widget.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _playing
                ? [BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 3))]
                : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _icon(),
            const SizedBox(width: 6),
            Text(
              _playing ? 'Durdur' : 'Sesli Rehber',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ]),
        ),
      ),
    );
  }

  // Küçük buton — üst kart sağ köşesi
  Widget _buildCompact() {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Transform.scale(
          scale: _playing ? _pulse.value : 1.0,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _icon(),
            const SizedBox(height: 2),
            Text(
              _playing ? 'Dur' : 'Sesli\nRehber',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _icon() {
    if (_loading) {
      return const SizedBox(
        width: 16, height: 16,
        child: CircularProgressIndicator(
            color: Colors.white, strokeWidth: 2),
      );
    }
    return Icon(
      _playing ? Icons.stop_rounded : Icons.volume_up_rounded,
      color: Colors.white,
      size: 16,
    );
  }
}