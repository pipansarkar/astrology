import 'package:flutter/material.dart';

import '../astro/ephemeris.dart';
import '../astro/kundli.dart';
import '../astrologer/reading_assistant.dart';
import '../backend/question_repository.dart';
import '../models/question.dart';
import '../notifications/push_service.dart';
import '../widgets/reading_assistant_panel.dart';
import '../widgets/format.dart';
import 'chart_screen.dart';

/// Astrologer's work queue: open questions (oldest first) and recent answers.
class AstrologerDeskScreen extends StatefulWidget {
  const AstrologerDeskScreen({super.key});

  @override
  State<AstrologerDeskScreen> createState() => _AstrologerDeskScreenState();
}

class _AstrologerDeskScreenState extends State<AstrologerDeskScreen> {
  final _repo = QuestionRepository();
  late Future<List<Question>> _open = _repo.openQuestions();
  late Future<List<Question>> _done = _repo.answeredByMe();

  @override
  void initState() {
    super.initState();
    PushService.enable().catchError((_) => false);
  }

  void _reload() => setState(() {
    _open = _repo.openQuestions();
    _done = _repo.answeredByMe();
  });

  Future<void> _openQuestion(Question q) async {
    final answered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AnswerQuestionScreen(question: q)),
    );
    if (answered == true) _reload();
  }

  Widget _list(Future<List<Question>> future, String empty) {
    return FutureBuilder<List<Question>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: TextButton(
              onPressed: _reload,
              child: const Text('Could not load. Retry'),
            ),
          );
        }
        final items = snap.data!;
        if (items.isEmpty) return Center(child: Text(empty));
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final q = items[i];
              final age = DateTime.now().difference(q.createdAt.toLocal());
              return ListTile(
                title: Text(
                  q.question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${q.details.name} · '
                  '${fmtDate(context, q.createdAt.toLocal())}'
                  '${q.status == QuestionStatus.open ? ' · ${age.inHours} h waiting' : ''}'
                  '${q.rating != null ? ' · ${'★' * q.rating!}' : ''}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openQuestion(q),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Astrologer desk'),
          actions: [
            IconButton(
              tooltip: 'My public profile',
              icon: const Icon(Icons.badge_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AstrologerProfileScreen(),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Open'),
              Tab(text: 'Answered'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _list(_open, 'No open questions. 🙏'),
            _list(_done, 'Nothing answered yet.'),
          ],
        ),
      ),
    );
  }
}

class AnswerQuestionScreen extends StatefulWidget {
  const AnswerQuestionScreen({super.key, required this.question});
  final Question question;

  @override
  State<AnswerQuestionScreen> createState() => _AnswerQuestionScreenState();
}

class _AnswerQuestionScreenState extends State<AnswerQuestionScreen> {
  final _answer = TextEditingController();
  late final Kundli _kundli = computeKundli(widget.question.details);
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _answer.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await QuestionRepository().answer(widget.question.id, text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not send. It may already be answered.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);
    final q = widget.question;
    final d = q.details;
    final moon = _kundli.planet(Body.moon);
    final now = DateTime.now().toUtc();
    final md = _kundli.dashas.where((p) => p.contains(now)).firstOrNull;
    final ad = md?.subPeriods.where((p) => p.contains(now)).firstOrNull;
    final isOpen = q.status == QuestionStatus.open;

    return Scaffold(
      appBar: AppBar(title: Text(d.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(q.question, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(
            '${fmtDate(context, d.localDateTime)}, '
            '${loc.formatTimeOfDay(TimeOfDay.fromDateTime(d.localDateTime))} · '
            '${d.city.label}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Lagna ${signNames[_kundli.lagna.sign]} · '
            'Moon ${signNames[moon.sign]}, ${moon.nakshatraLabel}'
            '${md == null ? '' : ' · Dasha ${bodyNames[md.lord]}–${bodyNames[ad?.lord] ?? ''}'}',
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChartScreen(kundli: _kundli)),
              ),
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('View full chart'),
            ),
          ),
          const SizedBox(height: 8),
          ReadingAssistantPanel(
            kundli: _kundli,
            question: q.question,
            onUseDraft: isOpen
                ? (Reading r) {
                    _answer.text = r.draft;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Draft inserted. Please review and edit it.',
                        ),
                      ),
                    );
                  }
                : null,
          ),
          const Divider(height: 24),
          if (isOpen) ...[
            TextField(
              controller: _answer,
              enabled: !_sending,
              minLines: 6,
              maxLines: 16,
              maxLength: 5000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Your answer',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _sending ? null : _send,
              child: const Text('Send answer'),
            ),
          ] else
            Text(q.answer ?? '', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Lets an astrologer edit the profile users see.
class AstrologerProfileScreen extends StatefulWidget {
  const AstrologerProfileScreen({super.key});

  @override
  State<AstrologerProfileScreen> createState() =>
      _AstrologerProfileScreenState();
}

class _AstrologerProfileScreenState extends State<AstrologerProfileScreen> {
  final _repo = QuestionRepository();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _languages = TextEditingController();
  final _years = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repo.myProfile().then(
      (p) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          if (p != null) {
            _name.text = p.name;
            _bio.text = p.bio;
            _languages.text = p.languages;
            _years.text = p.experienceYears?.toString() ?? '';
          }
        });
      },
      onError: (_) {
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  @override
  void dispose() {
    for (final c in [_name, _bio, _languages, _years]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await _repo.updateMyProfile(
        AstrologerProfile(
          name: _name.text.trim(),
          bio: _bio.text.trim(),
          languages: _languages.text.trim(),
          experienceYears: int.tryParse(_years.text.trim()),
        ),
      );
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save the profile.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String label, [String? hint]) => InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('My public profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Users see this on the Ask an Astrologer screen, with your '
                  'rating and number of answers.',
                ),
                const SizedBox(height: 16),
                TextField(controller: _name, decoration: deco('Display name')),
                const SizedBox(height: 16),
                TextField(
                  controller: _bio,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: deco(
                    'About you',
                    'Your background, tradition and what you help with',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _languages,
                  decoration: deco('Languages', 'Bengali, Hindi, English'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _years,
                  keyboardType: TextInputType.number,
                  decoration: deco('Years of experience'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Save'),
                ),
              ],
            ),
    );
  }
}
