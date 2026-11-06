import 'package:flutter/material.dart';

import '../astro/kundli.dart';
import '../data/cities.dart';
import '../data/city_search.dart';
import '../data/timezones.dart';
import '../models/birth_details.dart';
import '../widgets/format.dart';
import 'chart_screen.dart';

/// Birth details form.
///
/// By default it opens the chart. With [pickOnly] it pops with the
/// [BirthDetails] instead (used by kundli matching).
class BirthFormScreen extends StatefulWidget {
  const BirthFormScreen({super.key, this.pickOnly = false, this.title});

  final bool pickOnly;
  final String? title;

  @override
  State<BirthFormScreen> createState() => _BirthFormScreenState();
}

class _BirthFormScreenState extends State<BirthFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  final _offset = TextEditingController(text: '5:30');
  DateTime? _date;
  TimeOfDay? _time;
  City? _city;
  bool _manual = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    CitySearch.warmUp();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lat.dispose();
    _lon.dispose();
    _offset.dispose();
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

  City? _manualCity() {
    final lat = double.tryParse(_lat.text.trim());
    final lon = double.tryParse(_lon.text.trim());
    final off = parseUtcOffset(_offset.text);
    if (lat == null || lon == null || off == null) return null;
    if (lat.abs() > 90 || lon.abs() > 180) return null;
    return City(
      '${lat.toStringAsFixed(2)}°, ${lon.toStringAsFixed(2)}°',
      'Custom place',
      lat,
      lon,
      country: 'Custom',
      utcOffsetMinutes: off,
    );
  }

  void _submit() {
    setState(() => _submitted = true);
    final formOk = _formKey.currentState!.validate();
    if (!formOk || _date == null || _time == null) return;
    final city = _manual ? _manualCity() : _city;
    if (city == null) return;

    final details = BirthDetails(
      name: _nameController.text.trim(),
      localDateTime: DateTime(
        _date!.year,
        _date!.month,
        _date!.day,
        _time!.hour,
        _time!.minute,
      ),
      city: city,
    ).resolve();

    if (widget.pickOnly) {
      Navigator.of(context).pop(details);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChartScreen(kundli: computeKundli(details)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Birth details')),
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
              value: _date == null ? null : fmtDate(context, _date!),
              error: _submitted && _date == null ? 'Pick a date' : null,
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            _PickerTile(
              icon: Icons.access_time,
              label: 'Time of birth',
              value: _time?.format(context),
              error: _submitted && _time == null ? 'Pick a time' : null,
              onTap: _pickTime,
            ),
            const SizedBox(height: 16),
            if (!_manual)
              Autocomplete<City>(
                displayStringForOption: (c) => c.label,
                optionsBuilder: (value) => CitySearch.search(value.text),
                onSelected: (c) => setState(() => _city = c),
                fieldViewBuilder: (context, controller, focusNode, _) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Place of birth',
                      hintText: 'Town or city, in India or abroad',
                      prefixIcon: Icon(Icons.place_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (_) =>
                        (_city == null || controller.text != _city!.label)
                        ? 'Pick a place from the list'
                        : null,
                  );
                },
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lat,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        hintText: '22.57 (N +, S −)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final x = double.tryParse(v?.trim() ?? '');
                        return x == null || x.abs() > 90 ? '−90 to 90' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lon,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        hintText: '88.36 (E +, W −)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final x = double.tryParse(v?.trim() ?? '');
                        return x == null || x.abs() > 180
                            ? '−180 to 180'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _offset,
                decoration: const InputDecoration(
                  labelText: 'UTC offset at birth',
                  hintText: '5:30 for India, -5 for New York (winter)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    parseUtcOffset(v ?? '') == null ? 'e.g. 5:30 or -4' : null,
              ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _manual = !_manual),
                child: Text(
                  _manual
                      ? 'Search for a place instead'
                      : "Can't find the place? Enter coordinates",
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _submit,
              icon: Icon(widget.pickOnly ? Icons.check : Icons.auto_awesome),
              label: Text(
                widget.pickOnly ? 'Use these details' : 'Generate Kundli',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Place data © GeoNames (geonames.org), CC BY 4.0. Time zones '
                'include historical changes such as India\'s 1942–45 war time.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (_submitted && !_manual && _city == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Choose the place from the suggestions.',
                  style: TextStyle(color: errorColor),
                ),
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String? error;
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
