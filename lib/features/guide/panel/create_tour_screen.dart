// lib/features/guide/panel/create_tour_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/guide_tour_model.dart';
import 'guide_tour_service.dart';

class CreateTourScreen extends StatefulWidget {
  final GuideTour? existing; // null = yeni tur, dolu = düzenleme

  const CreateTourScreen({super.key, this.existing});

  @override
  State<CreateTourScreen> createState() => _CreateTourScreenState();
}

class _CreateTourScreenState extends State<CreateTourScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  DateTime? _tourDate;
  TimeOfDay? _tourTime;
  final List<String> _places = [];
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  static const _teal = Color(0xFF00BFA5);
  static const _tealDark = Color(0xFF00897B);
  static const _bg = Color(0xFFF0FAFA);
  static const _textDark = Color(0xFF1A2E2E);
  static const _textMid = Color(0xFF4A6060);
  static const _divider = Color(0xFFE0F0EF);

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description;
      _cityCtrl.text = e.city;
      _contactCtrl.text = e.guideContact;
      _priceCtrl.text = e.price?.toString() ?? '';
      _maxCtrl.text = e.maxParticipants?.toString() ?? '';
      _tourDate = e.tourDate;
      _places.addAll(e.places);
      final parts = e.tourTime.split(':');
      if (parts.length == 2) {
        _tourTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 9,
            minute: int.tryParse(parts[1]) ?? 0);
      }
    }
    // Varsayılan iletişim bilgisi
    final user = FirebaseAuth.instance.currentUser;
    if (_contactCtrl.text.isEmpty && user != null) {
      _contactCtrl.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [_titleCtrl, _descCtrl, _cityCtrl, _contactCtrl,
      _placeCtrl, _priceCtrl, _maxCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _tourDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _teal)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _tourDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _tourTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _teal)),
        child: child!,
      ),
    );
    if (t != null) setState(() => _tourTime = t);
  }

  void _addPlace() {
    final p = _placeCtrl.text.trim();
    if (p.isEmpty) return;
    setState(() {
      _places.add(p);
      _placeCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tourDate == null) {
      _snack('Please select the tour date', error: true); return;
    }
    if (_tourTime == null) {
      _snack('Please select the tour time', error: true); return;
    }
    if (_places.isEmpty) {
      _snack('Please add at least one place to visit', error: true); return;
    }

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final guideName = userData.data()?['displayName'] ??
          user.displayName ??
          user.email?.split('@').first ??
          'Guide';

      final id = _isEditing
          ? widget.existing!.id
          : FirebaseFirestore.instance.collection('guide_tours').doc().id;

      final timeStr =
          '${_tourTime!.hour.toString().padLeft(2, '0')}:${_tourTime!.minute.toString().padLeft(2, '0')}';

      final tour = GuideTour(
        id: id,
        guideId: user.uid,
        guideName: guideName,
        guideContact: _contactCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        tourDate: _tourDate!,
        tourTime: timeStr,
        places: _places,
        price: double.tryParse(_priceCtrl.text.trim()),
        maxParticipants: int.tryParse(_maxCtrl.text.trim()),
        likedBy: _isEditing ? widget.existing!.likedBy : [],
        createdAt: _isEditing ? widget.existing!.createdAt : DateTime.now(),
      );

      if (_isEditing) {
        await GuideTourService().updateTour(tour);
      } else {
        await GuideTourService().createTour(tour);
      }

      if (mounted) {
        _snack(_isEditing ? 'Tour updated successfully ✅' : 'Tour published successfully 🎉');
        Navigator.pop(context);
      }
    } catch (e) {
      _snack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : _teal,
      behavior: SnackBarBehavior.floating,
    ));
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
                color: _teal.withOpacity(0.12), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _teal, size: 18),
          ),
        ),
        title: Text(
          _isEditing ? 'Edit Tour' : 'Create Tour',
          style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w700,
              fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 80,
              child: Image.asset(
                'assets/images/app_logo_plan.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.explore_rounded, color: _teal),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _sectionTitle('Tour Details'),
            _field(_titleCtrl, 'Tour Title',
                Icons.title_rounded, required: true),
            _field(_cityCtrl, 'City',
                Icons.location_on_outlined, required: true),
            _multiField(_descCtrl, 'Tour Description',
                required: true, minLines: 3),

            const SizedBox(height: 16),
            _sectionTitle('Date and Time'),
            Row(children: [
              Expanded(child: _dateTile()),
              const SizedBox(width: 12),
              Expanded(child: _timeTile()),
            ]),

            const SizedBox(height: 16),
            _sectionTitle('Places to Visit'),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _placeCtrl,
                  decoration: _inputDecor(
                      'Add place...', Icons.add_location_alt_rounded),
                  onFieldSubmitted: (_) => _addPlace(),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _addPlace,
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                      color: _teal,
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ]),
            if (_places.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _places.asMap().entries.map((e) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _teal.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(e.value,
                        style: const TextStyle(
                            color: _teal,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _places.removeAt(e.key)),
                      child: const Icon(Icons.close_rounded,
                          color: _teal, size: 14),
                    ),
                  ]),
                )).toList(),
              ),
            ],

            const SizedBox(height: 16),
            _sectionTitle('Contact Information'),
            _field(_contactCtrl, 'Email or Phone Number',
                Icons.contact_mail_outlined, required: true),

            const SizedBox(height: 16),
            _sectionTitle('Optional Details'),
            Row(children: [
              Expanded(
                child: _field(_priceCtrl, 'Price (\$)',
                    Icons.payments_outlined,
                    keyboardType: TextInputType.number),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(_maxCtrl, 'Max Participants',
                    Icons.group_outlined,
                    keyboardType: TextInputType.number),
              ),
            ]),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.rocket_launch_rounded,
                    color: Colors.white, size: 18),
                label: Text(
                    _saving
                        ? 'Saving...'
                        : _isEditing
                        ? 'Update'
                        : 'Publish Tour',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  disabledBackgroundColor: _divider,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t.toUpperCase(),
        style: const TextStyle(
            color: _tealDark,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2)),
  );

  InputDecoration _inputDecor(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textMid, fontSize: 14),
        prefixIcon: Icon(icon, color: _teal, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _teal, width: 1.5)),
      );

  Widget _field(
      TextEditingController ctrl,
      String label,
      IconData icon, {
        bool required = false,
        TextInputType keyboardType = TextInputType.text,
      }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          validator: required
              ? (v) =>
          (v == null || v.trim().isEmpty) ? '$label is required' : null
              : null,
          decoration: _inputDecor(label, icon),
        ),
      );

  Widget _multiField(TextEditingController ctrl, String label,
      {bool required = false, int minLines = 3}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          maxLines: null,
          minLines: minLines,
          validator: required
              ? (v) =>
          (v == null || v.trim().isEmpty) ? '$label is required' : null
              : null,
          decoration: InputDecoration(
            labelText: label,
            alignLabelWithHint: true,
            labelStyle: const TextStyle(color: _textMid, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _divider)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _divider)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _teal, width: 1.5)),
          ),
        ),
      );

  Widget _dateTile() => GestureDetector(
    onTap: _pickDate,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider),
      ),
      child: Row(children: [
        const Icon(Icons.calendar_today_rounded, color: _teal, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _tourDate != null
                ? '${_tourDate!.day}/${_tourDate!.month}/${_tourDate!.year}'
                : 'Select Date',
            style: TextStyle(
                color:
                _tourDate != null ? _textDark : const Color(0xFF8AABAB),
                fontSize: 13),
          ),
        ),
      ]),
    ),
  );

  Widget _timeTile() => GestureDetector(
    onTap: _pickTime,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider),
      ),
      child: Row(children: [
        const Icon(Icons.access_time_rounded, color: _teal, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _tourTime != null
                ? '${_tourTime!.hour.toString().padLeft(2, '0')}:${_tourTime!.minute.toString().padLeft(2, '0')}'
                : 'Select Time',
            style: TextStyle(
                color: _tourTime != null
                    ? _textDark
                    : const Color(0xFF8AABAB),
                fontSize: 13),
          ),
        ),
      ]),
    ),
  );
}