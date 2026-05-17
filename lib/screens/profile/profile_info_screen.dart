import 'package:app1/config/app_theme.dart';
import 'package:app1/models/body_metrics.dart';
import 'package:app1/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Profile Info: lets the user view and edit their name and body metrics.
///
/// Reads:  GET /users/body-metrics  (via AuthService.fetchBodyMetrics)
/// Writes: POST /users/body-metrics (via AuthService.saveBodyMetrics)
/// Name is stored on Firebase, edited via FirebaseAuth.updateDisplayName.
class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  // null while loading; afterwards either a real BodyMetrics or a default-empty one.
  BodyMetrics? _metrics;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final m = await AuthService.fetchBodyMetrics();
      // If the user has no row yet (null), start from an empty BodyMetrics so
      // the UI still renders and the user can fill it in.
      setState(() {
        _metrics = m ?? const BodyMetrics();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  // ---- Edit handlers --------------------------------------------------------

  Future<void> _editName() async {
    final user = FirebaseAuth.instance.currentUser;
    final controller = TextEditingController(text: user?.displayName ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    try {
      await AuthService.updateDisplayName(newName);
      if (!mounted) return;
      setState(() {}); // FirebaseAuth.currentUser reflects the new name
      _toast('Name updated');
    } catch (e) {
      _toast('Failed: $e');
    }
  }

  Future<void> _editMetrics() async {
    if (_metrics == null) return;
    final updated = await Navigator.of(context).push<BodyMetrics>(
      MaterialPageRoute(
        builder: (_) => _BodyMetricsEditor(initial: _metrics!),
      ),
    );
    if (updated == null) return;

    try {
      await AuthService.saveBodyMetrics(updated);
      if (!mounted) return;
      setState(() => _metrics = updated);
      _toast('Body metrics saved');
    } catch (e) {
      _toast('Failed to save: $e');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Profile info', style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_loadError != null) _ErrorBanner(message: _loadError!),
                  _SectionTitle('Account'),
                  _InfoTile(
                    label: 'Name',
                    value: user?.displayName ?? '—',
                    onEdit: _editName,
                  ),
                  _InfoTile(
                    label: 'Email',
                    value: user?.email ?? '—',
                    // Email change requires re-auth on Firebase; out of scope.
                    onEdit: null,
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle('Body metrics'),
                  if (_metrics != null) _MetricsCard(metrics: _metrics!),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _editMetrics,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit body metrics'),
                  ),
                ],
              ),
            ),
    );
  }
}

// ---- Reusable bits ----------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryDarkColor,
          ),
        ),
      );
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onEdit; // null disables the edit button
  const _InfoTile({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      child: ListTile(
        title: Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
        subtitle: Text(value, style: GoogleFonts.inter(fontSize: 16, color: Colors.black)),
        trailing: onEdit == null
            ? null
            : IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              ),
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  final BodyMetrics metrics;
  const _MetricsCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final hasData = metrics.heightCm > 0 && metrics.weightKg > 0;
    final dobText = metrics.dob == null
        ? '—'
        : '${metrics.dob!.year}-${metrics.dob!.month.toString().padLeft(2, '0')}-${metrics.dob!.day.toString().padLeft(2, '0')}';
    return Card(
      color: Colors.white,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Sex', metrics.sex.name),
            _row('Height', hasData ? '${metrics.heightCm.toStringAsFixed(0)} cm' : '—'),
            _row('Weight', hasData ? '${metrics.weightKg.toStringAsFixed(1)} kg' : '—'),
            _row('Date of birth', dobText),
            _row('Activity', metrics.activityLevel.name),
            _row('Goal', metrics.goalType.name),
            const Divider(height: 20),
            _row('BMI', hasData ? metrics.bmi.toStringAsFixed(1) : '—'),
            _row('TDEE', hasData ? '${metrics.tdee.toStringAsFixed(0)} kcal/day' : '—'),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: GoogleFonts.inter(color: Colors.grey[700])),
            Text(v,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500, color: Colors.black)),
          ],
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(message, style: GoogleFonts.inter(color: Colors.red[800])),
      );
}

// ---- Editor sub-screen ------------------------------------------------------
//
// Lives in this file because it's only used here. It pops with the new
// BodyMetrics on save, or null on cancel.

class _BodyMetricsEditor extends StatefulWidget {
  final BodyMetrics initial;
  const _BodyMetricsEditor({required this.initial});
  @override
  State<_BodyMetricsEditor> createState() => _BodyMetricsEditorState();
}

class _BodyMetricsEditorState extends State<_BodyMetricsEditor> {
  late Sex _sex;
  late TextEditingController _height;
  late TextEditingController _weight;
  DateTime? _dob;
  late ActivityLevel _activity;
  late GoalType _goal;

  @override
  void initState() {
    super.initState();
    _sex = widget.initial.sex;
    _height = TextEditingController(
      text: widget.initial.heightCm > 0
          ? widget.initial.heightCm.toStringAsFixed(0)
          : '',
    );
    _weight = TextEditingController(
      text: widget.initial.weightKg > 0
          ? widget.initial.weightKg.toStringAsFixed(1)
          : '',
    );
    _dob = widget.initial.dob;
    _activity = widget.initial.activityLevel;
    _goal = widget.initial.goalType;
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _save() {
    final h = double.tryParse(_height.text) ?? 0;
    final w = double.tryParse(_weight.text) ?? 0;
    if (h <= 0 || w <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid height and weight')),
      );
      return;
    }
    final updated = widget.initial.copyWith(
      sex: _sex,
      heightCm: h,
      weightKg: w,
      dob: _dob,
      activityLevel: _activity,
      goalType: _goal,
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit body metrics'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<Sex>(
            initialValue: _sex,
            decoration: const InputDecoration(labelText: 'Sex'),
            items: Sex.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                .toList(),
            onChanged: (v) => setState(() => _sex = v ?? Sex.unknown),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _height,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Height (cm)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weight,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Weight (kg)'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date of birth'),
            subtitle: Text(_dob == null
                ? 'Not set'
                : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}'),
            trailing: TextButton(
              onPressed: _pickDob,
              child: const Text('Pick'),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ActivityLevel>(
            initialValue: _activity,
            decoration: const InputDecoration(labelText: 'Activity level'),
            items: ActivityLevel.values
                .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
                .toList(),
            onChanged: (v) =>
                setState(() => _activity = v ?? ActivityLevel.sedentary),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<GoalType>(
            initialValue: _goal,
            decoration: const InputDecoration(labelText: 'Goal'),
            items: GoalType.values
                .map((g) => DropdownMenuItem(value: g, child: Text(g.name)))
                .toList(),
            onChanged: (v) =>
                setState(() => _goal = v ?? GoalType.maintainWeight),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}
