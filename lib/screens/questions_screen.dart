import 'package:flutter/material.dart';

import '../backend/question_repository.dart';
import '../models/question.dart';
import '../widgets/format.dart';
import 'ask_question_screen.dart';

String formatRupees(int paise) => '₹${(paise / 100).toStringAsFixed(0)}';

/// The user's questions and answers, plus our promise and the astrologers.
class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final _repo = QuestionRepository();
  late Future<List<Question>> _future = _repo.myQuestions();
  late final Future<List<AstrologerProfile>> _astrologers = _repo
      .astrologers()
      .catchError((_) => <AstrologerProfile>[]);

  void _reload() => setState(() => _future = _repo.myQuestions());

  Future<void> _ask() async {
    final asked = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AskQuestionScreen()));
    if (asked == true) _reload();
  }

  Future<void> _rate(Question q, int stars) async {
    final feedback = await showDialog<String>(
      context: context,
      builder: (_) => _FeedbackDialog(stars: stars),
    );
    if (feedback == null) return;
    try {
      await _repo.rate(q.id, stars, feedback);
      _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save your rating.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask an Astrologer')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ask,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Ask a question'),
      ),
      body: FutureBuilder<List<Question>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _Retry(
              message: 'Could not load questions',
              onRetry: _reload,
            );
          }
          final items = snap.data!;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (items.isEmpty) const _Intro(),
                for (final q in items)
                  _QuestionCard(
                    q: q,
                    onDelete: () async {
                      await _repo.deleteUnpaid(q.id);
                      _reload();
                    },
                    onRate: (stars) => _rate(q, stars),
                  ),
                const SizedBox(height: 8),
                const _Promise(),
                const SizedBox(height: 16),
                _Astrologers(future: _astrologers),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Ask an experienced astrologer',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask one question about career, marriage, health, money or '
            'family. The astrologer studies your birth chart and current '
            'dasha and replies within 24 hours. Your first question is free.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// What we commit to: transparent price, deadline, no fear selling.
class _Promise extends StatelessWidget {
  const _Promise();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget item(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Our promise', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            item(
              Icons.sell_outlined,
              'One fixed price per question, shown before you ask. First question free. No hidden charges, no per-minute billing.',
            ),
            item(
              Icons.timer_outlined,
              'An answer within 24 hours. If we miss it, a paid question is refunded in full.',
            ),
            item(
              Icons.block_outlined,
              'No fear-based predictions and no pressure to buy gemstones or costly pujas.',
            ),
            item(
              Icons.lock_outline,
              'Your birth details and questions are private and seen only by the astrologer.',
            ),
            item(
              Icons.star_outline,
              'Rate every answer. Ratings are shown publicly on the astrologer\'s profile.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Astrologers extends StatelessWidget {
  const _Astrologers({required this.future});
  final Future<List<AstrologerProfile>> future;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<AstrologerProfile>>(
      future: future,
      builder: (context, snap) {
        final list = snap.data ?? const [];
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Our astrologers', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final a in list)
              Card.outlined(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(a.name.isEmpty ? '?' : a.name[0]),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.name, style: theme.textTheme.titleSmall),
                                Text(
                                  [
                                    if (a.experienceYears != null)
                                      '${a.experienceYears} years experience',
                                    if (a.languages.isNotEmpty) a.languages,
                                  ].join(' · '),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (a.bio.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(a.bio),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        a.ratingCount == 0
                            ? '${a.answered} answered · no ratings yet'
                            : '★ ${a.ratingAvg!.toStringAsFixed(1)} from '
                                  '${a.ratingCount} rating${a.ratingCount == 1 ? '' : 's'} · '
                                  '${a.answered} answered',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.q,
    required this.onDelete,
    required this.onRate,
  });
  final Question q;
  final VoidCallback onDelete;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (label, color) = switch (q.status) {
      QuestionStatus.answered => ('Answered', scheme.primary),
      QuestionStatus.open => ('Waiting for astrologer', scheme.tertiary),
      QuestionStatus.awaitingPayment => (
        'Payment pending · ${formatRupees(q.pricePaise)}',
        scheme.secondary,
      ),
      QuestionStatus.refunded => ('Refunded', scheme.outline),
    };

    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${q.details.name} · ${fmtDate(context, q.createdAt.toLocal())}',
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(q.question, style: theme.textTheme.titleSmall),
            if (q.answer != null) ...[
              const Divider(height: 24),
              Text(q.answer!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              if (q.rating == null)
                Row(
                  children: [
                    Text(
                      'Rate this answer',
                      style: theme.textTheme.labelMedium,
                    ),
                    const Spacer(),
                    for (var s = 1; s <= 5; s++)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: '$s star${s == 1 ? '' : 's'}',
                        onPressed: () => onRate(s),
                        icon: const Icon(Icons.star_border),
                      ),
                  ],
                )
              else
                Row(
                  children: [
                    for (var s = 1; s <= 5; s++)
                      Icon(
                        s <= q.rating! ? Icons.star : Icons.star_border,
                        size: 18,
                        color: scheme.primary,
                      ),
                    const SizedBox(width: 8),
                    Text('Thanks for rating', style: theme.textTheme.bodySmall),
                  ],
                ),
            ],
            if (q.status == QuestionStatus.open) ...[
              const SizedBox(height: 8),
              Text(
                'You will see the answer here within 24 hours.',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (q.status == QuestionStatus.awaitingPayment)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onDelete,
                  child: const Text('Remove'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackDialog extends StatefulWidget {
  const _FeedbackDialog({required this.stars});
  final int stars;

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${'★' * widget.stars}${'☆' * (5 - widget.stars)}'),
      content: TextField(
        controller: _text,
        maxLength: 500,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Anything to add? (optional)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _text.text),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
