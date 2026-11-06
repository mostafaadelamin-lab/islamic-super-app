import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/content.dart';
import 'l10n_ext.dart';

/// Pick a city from packages/shared-schemas/cities.json. Pops with the City.
class CityPickerScreen extends StatefulWidget {
  const CityPickerScreen({super.key, this.selectedId});
  final String? selectedId;

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final norm = s.content.normalizer;
    final q = _q.trim();
    final nq = norm.normalize(q);
    final cities = <City>[
      for (final c in s.content.cities)
        if (q.isEmpty ||
            c.nameEn.toLowerCase().contains(q.toLowerCase()) ||
            (nq.isNotEmpty && norm.normalize(c.nameAr).contains(nq)) ||
            (nq.isNotEmpty && norm.normalize(c.countryAr).contains(nq)) ||
            c.tz.toLowerCase().contains(q.toLowerCase()))
          c,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.prayerSelectCity)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const Key('citySearch'),
              decoration: InputDecoration(labelText: l.prayerSearchCity, prefixIcon: const Icon(Icons.search)),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: cities.isEmpty
                ? Center(child: Text(l.quranNoResults))
                : ListView.builder(
                    itemCount: cities.length,
                    itemBuilder: (context, i) {
                      final c = cities[i];
                      final selected = c.id == widget.selectedId;
                      return ListTile(
                        key: Key('city-${c.id}'),
                        title: Text(c.name(context.isArabic)),
                        subtitle: Text(context.isArabic ? '${c.countryAr} · ${c.tz}' : '${c.nameAr} · ${c.tz}'),
                        trailing: selected ? const Icon(Icons.check) : null,
                        selected: selected,
                        onTap: () => Navigator.of(context).pop(c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
