import '../../../core/localization/l10n.dart';

/// The five mandatory criteria, named exactly as the backend names them (the
/// field names of `POST /api/inspections`).
enum InspectionCriterion {
  waterSource('water_source'),
  utensilHygiene('utensil_glove_hygiene'),
  wasteDisposal('waste_disposal'),
  foodCovering('food_covering'),
  overallCleanliness('overall_cleanliness');

  const InspectionCriterion(this.apiField);

  /// The request field the backend reads.
  final String apiField;

  /// The name on screen, in the language in use.
  String get title => switch (this) {
        waterSource => l10n.inspWaterTitle,
        utensilHygiene => l10n.inspUtensilTitle,
        wasteDisposal => l10n.inspWasteTitle,
        foodCovering => l10n.inspCoveringTitle,
        overallCleanliness => l10n.inspCleanTitle,
      };

  /// What the inspector is checking, in the language in use.
  String get description => switch (this) {
        waterSource => l10n.inspWaterDesc,
        utensilHygiene => l10n.inspUtensilDesc,
        wasteDisposal => l10n.inspWasteDesc,
        foodCovering => l10n.inspCoveringDesc,
        overallCleanliness => l10n.inspCleanDesc,
      };
}

/// What an inspector can answer for one criterion (the backend's `CheckResult`).
enum CheckResult {
  pass('pass', 1),
  partial('partial', 0.5),
  fail('fail', 0);

  const CheckResult(this.apiValue, this.points);

  /// The value sent to the API.
  final String apiValue;

  /// The answer on screen, in the language in use.
  String get label => switch (this) {
        pass => l10n.inspPass,
        partial => l10n.inspPartial,
        fail => l10n.inspFail,
      };

  /// What it adds to the score: a full point, half, or none.
  final double points;
}

/// The score the server will compute for [results]: the points add up and are
/// scaled to 5.0 (a pass is 1 point, partial 0.5, fail 0, out of five criteria).
double inspectionScoreOf(Iterable<CheckResult> results) {
  final points = results.fold<double>(0, (sum, result) => sum + result.points);

  return (points / InspectionCriterion.values.length * 5 * 100).round() / 100;
}

/// The score for [passes] passed criteria and nothing else (no partials).
double inspectionScore(int passes) => inspectionScoreOf(List.filled(passes, CheckResult.pass));

/// The grade the server gives a score: 4.5 and up is A+, 3.5 is A, 2.5 is B,
/// below that needs improvement. Same thresholds as the backend's HygieneGrade.
String inspectionGrade(double score) {
  if (score >= 4.5) return 'A+';
  if (score >= 3.5) return 'A';
  if (score >= 2.5) return 'B';

  return l10n.inspGradeNeedsImprovement;
}
