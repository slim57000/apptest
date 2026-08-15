import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/habits_provider.dart';
import '../theme.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _nameController = TextEditingController();
  String _emoji = habitEmojiChoices.first;
  int _color = habitColorPalette.first;
  final Set<int> _weekdays = {};

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weekdayLabels = [
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
      l10n.weekdaySun,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newHabit)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.habitNameLabel,
              hintText: l10n.habitNameHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.iconLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: habitEmojiChoices.map((emoji) {
              final selected = emoji == _emoji;
              return ChoiceChip(
                label: Text(emoji, style: const TextStyle(fontSize: 18)),
                selected: selected,
                onSelected: (_) => setState(() => _emoji = emoji),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(l10n.colorLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: habitColorPalette.map((value) {
              final selected = value == _color;
              return GestureDetector(
                onTap: () => setState(() => _color = value),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(value),
                  child: selected ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(l10n.activeDaysLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(l10n.activeDaysHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final weekday = index + 1;
              final selected = _weekdays.contains(weekday);
              return FilterChip(
                label: Text(weekdayLabels[index]),
                selected: selected,
                onSelected: (value) => setState(() {
                  if (value) {
                    _weekdays.add(weekday);
                  } else {
                    _weekdays.remove(weekday);
                  }
                }),
              );
            }),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _nameController.text.trim().isEmpty ? null : _save,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l10n.createButton),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await context.read<HabitsProvider>().addHabit(
          name: name,
          emoji: _emoji,
          colorValue: _color,
          activeWeekdays: _weekdays,
        );
    if (mounted) Navigator.of(context).pop();
  }
}
