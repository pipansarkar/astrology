import 'package:flutter/material.dart';

import '../backend/question_repository.dart';
import '../models/question.dart';
import 'ask_question_screen.dart';

String formatRupees(int paise) => '₹${(paise / 100).toStringAsFixed(0)}';

/// The user's questions and answers.
class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final _repo = QuestionRepository();
  late Future<List<Question>> _future = _repo.myQuestions();

  void _reload() => setState(() => _future = _repo.myQuestions());

  Future<void> _ask() async {
    final asked = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AskQuestionScreen()));
    if (asked == true) _reload();
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
          if (items.isEmpty) return const _Intro();
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              itemBuilder: (context, i) => _QuestionCard(
                q: items[i],
                onDelete: () async {
                  await _repo.deleteUnpaid(items[i].id);
                  _reload();
                },
              ),
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.forum_outlined, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Ask an experienced astrologer',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Ask one question about career, marriage, health, money or family. '
          'The astrologer studies your birth chart and current dasha and '
          'replies within 24 hours.\n\nYour first question is free.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.q, required this.onDelete});
  final Question q;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);
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
                    '${q.details.name} · ${loc.formatMediumDate(q.createdAt.toLocal())}',
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
