import 'package:flutter/material.dart';

import '../astro/kundli.dart';
import '../data/cities.dart';
import '../models/birth_details.dart';
import 'chart_screen.dart';

class BirthFormScreen extends StatefulWidget {
  const BirthFormScreen({super.key});

  @override
  State<BirthFormScreen> createState() => _BirthFormScreenState();
}

class _BirthFormScreenState extends State<BirthFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  City? _city;
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 12, minute: 0),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    setState(() => _submitted = true);
    final formOk = _formKey.currentState!.validate();
    if (!formOk || _date == null || _time == null) return;

    final details = BirthDetails(
      name: _nameController.text.trim(),
      localDateTime: DateTime(
        _date!.year,
        _date!.month,
        _date!.day,
        _time!.hour,
        _time!.minute,
      ),
      city: _city!,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChartScreen(kundli: computeKundli(details)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final loc = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Birth details')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            _PickerTile(
              icon: Icons.calendar_today,
              label: 'Date of birth',
              value: _date == null ? null : loc.formatMediumDate(_date!),
              error: _submitted && _date == null ? 'Pick a date' : null,
              errorColor: errorColor,
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            _PickerTile(
              icon: Icons.access_time,
              label: 'Time of birth',
              value: _time?.format(context),
              error: _submitted && _time == null ? 'Pick a time' : null,
              errorColor: errorColor,
              onTap: _pickTime,
            ),
            const SizedBox(height: 16),
            Autocomplete<City>(
              displayStringForOption: (c) => c.label,
              optionsBuilder: (value) {
                final q = value.text.trim().toLowerCase();
                if (q.isEmpty) return const Iterable<City>.empty();
                return indianCities
                    .where((c) => c.label.toLowerCase().contains(q))
                    .take(8);
              },
              onSelected: (c) => setState(() => _city = c),
              fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Place of birth',
                    hintText: 'Start typing a city',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (_) =>
                      (_city == null || controller.text != _city!.label)
                      ? 'Pick a city from the list'
                      : null,
                );
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Kundli'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.error,
    required this.errorColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String? error;
  final Color errorColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          errorText: error,
        ),
        isEmpty: value == null,
        child: Text(value ?? ''),
      ),
    );
  }
}
