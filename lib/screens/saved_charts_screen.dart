import 'package:flutter/material.dart';

import '../astro/kundli.dart';
import '../backend/profile_repository.dart';
import '../models/birth_details.dart';
import 'chart_screen.dart';

class SavedChartsScreen extends StatefulWidget {
  const SavedChartsScreen({super.key});

  @override
  State<SavedChartsScreen> createState() => _SavedChartsScreenState();
}

class _SavedChartsScreenState extends State<SavedChartsScreen> {
  final _repo = ProfileRepository();
  late Future<List<BirthDetails>> _future = _repo.list();

  void _reload() => setState(() => _future = _repo.list());

  Future<void> _delete(BirthDetails d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete ${d.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.delete(d.id!);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('My charts')),
      body: FutureBuilder<List<BirthDetails>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load charts'),
                  TextButton(onPressed: _reload, child: const Text('Retry')),
                ],
              ),
            );
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No saved charts yet.\nGenerate one and tap save.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final d = items[i];
                return ListTile(
                  title: Text(d.name),
                  subtitle: Text(
                    '${loc.formatMediumDate(d.localDateTime)} · ${d.city.name}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(d),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChartScreen(kundli: computeKundli(d)),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
