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
  int _dailyTarget = 1;
  bool _flexible = false;
  int _weeklyGoal = 3;
  TimeOfDay? _reminderTime;

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
          // Tuiles circulaires uniformes, alignées au centre : plus lisible
          // que des chips de largeur variable.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: habitEmojiChoices.map((emoji) {
              final selected = emoji == _emoji;
              final scheme = Theme.of(context).colorScheme;
              return GestureDetector(
                onTap: () => setState(() => _emoji = emoji),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                    border: Border.all(
                      color: selected ? scheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: selected ? 24 : 20),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(l10n.colorLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 10,
            children: habitColorPalette.map((value) {
              final selected = value == _color;
              return GestureDetector(
                onTap: () => setState(() => _color = value),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(value),
                    border: selected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2.5,
                          )
                        : null,
                  ),
                  child: selected ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(l10n.timesPerDayLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.outlined(
                icon: const Icon(Icons.remove),
                onPressed: _dailyTarget > 1
                    ? () => setState(() => _dailyTarget--)
                    : null,
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$_dailyTarget',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton.outlined(
                icon: const Icon(Icons.add),
                onPressed: _dailyTarget < 20
                    ? () => setState(() => _dailyTarget++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.scheduleModeLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l10n.modeFixedDays)),
              ButtonSegment(value: true, label: Text(l10n.modeWeeklyGoal)),
            ],
            selected: {_flexible},
            onSelectionChanged: (selection) =>
                setState(() => _flexible = selection.first),
          ),
          const SizedBox(height: 12),
          if (!_flexible) ...[
            Text(l10n.activeDaysLabel, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(l10n.activeDaysHint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
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
          ] else ...[
            Text(l10n.weeklyGoalHint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final goal = index + 1;
                return ChoiceChip(
                  label: Text(l10n.timesPerWeek(goal)),
                  selected: _weeklyGoal == goal,
                  onSelected: (_) => setState(() => _weeklyGoal = goal),
                );
              }),
            ),
          ],
          const SizedBox(height: 24),
          Text(l10n.reminderLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_outlined),
            title: Text(
              _reminderTime == null ? l10n.reminderNone : l10n.reminderAt(_reminderTime!.format(context)),
            ),
            trailing: _reminderTime == null
                ? TextButton(onPressed: _pickReminderTime, child: Text(l10n.addReminder))
                : IconButton(
                    // Corbeille : retire le rappel immédiatement, sans ouvrir
                    // le sélecteur d'heure.
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.removeReminder,
                    onPressed: () => setState(() => _reminderTime = null),
                  ),
            onTap: _pickReminderTime,
          ),
          const SizedBox(height: 24),
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

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await context.read<HabitsProvider>().addHabit(
          name: name,
          emoji: _emoji,
          colorValue: _color,
          activeWeekdays: _flexible ? const {} : _weekdays,
          dailyTarget: _dailyTarget,
          weeklyGoal: _flexible ? _weeklyGoal : 0,
          reminderMinutes: _reminderTime == null
              ? null
              : _reminderTime!.hour * 60 + _reminderTime!.minute,
        );
    if (mounted) Navigator.of(context).pop();
  }
}
