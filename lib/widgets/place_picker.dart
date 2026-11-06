import 'package:flutter/material.dart';

import '../data/cities.dart';
import '../data/city_search.dart';
import '../settings/place_setting.dart';
import '../l10n/l10n.dart';

/// App bar button showing the panjika place; tap to change it.
class PlaceButton extends StatelessWidget {
  const PlaceButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<City>(
      valueListenable: PlaceSetting.notifier,
      builder: (context, city, _) => TextButton.icon(
        onPressed: () async {
          final c = await pickPlace(context);
          if (c != null) PlaceSetting.set(c);
        },
        icon: const Icon(Icons.place_outlined, size: 18),
        label: Text(city.name, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Bottom sheet with offline place search.
Future<City?> pickPlace(BuildContext context) {
  CitySearch.warmUp();
  return showModalBottomSheet<City>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _PlaceSheet(),
  );
}

class _PlaceSheet extends StatefulWidget {
  const _PlaceSheet();

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  List<City> _results = const [];
  int _query = 0;

  Future<void> _search(String q) async {
    final id = ++_query;
    final r = await CitySearch.search(q, limit: 20);
    if (mounted && id == _query) setState(() => _results = r);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: tr('Search town or city'),
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final c in _results)
                    ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(c.name),
                      subtitle: Text(c.label),
                      onTap: () => Navigator.of(context).pop(c),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
