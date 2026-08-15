import '../l10n/app_localizations.dart';
import '../theme.dart';

/// Une suggestion d'habitude prête à l'emploi, pour éviter la "page
/// blanche" au premier lancement (le vrai point de friction n°1 des habit
/// trackers). Les noms viennent de [AppLocalizations] : construits à la
/// demande via [buildTemplatePacks], pas de const top-level possible ici.
class HabitTemplate {
  final String name;
  final String emoji;
  final int colorValue;
  final Set<int> activeWeekdays;

  const HabitTemplate({
    required this.name,
    required this.emoji,
    required this.colorValue,
    this.activeWeekdays = const {},
  });
}

class TemplatePack {
  final String title;
  final List<HabitTemplate> templates;

  const TemplatePack({required this.title, required this.templates});
}

List<TemplatePack> buildTemplatePacks(AppLocalizations l10n) {
  return [
    TemplatePack(
      title: l10n.templatePackMorning,
      templates: [
        HabitTemplate(
          name: l10n.templateDrinkWater,
          emoji: '💧',
          colorValue: habitColorPalette[3],
        ),
        HabitTemplate(
          name: l10n.templateMakeBed,
          emoji: '🛏️',
          colorValue: habitColorPalette[0],
        ),
        HabitTemplate(
          name: l10n.templateMeditate,
          emoji: '🧘',
          colorValue: habitColorPalette[1],
        ),
        HabitTemplate(
          name: l10n.templateStretch,
          emoji: '🤸',
          colorValue: habitColorPalette[4],
        ),
      ],
    ),
    TemplatePack(
      title: l10n.templatePackWellness,
      templates: [
        HabitTemplate(
          name: l10n.templateSleepEarly,
          emoji: '😴',
          colorValue: habitColorPalette[0],
        ),
        HabitTemplate(
          name: l10n.templateWalk,
          emoji: '🚶',
          colorValue: habitColorPalette[1],
        ),
        HabitTemplate(
          name: l10n.templateGratitudeJournal,
          emoji: '📝',
          colorValue: habitColorPalette[5],
        ),
      ],
    ),
    TemplatePack(
      title: l10n.templatePackProductivity,
      templates: [
        HabitTemplate(
          name: l10n.templateRead,
          emoji: '📖',
          colorValue: habitColorPalette[3],
        ),
        HabitTemplate(
          name: l10n.templateNoSocialMorning,
          emoji: '📵',
          colorValue: habitColorPalette[2],
        ),
        HabitTemplate(
          name: l10n.templatePlanDay,
          emoji: '🗒️',
          colorValue: habitColorPalette[0],
        ),
        HabitTemplate(
          name: l10n.templateTidyDesk,
          emoji: '🧹',
          colorValue: habitColorPalette[5],
        ),
      ],
    ),
    TemplatePack(
      title: l10n.templatePackScreenFree,
      templates: [
        HabitTemplate(
          name: l10n.templateNoScreenEvening,
          emoji: '📵',
          colorValue: habitColorPalette[2],
        ),
        HabitTemplate(
          name: l10n.templateReadBeforeBed,
          emoji: '📖',
          colorValue: habitColorPalette[3],
        ),
        HabitTemplate(
          name: l10n.templatePrepTomorrow,
          emoji: '🎒',
          colorValue: habitColorPalette[1],
        ),
      ],
    ),
  ];
}
