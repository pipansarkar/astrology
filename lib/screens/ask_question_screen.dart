import 'package:flutter/material.dart';

import '../backend/profile_repository.dart';
import '../backend/question_repository.dart';
import '../notifications/push_service.dart';
import '../models/birth_details.dart';
import 'birth_form_screen.dart';

/// Write a question about a birth chart. Pops with `true` once submitted.
///
/// Pass [details] when opened from a chart; otherwise the user picks one of
/// their saved charts.
class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({super.key, this.details});

  final BirthDetails? details;

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final _questions = QuestionRepository();
  final _text = TextEditingController();

  List<BirthDetails> _profiles = [];
  BirthDetails? _selected;
  bool? _isFree;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.details;
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final free = await _questions.nextQuestionIsFree();
      final profiles = widget.details == null
          ? await ProfileRepository().list()
          : <BirthDetails>[];
      if (!mounted) return;
      setState(() {
        _isFree = free;
        _profiles = profiles;
        _selected ??= profiles.isEmpty ? null : profiles.first;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not connect. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addChart() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BirthFormScreen()));
    // The user may have saved a chart on the way.
    _load();
  }

  Future<void> _submit() async {
    final text = _text.text.trim();
    if (_selected == null) return;
    if (text.length < 10) {
      setState(() => _error = 'Please write at least 10 characters.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _questions.submit(_selected!, text);
      // Ask for notification permission so we can tell them when it's answered.
      await PushService.enable().catchError((_) => false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question sent to the astrologer')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not send. Try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_isFree == false) {
      // Payments are not wired up yet; the server would mark the question
      // as awaiting payment, so don't let users submit it.
      body = ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.lock_clock, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            "You've used your free question",
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Paid questions are coming soon.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (_isFree == null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Could not connect.'),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card.filled(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('Your first question is free'),
              subtitle: const Text('Answered within 24 hours'),
            ),
          ),
          const SizedBox(height: 16),
          Text('About whom?', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (widget.details != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(widget.details!.name),
              subtitle: Text(
                '${loc.formatMediumDate(widget.details!.localDateTime)} · '
                '${widget.details!.city.name}',
              ),
            )
          else if (_profiles.isEmpty)
            OutlinedButton.icon(
              onPressed: _addChart,
              icon: const Icon(Icons.add),
              label: const Text('Create and save a birth chart first'),
            )
          else ...[
            DropdownButtonFormField<BirthDetails>(
              initialValue: _selected,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                for (final p in _profiles)
                  DropdownMenuItem(
                    value: p,
                    child: Text(
                      '${p.name} · ${loc.formatShortDate(p.localDateTime)}',
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _selected = v),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addChart,
                icon: const Icon(Icons.add),
                label: const Text('Another person'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Your question', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            enabled: !_sending,
            minLines: 4,
            maxLines: 8,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. When will I get a stable job?',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _sending || _selected == null ? null : _submit,
            child: _sending
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send question'),
          ),
          const SizedBox(height: 12),
          Text(
            'Astrology offers guidance, not certainty. Please do not ask about '
            'death, serious illness or legal cases; consult a professional '
            'for those.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ask a question')),
      body: body,
    );
  }
}
