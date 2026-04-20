import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'edit_profile_screen.dart';

const _teal = Color(0xFF00BFA5);
const _tealDark = Color(0xFF00897B);
const _bg = Color(0xFFF0FAFA);
const _textDark = Color(0xFF1A2E2E);
const _textMid = Color(0xFF4A6060);
const _textLight = Color(0xFF8AABAB);
const _divider = Color(0xFFE0F0EF);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {

  bool _audioGuide = true;
  bool _darkMode = false;
  bool _locationPerm = true;
  bool _cameraPerm = false;
  bool _notifPerm = true;

  String _openSection = ''; 
  int _rating = 0;
  String _language = 'Türkçe';
  final _reportCtrl = TextEditingController();
  User? get _user => FirebaseAuth.instance.currentUser;
  String get _name => _user?.displayName ?? _user?.email?.split('@').first ?? 'Kullanıcı';
  String get _email => _user?.email ?? '';
  String? get _photo => _user?.photoURL;

  @override
  void dispose() {
    _reportCtrl.dispose();
    super.dispose();
  }

  void _toggle(String section) =>
      setState(() => _openSection = _openSection == section ? '' : section);

  Future<void> _openMail({String subject = '', String body = ''}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'voyixiapp@gmail.com',
      queryParameters: {'subject': subject, if (body.isNotEmpty) 'body': body},
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 225, 239, 239),
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _teal, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Ayarlar',
            style: TextStyle(color: _textDark, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _profileCard(),
          const SizedBox(height: 22),
          _sectionTitle('Hesap'),
          _card([
            _tile(Icons.person_outline_rounded, 'Hesabım', onTap: () {}),
            _tile(Icons.description_outlined, 'Gizlilik ve Koşullar', onTap: () {}, isLast: true),
          ]),
          const SizedBox(height: 16),
          _sectionTitle('Tercihler'),
          _card([
            _tile(Icons.language_rounded, 'Dil',
                trailing: Text(_language, style: const TextStyle(color: _textLight)),
                onTap: _showLanguagePicker),
            _tile(Icons.dark_mode_outlined, 'Karanlık Mod',
                trailing: _switch(_darkMode, (v) => setState(() => _darkMode = v))),
            _tile(Icons.headphones_rounded, 'Sesli Rehber',
                trailing: _switch(_audioGuide, (v) => setState(() => _audioGuide = v)),
                isLast: true),
          ]),
          const SizedBox(height: 16),

          _sectionTitle('İzinler'),
          _card([
            _accordionHeader(Icons.shield_outlined, 'İzinler', 'permissions'),
            if (_openSection == 'permissions') ...[
              const Divider(height: 1, indent: 20, endIndent: 20, color: _divider),
              _permRow(Icons.location_on_outlined, 'Konum', _locationPerm,
                  (v) => setState(() => _locationPerm = v)),
              _permRow(Icons.camera_alt_outlined, 'Kamera', _cameraPerm,
                  (v) => setState(() => _cameraPerm = v)),
              _permRow(Icons.notifications_outlined, 'Bildirimler', _notifPerm,
                  (v) => setState(() => _notifPerm = v), isLast: true),
            ],
          ]),
          const SizedBox(height: 16),
          _sectionTitle('Uygulama'),
          _card([
            _tile(Icons.tour_outlined, 'Rehber Uygulaması', onTap: () {}),
            _tile(Icons.info_outline_rounded, 'Versiyon',
                trailing: const Text('v1.0.0', style: TextStyle(color: _textLight)),
                isLast: true),
          ]),
          const SizedBox(height: 16),
          _sectionTitle('Destek'),
          _card([
            _accordionHeader(Icons.star_outline_rounded, 'Bizi Değerlendirin', 'rating'),
            if (_openSection == 'rating') _ratingContent(),
            const Divider(height: 1, indent: 66, color: _divider),
            _accordionHeader(Icons.mail_outline_rounded, 'Bize Ulaşın', 'contact'),
            if (_openSection == 'contact') _contactContent(),
            const Divider(height: 1, indent: 66, color: _divider),
            _accordionHeader(Icons.flag_outlined, 'Sorun Bildir', 'report'),
            if (_openSection == 'report') _reportContent(),
          ]),
          const SizedBox(height: 28),
          _logoutButton(),
          const SizedBox(height: 12),
          const Center(
            child: Text('VOYIXI • Daha iyi tur deneyimi için buradayız',
                style: TextStyle(color: _textLight, fontSize: 11)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  Widget _profileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_teal, _tealDark]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _teal.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            backgroundImage: _photo != null ? NetworkImage(_photo!) : null,
            child: _photo == null ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(_email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(t.toUpperCase(),
            style: const TextStyle(color: _tealDark, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: _teal.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(children: children),
      );

  Widget _tileIcon(IconData icon) => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: _teal.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: _teal, size: 20),
      );

  Widget _tile(IconData icon, String label,
      {Widget? trailing, VoidCallback? onTap, bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          leading: _tileIcon(icon),
          title: Text(label, style: const TextStyle(color: _textDark, fontSize: 14.5, fontWeight: FontWeight.w500)),
          trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, color: _textLight) : null),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        ),
        if (!isLast) const Divider(height: 1, indent: 66, color: _divider),
      ],
    );
  }
  Widget _accordionHeader(IconData icon, String label, String section) {
    final isOpen = _openSection == section;
    return ListTile(
      leading: _tileIcon(icon),
      title: Text(label, style: const TextStyle(color: _textDark, fontSize: 14.5, fontWeight: FontWeight.w500)),
      trailing: AnimatedRotation(
        turns: isOpen ? 0.5 : 0,
        duration: const Duration(milliseconds: 250),
        child: const Icon(Icons.keyboard_arrow_down_rounded, color: _textLight),
      ),
      onTap: () => _toggle(section),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _permRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged,
      {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(66, 4, 16, 4),
          child: Row(
            children: [
              Icon(icon, color: _teal, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: const TextStyle(color: _textMid, fontSize: 14))),
              _switch(value, onChanged),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 82, color: _divider),
      ],
    );
  }

  Widget _switch(bool val, ValueChanged<bool> fn) =>
      Transform.scale(scale: 0.82, child: CupertinoSwitch(value: val, onChanged: fn, activeColor: _teal));

  // ── Açılır bölümler 
  Widget _ratingContent() {
    const labels = ['Berbat', 'Kötü', 'Orta', 'İyi', 'Harika'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _rating = i + 1),
              child: Icon(
                i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: i < _rating ? Colors.amber : _textLight,
                size: 38,
              ),
            )),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 6),
            Text(labels[_rating - 1], style: const TextStyle(color: _teal, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 12),
          _actionButton('Değerlendirmeyi Gönder', _rating == 0 ? null : () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('$_rating yıldız için teşekkürler 🎉'),
              backgroundColor: _teal,
              behavior: SnackBarBehavior.floating,
            ));
            setState(() { _rating = 0; _openSection = ''; });
          }),
        ],
      ),
    );
  }

  Widget _contactContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _teal.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.mail_rounded, color: _teal),
                SizedBox(width: 10),
                Text('voyixiapp@gmail.com',
                    style: TextStyle(color: _tealDark, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _actionButton('Mail Uygulamasını Aç',
              () => _openMail(subject: 'Uygulama Hakkında')),
        ],
      ),
    );
  }

  Widget _reportContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        children: [
          TextField(
            controller: _reportCtrl,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Sorununuzu buraya yazın...',
              hintStyle: const TextStyle(color: _textLight, fontSize: 13),
              filled: true,
              fillColor: _teal.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _teal.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _teal, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _teal.withOpacity(0.2)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _actionButton('Gönder', () async {
            final text = _reportCtrl.text.trim();
            if (text.isEmpty) return;
            await _openMail(subject: 'Sorun Bildirimi', body: text);
            _reportCtrl.clear();
            setState(() => _openSection = '');
          }),
        ],
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback? onTap) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: _teal,
            disabledBackgroundColor: _divider,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _logoutButton() {
    return OutlinedButton.icon(
      onPressed: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Hesabınızdan çıkmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: _textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, elevation: 0),
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              },
              child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      icon: Icon(Icons.logout_rounded, color: Colors.red.shade400),
      label: Text('Çıkış Yap', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.red.shade200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(double.infinity, 0),
      ),
    );
  }
  void _showLanguagePicker() {
    final langs = ['Türkçe', 'English', 'Deutsch', 'Français', 'Español'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Dil Seçin',
                  style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 17)),
            ),
            ...langs.map((lang) => ListTile(
                  title: Text(lang, style: const TextStyle(color: _textDark)),
                  trailing: _language == lang ? const Icon(Icons.check_circle_rounded, color: _teal) : null,
                  onTap: () { setState(() => _language = lang); Navigator.pop(context); },
                )),
          ],
        ),
      ),
    );
  }
}