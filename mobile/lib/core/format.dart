import 'localization/l10n.dart';

/// `Just now`, `25 min ago`, `1 hour ago`, `3 hours ago`, `1 day ago`, `2 weeks ago`,
/// in the language the app is showing.
String agoLabel(Duration age) {
  if (age.inMinutes < 1) return l10n.agoJustNow;
  if (age.inMinutes < 60) return l10n.agoMinutes(age.inMinutes);
  if (age.inHours < 24) return l10n.agoHours(age.inHours);
  if (age.inDays < 7) return l10n.agoDays(age.inDays);

  return l10n.agoWeeks(age.inDays ~/ 7);
}

/// How long ago [then] was, as words; empty if [then] is unknown.
String agoFrom(DateTime? then, {DateTime? now}) {
  if (then == null) return '';

  return agoLabel((now ?? DateTime.now()).difference(then));
}

/// The first letter of [name], uppercased, for an initial avatar.
String initialOf(String name) => name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase();
