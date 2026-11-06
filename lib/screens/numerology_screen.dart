import 'package:flutter/material.dart';

import '../numerology/numerology.dart';
import '../widgets/format.dart';
import '../l10n/l10n.dart';

class NumerologyScreen extends StatefulWidget {
  const NumerologyScreen({super.key});

  @override
  State<NumerologyScreen> createState() => _NumerologyScreenState();
}

class _NumerologyScreenState extends State<NumerologyScreen> {
  final _name = TextEditingController();
  DateTime? _dob;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dob = _dob;
    final nameNo = nameNumber(_name.text);

    return Scaffold(
      appBar: AppBar(title: Text(tr('Numerology'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: tr('Full name (in English letters)'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: dob ?? DateTime(DateTime.now().year - 25),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                initialEntryMode: DatePickerEntryMode.input,
              );
              if (d != null) setState(() => _dob = d);
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              dob == null ? tr('Date of birth') : fmtDate(context, dob),
            ),
          ),
          if (dob != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _Big(tr('Mulank'), mulank(dob), tr('Birth number')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Big(
                    tr('Bhagyank'),
                    bhagyank(dob),
                    tr('Destiny number'),
                  ),
                ),
                if (nameNo != null) ...[
                  const SizedBox(width: 8),
                  Expanded(child: _Big(tr('Name'), nameNo, tr('Name number'))),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: tr('Your birth number {n}', {'n': digits(mulank(dob))}),
              n: mulank(dob),
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: tr('Your destiny number {n}', {
                'n': digits(bhagyank(dob)),
              }),
              n: bhagyank(dob),
            ),
            if (nameNo != null) ...[
              const SizedBox(height: 12),
              Card.outlined(
                margin: EdgeInsets.zero,
                child: ListTile(
                  title: Text(tr('Name number {n}', {'n': digits(nameNo)})),
                  subtitle: Text(tr(nameHarmony(mulank(dob), nameNo))),
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Text(
            tr(
              'Chaldean numerology, as commonly used in India. For '
              'entertainment purposes only.',
            ),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Big extends StatelessWidget {
  const _Big(this.label, this.n, this.caption);
  final String label;
  final int n;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            Text(
              digits(n),
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            Text(caption, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.n});
  final String title;
  final int n;

  @override
  Widget build(BuildContext context) {
    final i = numberInfo[n]!;
    final theme = Theme.of(context);
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              tr('Ruled by {planet}', {'planet': tr(i.planet)}),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Text(tr(i.traits)),
            const SizedBox(height: 8),
            Text(tr('Lucky days: {list}', {'list': i.days.map(tr).join(', ')})),
            Text(
              tr('Lucky colours: {list}', {
                'list': i.colours.map(tr).join(', '),
              }),
            ),
            Text(
              tr('Friendly numbers: {list}', {
                'list': (i.friendly.toList()..sort()).map(digits).join(', '),
              }),
            ),
          ],
        ),
      ),
    );
  }
}
