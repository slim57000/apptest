import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../providers/habits_provider.dart';
import '../theme.dart';
import 'archived_habits_screen.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? existing;

  const AddHabitScreen({super.key, this.existing});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late String _emoji = widget.existing?.emoji ?? habitEmojiChoices.first;
  late int _color = widget.existing?.colorValue ?? habitColorPalette.first;
  late final Set<int> _weekdays = Set<int>.from(widget.existing?.activeWeekdays ?? const {});
  late int _dailyTarget = widget.existing?.dailyTarget ?? 1;
  late bool _flexible = widget.existing?.isFlexible ?? false;
  late int _weeklyGoal = (widget.existing?.weeklyGoal ?? 0) > 0 ? widget.existing!.weeklyGoal : 3;
  late final List<TimeOfDay> _reminderTimes = (widget.existing?.reminderTimes ?? const [])
      .map((m) => TimeOfDay(hour: m ~/ 60, minute: m % 60))
      .toList();

  bool get _isEditing => widget.existing != null;

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
      appBar: AppBar(title: Text(_isEditing ? l10n.editHabit : l10n.newHabit)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            autofocus: !_isEditing,
            decoration: InputDecoration(
              labelText: l10n.habitNameLabel,
              hintText: l10n.habitNameHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.iconLabel, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
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
          Text(l10n.colorLabel, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
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
          Text(l10n.timesPerDayLabel, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
          Text(l10n.scheduleModeLabel, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
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
            Text(l10n.activeDaysLabel, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(l10n.activeDaysHint, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
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
            Text(l10n.weeklyGoalHint, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
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
          SizedBox(
            width: double.infinity,
            child: Text(l10n.reminderLabel, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: 8),
          if (_reminderTimes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                l10n.reminderNone,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ..._reminderTimes.map((time) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_outlined),
                title: Text(time.format(context)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.removeReminder,
                  onPressed: () => setState(() => _reminderTimes.remove(time)),
                ),
              );
            }),
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: _reminderTimes.length >= Habit.maxReminders ? null : _addReminderTime,
              icon: const Icon(Icons.add),
              label: Text(l10n.addReminder),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _nameController.text.trim().isEmpty ? null : _save,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_isEditing ? l10n.save : l10n.createButton),
            ),
          ),
          if (!_isEditing) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ArchivedHabitsScreen()),
                ),
                icon: const Icon(Icons.archive_outlined),
                label: Text(l10n.archivedHabitsTitle),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) return;
    if (_reminderTimes.any((t) => t.hour == picked.hour && t.minute == picked.minute)) return;
    setState(() {
      _reminderTimes.add(picked);
      _reminderTimes.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final habitsProvider = context.read<HabitsProvider>();
    final reminderMinutes = _reminderTimes.map((t) => t.hour * 60 + t.minute).toList();

    if (_isEditing) {
      final id = widget.existing!.id;
      await habitsProvider.updateHabit(
        id: id,
        name: name,
        emoji: _emoji,
        colorValue: _color,
        activeWeekdays: _flexible ? const {} : _weekdays,
        dailyTarget: _dailyTarget,
        weeklyGoal: _flexible ? _weeklyGoal : 0,
      );
      await habitsProvider.setReminderTimes(id, reminderMinutes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.habitUpdatedMessage)),
        );
      }
    } else {
      await habitsProvider.addHabit(
        name: name,
        emoji: _emoji,
        colorValue: _color,
        activeWeekdays: _flexible ? const {} : _weekdays,
        dailyTarget: _dailyTarget,
        weeklyGoal: _flexible ? _weeklyGoal : 0,
        reminderTimes: reminderMinutes,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }
}
