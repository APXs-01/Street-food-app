import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../data/stall_detail_models.dart';

/// What the profile's Hygiene tab says about one point of the municipal
/// checklist. The result (pass, partial or fail) comes from the inspector via
/// `GET /vendors/{id}/hygiene`; this is only the name and what the point covers,
/// in the language in use.
class ChecklistLabel {
  const ChecklistLabel({required this.title, required this.description, required this.icon});

  final String title;
  final String description;
  final IconData icon;
}

/// The five points, in the order the inspector sees them.
const checklistOrder = [
  'water_source',
  'utensil_glove_hygiene',
  'waste_disposal',
  'food_covering',
  'overall_cleanliness',
];

/// The label for a criterion key; an unknown key (a criterion added later) is
/// shown by its own name rather than hidden.
ChecklistLabel checklistLabel(String key) {
  return switch (key) {
    'water_source' => ChecklistLabel(
        title: l10n.criterionWaterTitle,
        description: l10n.criterionWaterDesc,
        icon: Icons.water_drop_outlined,
      ),
    'utensil_glove_hygiene' => ChecklistLabel(
        title: l10n.criterionUtensilTitle,
        description: l10n.criterionUtensilDesc,
        icon: Icons.clean_hands_outlined,
      ),
    'waste_disposal' => ChecklistLabel(
        title: l10n.criterionWasteTitle,
        description: l10n.criterionWasteDesc,
        icon: Icons.delete_outline,
      ),
    'food_covering' => ChecklistLabel(
        title: l10n.criterionCoveringTitle,
        description: l10n.criterionCoveringDesc,
        icon: Icons.takeout_dining_outlined,
      ),
    'overall_cleanliness' => ChecklistLabel(
        title: l10n.criterionCleanTitle,
        description: l10n.criterionCleanDesc,
        icon: Icons.cleaning_services_outlined,
      ),
    _ => ChecklistLabel(title: key.replaceAll('_', ' '), description: '', icon: Icons.fact_check_outlined),
  };
}

/// What a reviewer can tick, by the API's key (`config/streetbite.php`
/// `review_observations`). The app only offers the positive ones; a review
/// carrying a negative key (sent by another client) is still shown. An unknown
/// key is shown as it is.
String reviewObservationLabel(String key) {
  return switch (key) {
    'clean_area' => l10n.observationCleanArea,
    'gloves_worn' => l10n.observationGlovesWorn,
    'covered_food' => l10n.observationCoveredFood,
    'clean_water' => l10n.observationCleanWater,
    'covered_waste_bin' => l10n.observationCoveredBin,
    'unclean_area' => l10n.observationUncleanArea,
    'no_gloves' => l10n.observationNoGloves,
    'uncovered_food' => l10n.observationUncoveredFood,
    'no_running_water' => l10n.observationNoWater,
    'overflowing_waste' => l10n.observationOverflowingWaste,
    _ => key,
  };
}

/// The keys the review form offers, in order.
const positiveObservationKeys = ['clean_area', 'gloves_worn', 'covered_waste_bin', 'clean_water', 'covered_food'];

/// Whether an observation key is a complaint.
bool isNegativeObservation(String key) => !positiveObservationKeys.contains(key);

/// The criteria to show: the five known points in order (a missing one is
/// simply absent), then any the server sent that this app does not know yet.
List<CriterionResult> orderedCriteria(List<CriterionResult> criteria) {
  final byKey = {for (final criterion in criteria) criterion.key: criterion};

  return [
    for (final key in checklistOrder)
      if (byKey.containsKey(key)) byKey[key]!,
    for (final criterion in criteria)
      if (!checklistOrder.contains(criterion.key)) criterion,
  ];
}
