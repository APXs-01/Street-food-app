// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class AppLocalizationsSi extends AppLocalizations {
  AppLocalizationsSi([String locale = 'si']) : super(locale);

  @override
  String get inspTitle => 'පරීක්ෂණ ඉදිරිපත් කිරීම';

  @override
  String get inspSelectStall => 'පරීක්ෂා කිරීමට කඩය තෝරන්න';

  @override
  String get inspSearchHint => 'කඩයේ නම සොයන්න';

  @override
  String get inspNoMatch => 'ගැළපෙන කඩයක් නැත.';

  @override
  String inspStallWithNumber(String name, int number) {
    return '$name (#$number)';
  }

  @override
  String inspLastInspected(String ago) {
    return 'අවසන් වරට පරීක්ෂා කළේ $ago';
  }

  @override
  String get inspChecklistTitle =>
      'සනීපාරක්ෂක පරීක්ෂණ ලැයිස්තුව (අනිවාර්ය නිර්ණායක 5)';

  @override
  String inspScored(int count) {
    return '$count/5 ලකුණු දමා ඇත';
  }

  @override
  String get inspScoreAll => 'කඩයේ ලකුණු බැලීමට නිර්ණායක පහම ලකුණු කරන්න.';

  @override
  String inspWillScore(String score, String grade) {
    return 'කඩයට 5.0න් $score ලැබේ ($grade)';
  }

  @override
  String get inspAttachPhoto => 'පරීක්ෂණ ඡායාරූපය අමුණන්න';

  @override
  String get inspTapCapture => 'පරීක්ෂණ සාක්ෂි ග්‍රහණය කිරීමට තට්ටු කරන්න';

  @override
  String get inspPhotoRequired =>
      'අවශ්‍යයි: පරීක්ෂා කළ ආකාරයෙන් කඩයේ ඡායාරූපයක්';

  @override
  String get inspEvidence => 'සාක්ෂි අමුණා ඇත (ඡායාරූප 1ක්)';

  @override
  String inspToday(String time) {
    return 'අද, $time';
  }

  @override
  String get inspRetake => 'නැවත ගන්න හෝ වෙනත් එකක් තෝරන්න';

  @override
  String get inspServerRecords => 'ඡායාරූපය ලැබුණු වේලාව සේවාදායකය සටහන් කරයි.';

  @override
  String get inspNotes => 'පරීක්ෂකගේ සටහන් (විකල්ප)';

  @override
  String get inspNotesHint =>
      'නිරීක්ෂණ, අවශ්‍ය නිවැරදි කිරීමේ ක්‍රියාමාර්ග, පසු විපරම් දිනය...';

  @override
  String get inspNotesPublic =>
      'සටහන් කඩයේ ප්‍රසිද්ධ සනීපාරක්ෂක පිටුවේ දිස් වේ';

  @override
  String get inspSubmit => 'පරීක්ෂණ ලකුණු ඉදිරිපත් කරන්න';

  @override
  String get inspSubmitHint =>
      'ඉදිරිපත් කිරීමට කඩයක් තෝරා, නිර්ණායක පහම ලකුණු කර, ඡායාරූපයක් අමුණන්න.';

  @override
  String get inspSubmitEffect =>
      'මෙය කඩයේ ප්‍රසිද්ධ සනීපාරක්ෂක ශ්‍රේණිය වහාම යාවත්කාලීන කරයි.';

  @override
  String inspSubmitted(String name, String score, String grade) {
    return '$name පරීක්ෂණය ඉදිරිපත් කරන ලදී. ලකුණු $score ($grade).';
  }

  @override
  String get inspPass => 'සමත්';

  @override
  String get inspPartial => 'අර්ධ වශයෙන්';

  @override
  String get inspFail => 'අසමත්';

  @override
  String get inspGradeNeedsImprovement => 'දියුණු කළ යුතුයි';

  @override
  String get inspWaterTitle => 'ජල ප්‍රභවය';

  @override
  String get inspWaterDesc => 'පිරිසිදු, ගලා එන, ත්‍රිත්ව පෙරහන් කළ ජලය තිබීම';

  @override
  String get inspUtensilTitle => 'අත් සහ උපකරණ සනීපාරක්ෂාව';

  @override
  String get inspUtensilDesc =>
      'අත්වැසුම් සහ විෂබීජ නාශක කළ උපකරණ භාවිතයේ තිබීම';

  @override
  String get inspWasteTitle => 'අපද්‍රව්‍ය බැහැර කිරීම';

  @override
  String get inspWasteDesc =>
      'වසා ඇති කුණු බඳුනක් සහ නිසි ලෙස මුද්‍රා තබා බැහැර කිරීම';

  @override
  String get inspCoveringTitle => 'ආහාර වසා තැබීම';

  @override
  String get inspCoveringDesc =>
      'ආහාර මාර්ග දූවිලි සහ මැස්සන්ගෙන් ආරක්ෂා කර තිබීම';

  @override
  String get inspCleanTitle => 'කඩයේ සමස්ත පිරිසිදුකම';

  @override
  String get inspCleanDesc =>
      'අවට සකස් කිරීමේ කවුන්ටරය සහ බිම විෂබීජහරණය කර තිබීම';

  @override
  String get commonEdit => 'සංස්කරණය';

  @override
  String get categoryKottu => 'කොත්තු';

  @override
  String get categoryShortEats => 'ෂෝට් ඊට්ස්';

  @override
  String get categoryFreshJuice => 'නැවුම් පළතුරු යුෂ';

  @override
  String get categoryHoppers => 'ආප්ප';

  @override
  String get categoryRiceAndCurry => 'බත් සහ කරි';

  @override
  String get categoryBbqSeafood => 'බාබකිව් / මුහුදු ආහාර';

  @override
  String get obLeaveTitle => 'කඩය සැකසීම අත්හරිනවාද?';

  @override
  String get obLeaveBody => 'ඔබට පසුව අවසන් කළ හැක. දැනට ඔබව ඉවත් කෙරේ.';

  @override
  String get obStay => 'රැඳී සිටින්න';

  @override
  String get obSignOut => 'ඉවත් වන්න';

  @override
  String get obTitle => 'ඔබේ ආහාර කඩය සකසන්න';

  @override
  String get obSubtitle =>
      'වීදි ආහාර ඇණවුම් වහාම ලබා ගැනීම ආරම්භ කිරීමට ඔබේ පැතිකඩ සම්පූර්ණ කරන්න.';

  @override
  String get obInstantTitle => 'ක්ෂණික සක්‍රීය කිරීම';

  @override
  String get obInstantBody =>
      'ඔබේ කඩය වහාම සජීවී වේ — අනුමැතිය සඳහා රැඳී සිටීමක් හෝ පරීක්ෂක ප්‍රමාදයක් නැත!';

  @override
  String get obStallName => 'කඩයේ නම';

  @override
  String get obStallNameHint => 'උදා: ඔබේ කඩයේ නම සහ විශේෂ ආහාරය';

  @override
  String get obStallNameTip =>
      'ඔබේ විශේෂ ආහාරය සමඟ ආකර්ශනීය නම් වලට බඩගිනි පාරිභෝගිකයන් 40% ක් වැඩියෙන් ලැබේ.';

  @override
  String get obFoodCategory => 'ආහාර වර්ගය';

  @override
  String get obMultiSelect => 'බහු තේරීම';

  @override
  String get obCategoriesLoadFailed => 'වර්ග පූරණය කළ නොහැකි විය.';

  @override
  String get obStallLocation => 'කඩයේ ස්ථානය';

  @override
  String get obFindingYou => 'ඔබව සොයමින්...';

  @override
  String get obUpdateGps => 'GPS ස්ථානය යාවත්කාලීන කරන්න 📍';

  @override
  String get obUseGps => 'වත්මන් GPS ස්ථානය භාවිත කරන්න 📍';

  @override
  String get obOpenSettings => 'සැකසුම් විවෘත කරන්න';

  @override
  String get obGpsAccurate => 'GPS නිවැරදියි';

  @override
  String get obPinnedLandmark => 'සලකුණු කළ ස්ථානය';

  @override
  String get obCurrentLocation => 'වත්මන් ස්ථානය';

  @override
  String get obNameSpotTitle => 'මෙම ස්ථානයට නමක් දෙන්න';

  @override
  String get obNameSpotHint => 'උදා: බස් නැවතුමට ඉදිරිපිට';

  @override
  String get obOpeningTime => 'විවෘත කරන වේලාව';

  @override
  String get obClosingTime => 'වසන වේලාව';

  @override
  String get obOpens => 'විවෘත වේ';

  @override
  String get obCloses => 'වසා දමයි';

  @override
  String get obSelectTime => 'වේලාව තෝරන්න';

  @override
  String obTimeNotSet(String label) {
    return '$label, සකසා නැත';
  }

  @override
  String obTimeValue(String label, String time) {
    return '$label, $time';
  }

  @override
  String get obOpenEveryDay => 'සතියේ දින 7ම විවෘතයි';

  @override
  String get obDayMon => 'ස';

  @override
  String get obDayTue => 'අ';

  @override
  String get obDayWed => 'බ';

  @override
  String get obDayThu => 'බ්‍ර';

  @override
  String get obDayFri => 'සි';

  @override
  String get obDaySat => 'සෙ';

  @override
  String get obDaySun => 'ඉ';

  @override
  String get obPhotoTitle => 'කඩයේ සහ ආහාරයේ ඡායාරූපය';

  @override
  String get obPhotoTap => 'ඔබේ කඩයේ ඡායාරූපයක් ගැනීමට තට්ටු කරන්න';

  @override
  String get obPhotoHelp =>
      'ඔබේ කඩයේ සහ ආහාරයේ පැහැදිලි ඡායාරූපයක් පාරිභෝගිකයන්ගේ විශ්වාසය ලබා ගැනීමට උපකාරී වේ.';

  @override
  String get obPhotoAction => 'කැමරාව හෝ ගැලරිය විවෘත කරන්න';

  @override
  String get obChangePhoto => 'ඡායාරූපය වෙනස් කරන්න';

  @override
  String get obDescription => 'කෙටි විස්තරය';

  @override
  String get obDescriptionHint => 'කෙටියෙන් සහ කටට රසයි වගේ ලියන්න';

  @override
  String get obAgreement =>
      'ලැයිස්තුගත කිරීමෙන්, නැවුම් අමුද්‍රව්‍ය සහ සනීපාරක්ෂක ආහාර සකස් කිරීමේ සම්මත පවත්වා ගැනීමට ඔබ එකඟ වේ.';

  @override
  String get obSubmit => 'මගේ කඩය ලැයිස්තුගත කර සජීවී වන්න 🚀';

  @override
  String get obZeroCommission =>
      'ඔබේ පළමු ඇණවුම් 50 සඳහා කොමිස් මුදලක් නැත • ඕනෑම වේලාවක සංස්කරණය කරන්න';

  @override
  String get obErrNameRequired => 'ඔබේ කඩයට නමක් දෙන්න.';

  @override
  String obErrNameLong(int max) {
    return 'නම අක්ෂර $maxට අඩු කරන්න.';
  }

  @override
  String get obErrCategories => 'අවම වශයෙන් ආහාර වර්ගයක් තෝරන්න.';

  @override
  String get obErrLocation =>
      'පාරිභෝගිකයන්ට ඔබව සොයා ගත හැකි වන පරිදි ඔබේ කඩයේ ස්ථානය සලකුණු කරන්න.';

  @override
  String get obErrOpens => 'ඔබ විවෘත කරන වේලාව තෝරන්න.';

  @override
  String get obErrCloses => 'ඔබ වසන වේලාව තෝරන්න.';

  @override
  String get obErrCloseDiffer =>
      'වසන වේලාව විවෘත කරන වේලාවට වඩා වෙනස් විය යුතුය.';

  @override
  String get obErrDays => 'ඔබ විවෘතව සිටින දින තෝරන්න.';

  @override
  String get obErrPhoto => 'ඔබේ කඩයේ ඡායාරූපයක් එක් කරන්න.';

  @override
  String obErrDescLong(int max) {
    return 'විස්තරය අක්ෂර $maxකට සීමා කරන්න.';
  }

  @override
  String get settingsTitle => 'යෙදුම් සැකසුම්';

  @override
  String get settingsRowSub => 'භාෂාව, දැනුම්දීම් සහ රහස්‍යතාව';

  @override
  String get settingsLanguage => 'භාෂාව';

  @override
  String get settingsLanguageHelp =>
      'යෙදුම පුරා භාවිත කරන භාෂාව තෝරන්න. වෙනස් කිරීම වහාම බලාත්මක වන අතර මතක තබා ගැනේ.';

  @override
  String get settingsPreferences => 'මනාප';

  @override
  String get settingsNotifications => 'දැනුම්දීම් සැකසුම්';

  @override
  String get settingsNotificationsSub => 'ඔබට ලැබෙන දැනුම්දීම් තෝරන්න';

  @override
  String get settingsFeatureNotifications => 'දැනුම්දීම් සැකසුම්';

  @override
  String get settingsPrivacy => 'රහස්‍යතා සැකසුම්';

  @override
  String get settingsPrivacySub =>
      'ඔබේ ක්‍රියාකාරකම් දැකිය හැක්කේ කාටදැයි පාලනය කරන්න';

  @override
  String get settingsFeaturePrivacy => 'රහස්‍යතා සැකසුම්';

  @override
  String settingsLanguageSelected(String language) {
    return '$language, තෝරා ඇත';
  }

  @override
  String get commonCancel => 'අවලංගු කරන්න';

  @override
  String get commonSave => 'සුරකින්න';

  @override
  String get commonDelete => 'මකන්න';

  @override
  String get commonNotifications => 'දැනුම්දීම්';

  @override
  String get commonComingSoonTag => 'ඉක්මනින් එනවා';

  @override
  String get vhQuickControls => 'වෙළෙන්දාගේ ඉක්මන් පාලන';

  @override
  String get vhRecentReviews => 'මෑත පාරිභෝගික සමාලෝචන';

  @override
  String get vhRecentReviewsSub => 'ඔබේ පාරිභෝගිකයන්ගෙන් අලුත්ම';

  @override
  String get vhSeeAll => 'සියල්ල බලන්න';

  @override
  String vhSeeAllCount(int count) {
    return 'සියල්ල බලන්න ($count)';
  }

  @override
  String get vhNoReviews =>
      'තවම සමාලෝචන නැත. පාරිභෝගිකයන් ඒවා තබන විට මෙහි පෙනේ.';

  @override
  String get vhOpenNowTap => 'දැන් විවෘතයි, වැසීමට තට්ටු කරන්න';

  @override
  String get vhClosedTap => 'වසා ඇත, විවෘත කිරීමට තට්ටු කරන්න';

  @override
  String get vhPillOpen => 'දැන් විවෘතයි 🟢';

  @override
  String get vhPillClosed => 'වසා ඇත';

  @override
  String get vhHygieneScore => 'සනීපාරක්ෂක ලකුණු';

  @override
  String get vhStatusCardTitle => 'අද නැවුම් සූදානම් තත්ත්වය';

  @override
  String get vhNoneLive => 'සජීවී කිසිවක් නැත';

  @override
  String get vhNoStatusBody =>
      'ඔබට රේඩාරයේ කිසිදු තත්ත්වයක් නැත. දැන් නැවුම් දේ පාරිභෝගිකයන්ට දැකිය හැකි වන පරිදි එකක් පළ කරන්න.';

  @override
  String get vhStatLikes => 'ලයික්';

  @override
  String get vhStatComments => 'අදහස්';

  @override
  String get vhPostStatus => 'දෛනික තත්ත්වය පළ කරන්න';

  @override
  String get vhPostStatusDesc =>
      'අද නැවුම් කොටස අවට පාරිභෝගිකයන් සමඟ බෙදාගන්න.';

  @override
  String get vhUpdateMenu => 'මෙනුව යාවත්කාලීන කරන්න';

  @override
  String get vhUpdateMenuDesc =>
      'මිල වෙනස් කර අයිතම නැවුම් හෝ අවසන් ලෙස සලකුණු කරන්න.';

  @override
  String get vhUpdateHours => 'වේලාවන් යාවත්කාලීන කරන්න';

  @override
  String get vhUpdateHoursDesc =>
      'ඔබේ විවෘත කිරීමේ සහ වසා දැමීමේ වේලාවන් සකසන්න.';

  @override
  String get vhViewProfile => 'කඩයේ පැතිකඩ බලන්න';

  @override
  String get vhViewProfileDesc => 'පාරිභෝගිකයන් දකින ආකාරයට ඔබේ කඩය බලන්න.';

  @override
  String get vhSingleTap => 'එක් ස්පර්ශයකින්';

  @override
  String get vacctStatusOpen => 'කඩයේ තත්ත්වය: විවෘතයි';

  @override
  String get vacctStatusClosed => 'කඩයේ තත්ත්වය: වසා ඇත';

  @override
  String get vacctOpenServing => 'විවෘතයි • පාරිභෝගිකයන්ට සේවය කරමින්';

  @override
  String vacctOpenUntil(String time) {
    return '$time දක්වා විවෘතයි • පාරිභෝගිකයන්ට සේවය කරමින්';
  }

  @override
  String get vacctClosedNote => 'වසා ඇත • \"දැන් විවෘත\" සෙවීම්වල නොපෙන්වයි';

  @override
  String get vacctAutoCloses => 'වසන වේලාවෙන් පසු කඩය ස්වයංක්‍රීයව වැසේ.';

  @override
  String get vacctChangeHours => 'වේලාවන් වෙනස් කරන්න';

  @override
  String get vacctConfig => 'වෙළෙන්දා සැකසුම්';

  @override
  String get vacctEditStall => 'කඩයේ විස්තර සංස්කරණය';

  @override
  String get vacctEditStallSub =>
      'නම, වර්ගය, ස්ථාන සලකුණ සහ මුල් පිටු ඡායාරූපය';

  @override
  String get vacctFeatureEditStall => 'ඔබේ කඩයේ විස්තර සංස්කරණය';

  @override
  String get vacctCertificate => 'සනීපාරක්ෂක සහ පරීක්ෂණ සහතිකය';

  @override
  String get vacctCertificateSub =>
      'ඔබේ සනීපාරක්ෂක ලකුණු සහ නවතම පරීක්ෂණ ලැයිස්තුව බලන්න';

  @override
  String get vacctHelp => 'වෙළෙන්දා උදව් සහ පරීක්ෂක ක්ෂණික ඇමතුම';

  @override
  String get vacctHelpSub => 'තවම ලබා ගත නොහැක';

  @override
  String get vacctFeatureHotline => 'පරීක්ෂක ක්ෂණික ඇමතුම';

  @override
  String get vacctLogOut => 'වෙළෙන්දා ගිණුමෙන් ඉවත් වන්න';

  @override
  String vacctStallId(String code) {
    return 'කඩ හැඳුනුම: $code';
  }

  @override
  String vacctAppVersion(String version) {
    return 'යෙදුම් අනුවාදය $version';
  }

  @override
  String get vacctCover => 'මුල් පිටුව';

  @override
  String get vacctFeatureCover => 'ඔබේ මුල් පිටු ඡායාරූපය වෙනස් කිරීම';

  @override
  String get vacctEditPhoto => 'කඩයේ ඡායාරූපය සංස්කරණය';

  @override
  String get vacctFeatureStallPhoto => 'ඔබේ කඩයේ ඡායාරූපය වෙනස් කිරීම';

  @override
  String get vacctVerifiedCleanVendor => 'සත්‍යාපිත පිරිසිදු වෙළෙන්දා';

  @override
  String get vtOpenTitle => 'කඩය විවෘතයි 🟢';

  @override
  String get vtClosedTitle => 'කඩය වසා ඇත';

  @override
  String get vtOpenBody => 'සිතියමේ ඔබව විවෘත ලෙස පාරිභෝගිකයන්ට පෙනේ.';

  @override
  String get vtClosedBody => '\"දැන් විවෘත\" සෙවීම්වලින් සඟවා ඇත.';

  @override
  String get vtCloseToday => 'අද සඳහා වසන්න';

  @override
  String get vtReopen => 'නැවත විවෘත කරන්න';

  @override
  String get vdMerchantControl => 'වෙළෙන්දා පාලනය';

  @override
  String get vdTitle => 'කඩයේ උපකරණ පුවරුව';

  @override
  String get vdCleanVerified => 'පිරිසිදු සහ සත්‍යාපිතයි';

  @override
  String vdDeleteItemTitle(String name) {
    return '$name මකන්නද?';
  }

  @override
  String get vdDeleteItemBody =>
      'එය ඔබේ මෙනුවෙන් ඉවත් වේ. පසුව නැවත එක් කළ හැක.';

  @override
  String get vdKeep => 'තබා ගන්න';

  @override
  String get vdHoursSaved => 'වේලාවන් සුරකින ලදී.';

  @override
  String get vdClosedToast =>
      'දැනට වසා ඇත. නැවත විවෘත කිරීමට \'නැවත විවෘත කරන්න\' ඔබන්න.';

  @override
  String get vdOpenTime => 'විවෘත වේලාව';

  @override
  String get vdCloseTime => 'වසන වේලාව';

  @override
  String get vdExtendHour => 'පැයක් දිගු කරන්න';

  @override
  String get vdCloseEarly => 'කලින් වසන්න';

  @override
  String get vdHoursSavedBtn => 'වේලාවන් සුරකින ලදී';

  @override
  String get vdSaveHours => 'වේලාවන් සුරකින්න';

  @override
  String vdEarlier(int minutes) {
    return 'විනාඩි $minutesකින් කලින්';
  }

  @override
  String vdLater(int minutes) {
    return 'විනාඩි $minutesකින් පසුව';
  }

  @override
  String get vdDailyMenu => 'දෛනික මෙනුව';

  @override
  String vdDailyMenuCount(int count) {
    return 'දෛනික මෙනුව (අයිතම $count)';
  }

  @override
  String get vdAddItem => 'නව අයිතමයක් එක් කරන්න';

  @override
  String get vdMenuEmpty => 'ඔබේ මෙනුව හිස්ය. අද විකුණන ආහාර එක් කරන්න.';

  @override
  String vdEditItemTooltip(String name) {
    return '$name සංස්කරණය';
  }

  @override
  String vdDeleteItemTooltip(String name) {
    return '$name මකන්න';
  }

  @override
  String get vdPreparedness => 'දෛනික සූදානම';

  @override
  String get vdFreshOn => 'අද නැවුම් ✓';

  @override
  String get vdFreshOff => 'නැත';

  @override
  String get vdUnavailable => 'නොමැත';

  @override
  String get vdProfileLink => 'කඩයේ පැතිකඩ සහ ස්ථානය';

  @override
  String get vdProfileLinkBody =>
      'ඔබේ නම, වර්ග, ස්ථානය සහ මුල් පිටු ඡායාරූපය සංස්කරණය කිරීම යෙදුමේ තවම නොමැත.';

  @override
  String get vdFeatureEditProfile => 'ඔබේ කඩයේ පැතිකඩ සංස්කරණය';

  @override
  String get vdEditItemTitle => 'අයිතමය සංස්කරණය';

  @override
  String get vdDishName => 'ආහාරයේ නම';

  @override
  String get vdPrice => 'මිල';

  @override
  String get vdErrName => 'ආහාරයට නමක් දෙන්න.';

  @override
  String get vdErrPrice => 'බිංදුවට වඩා වැඩි මිලක් ඇතුළත් කරන්න, උදා: 4.50.';

  @override
  String get vanFeedback => 'කඩය පිළිබඳ මෑත ප්‍රතිචාර';

  @override
  String vanReviewCount(int count) {
    return 'සමාලෝචන $count';
  }

  @override
  String get vanNoReviews => 'තවම සමාලෝචන නැත.';

  @override
  String get vanShareBadge => 'මගේ සනීපාරක්ෂක ලාංඡනය බෙදාගන්න';

  @override
  String get vanFeatureShareBadge => 'ඔබේ සනීපාරක්ෂක ලාංඡනය බෙදාගැනීම';

  @override
  String get vanTitle => 'වෙළෙන්දාගේ විශ්ලේෂණ';

  @override
  String get vanLiveStall => 'සජීවී කඩය';

  @override
  String get vanClosed => 'වසා ඇත';

  @override
  String get vanCurrentScore => 'වත්මන් සනීපාරක්ෂක ලකුණු';

  @override
  String get vanCustomerRating => 'පාරිභෝගික ශ්‍රේණිගත කිරීම';

  @override
  String get vanNoReviewsSub => 'තවම සමාලෝචන නැත';

  @override
  String vanReviewCountLower(int count) {
    return 'සමාලෝචන $count';
  }

  @override
  String get vanStatusLikes => 'තත්ත්ව ලයික්';

  @override
  String get vanNoLiveStatus => 'සජීවී තත්ත්වයක් නැත';

  @override
  String vanOnStatuses(int count) {
    return 'සජීවී තත්ත්ව $countක';
  }

  @override
  String get vanStatusComments => 'තත්ත්ව අදහස්';

  @override
  String get vanOnLive => 'සජීවී තත්ත්වවල';

  @override
  String get vanStatusViews => 'තත්ත්ව නැරඹුම්';

  @override
  String get vanNotTracked => 'තවම නිරීක්ෂණය නොකෙරේ';

  @override
  String get vanTrendTitle => 'සනීපාරක්ෂක ලකුණු ප්‍රවණතාව';

  @override
  String vanLastInspections(int count) {
    return 'අවසන් පරීක්ෂණ $count';
  }

  @override
  String get vanNoInspections =>
      'තවම පරීක්ෂණ නැත. පරීක්ෂකවරයෙකු පැමිණි පසු ඔබේ ලකුණු මෙහි පෙනේ.';

  @override
  String vanScoredOne(String score) {
    return '5න් $score ලකුණු ලැබී ඇත';
  }

  @override
  String vanScoredRange(String from, String to) {
    return '5න් $from සිට $to දක්වා';
  }

  @override
  String vanChartDate(int day, String month) {
    return '$month $day';
  }

  @override
  String get commonSomeone => 'යමෙක්';

  @override
  String get alertsTitle => 'දැනුම්දීම්';

  @override
  String get alertsSubtitle => 'වීදි කුස්සි සහ කඩ යාවත්කාලීන';

  @override
  String alertsUnreadCount(int count) {
    return 'නොකියවූ $countක්';
  }

  @override
  String get alertsMarkAllRead => 'සියල්ල කියවූ ලෙස සලකුණු කරන්න';

  @override
  String get alertsCaughtUp => 'සියල්ල බලා අවසන්!';

  @override
  String get alertsCaughtUpBody =>
      'ඔබ ප්‍රිය කරන කඩ අනුගමනය කරන්න; ඒවායේ නැවුම් පළ කිරීම් මෙහි පෙනේ.';

  @override
  String get alertsDiscover => 'අසල කඩ සොයන්න';

  @override
  String get alertsFilterAll => 'සියල්ල';

  @override
  String get alertsFilterStalls => 'ඔබ අනුගමනය කරන කඩ';

  @override
  String get alertsFilterCommunity => 'ප්‍රජාව';

  @override
  String get alertTypeStallUpdate => 'කඩ යාවත්කාලීනය';

  @override
  String get alertTypeComment => 'නව අදහසක්';

  @override
  String get alertTypeLike => 'නව ලයික් එකක්';

  @override
  String get alertTypeFriendRequest => 'මිතුරු ඉල්ලීමක්';

  @override
  String get alertTypeNewFriend => 'නව මිතුරෙක්';

  @override
  String get alertTypeHygieneUpdate => 'සනීපාරක්ෂක යාවත්කාලීනය';

  @override
  String get alertTypeRecheck => 'නැවත පරීක්ෂාව කළ යුතුයි';

  @override
  String get alertTypeNewReview => 'නව සමාලෝචනයක්';

  @override
  String get alertTypeOther => 'දැනුම්දීමක්';

  @override
  String alertScoreWas(String score) {
    return 'කලින් $score';
  }

  @override
  String get vaTitle => 'කඩ දැනුම්දීම්';

  @override
  String get vaSubtitle => 'සමාලෝචන, සනීපාරක්ෂක ලකුණු සහ පාරිභෝගික ප්‍රතිචාර';

  @override
  String get vaVendorView => 'වෙළෙන්දා දසුන';

  @override
  String get vaFilterAll => 'සියල්ල';

  @override
  String get vaFilterReviews => 'පාරිභෝගික සමාලෝචන';

  @override
  String get vaFilterHygiene => 'සනීපාරක්ෂක දැනුම්දීම්';

  @override
  String get vaFilterBuzz => 'තත්ත්ව ප්‍රතිචාර';

  @override
  String get vaNone => 'තවම දැනුම්දීම් නැත.';

  @override
  String get vaNothingForFilter => 'මෙම පෙරහනට කිසිවක් නැත.';

  @override
  String get vaSeeReviews => 'සමාලෝචන බලන්න';

  @override
  String get vaReplyUnavailable => 'සමාලෝචනයට පිළිතුරු දෙන්න (තවම නැත)';

  @override
  String get vaViewHygiene => 'සනීපාරක්ෂක වාර්තාව බලන්න';

  @override
  String get vaViewReply => 'බලන්න සහ පිළිතුරු දෙන්න';

  @override
  String get vaViewStatus => 'තත්ත්වය බලන්න';

  @override
  String get profLiveStatuses => 'ඔබේ සජීවී තත්ත්ව';

  @override
  String get profCreateStatus => 'නව තත්ත්වයක් සාදන්න';

  @override
  String get profSettingsNetwork => 'සැකසුම් සහ ජාලය';

  @override
  String get profFriendsNetwork => 'මගේ මිතුරන් සහ ආහාර ප්‍රිය ජාලය';

  @override
  String profConnected(int count) {
    return 'සම්බන්ධ $countක්';
  }

  @override
  String get profFriendsSub => 'ඔබේ ආහාර ප්‍රිය මිතුරන් එක් කර කළමනාකරණය කරන්න';

  @override
  String get profHistory => 'මගේ තත්ත්ව ඉතිහාසය සහ සුරැකුම';

  @override
  String get profHistorySub => 'ඔබේ පසුගිය තත්ත්ව, සජීවී හෝ කල් ඉකුත් වූ';

  @override
  String get profHelp => 'උදව් සහ ආහාර ආරක්ෂණ සහාය';

  @override
  String get profHelpSub => 'තවම නැත';

  @override
  String get profFeatureHelp => 'උදව් සහ ආහාර ආරක්ෂණ සහාය';

  @override
  String get profLogOut => 'පිටවෙන්න';

  @override
  String get profEditPhoto => 'ඡායාරූපය සංස්කරණය (තවම නැත)';

  @override
  String get profFeaturePhoto => 'ඔබේ ඡායාරූපය වෙනස් කිරීම';

  @override
  String get profStatStatuses => 'බෙදාගත් තත්ත්ව';

  @override
  String get profStatFriends => 'ආහාර ප්‍රිය මිතුරන්';

  @override
  String get profStatLive => 'දැන් සජීවී';

  @override
  String get shTitle => 'තත්ත්ව ඉතිහාසය සහ සුරැකුම';

  @override
  String get shEmpty =>
      'ඔබ තවම තත්ත්වයක් පළ කර නැත. ඔබේ පැතිකඩෙන් ඔබ අනුභව කරන දේ බෙදාගන්න.';

  @override
  String get shLive => 'සජීවී';

  @override
  String get shArchived => 'සංරක්ෂිත';

  @override
  String get shHidden => 'සඟවා ඇත';

  @override
  String get frTitle => 'ආහාර ප්‍රිය ජාලය';

  @override
  String get frTabAdd => 'මිතුරෙකු එක් කරන්න';

  @override
  String get frTabRequests => 'ඉල්ලීම්';

  @override
  String get frTabFriends => 'මගේ මිතුරන්';

  @override
  String get frFindTitle => 'ආහාර ප්‍රියයෙකු සොයන්න';

  @override
  String get frFindSub =>
      'ඔවුන්ගේ නිවැරදි පරිශීලක නාමය ටයිප් කරන්න. නමින් හෝ දුරකථන අංකයෙන් සෙවීමක් නැත.';

  @override
  String get frUsernameHint => '@පරිශීලකනාමය';

  @override
  String get frFind => 'සොයන්න';

  @override
  String frNoUser(String username) {
    return '@$username පරිශීලක නාමයෙන් පාරිභෝගිකයෙකු නැත. පරිශීලක නාම හරියටම ගැළපිය යුතුයි.';
  }

  @override
  String frRequestSent(String name) {
    return '$name වෙත ඉල්ලීම යවන ලදී.';
  }

  @override
  String frNowFriends(String name) {
    return 'ඔබ දැන් $name සමඟ මිතුරන්.';
  }

  @override
  String get frDeclined => 'ඉල්ලීම ප්‍රතික්ෂේප කරන ලදී.';

  @override
  String frRemoved(String name) {
    return '$name ඔබේ මිතුරන්ගෙන් ඉවත් කරන ලදී.';
  }

  @override
  String get frAdd => 'එක් කරන්න';

  @override
  String get frNoRequests => 'ඔබ වෙත පැමිණ ඇති මිතුරු ඉල්ලීම් නැත.';

  @override
  String get frActiveFriends => 'සක්‍රිය මිතුරන්';

  @override
  String get frNoFriends =>
      'තවම මිතුරන් නැත. \'මිතුරෙකු එක් කරන්න\' ටැබයෙන් පරිශීලක නාමයෙන් කෙනෙකු සොයන්න.';

  @override
  String get frAccept => 'පිළිගන්න';

  @override
  String get frDecline => 'ප්‍රතික්ෂේප කරන්න';

  @override
  String frFriendsSince(String ago) {
    return 'මිතුරන් · $ago';
  }

  @override
  String get frRemoveFriend => 'මිතුරා ඉවත් කරන්න';

  @override
  String get frMoreOptions => 'තවත් විකල්ප';

  @override
  String get frTipTitle => 'ආහාර ප්‍රිය ජාල ඉඟිය';

  @override
  String get frTipBody =>
      'මිතුරන්ට ඔබේ \'මිතුරන්ට පමණි\' තත්ත්ව පෙනේ; ඔබටත් ඔවුන්ගේ ඒවා ඔබේ දෛනික නැවුම් කතාවල පෙනේ.';

  @override
  String get csTitle => 'නව තත්ත්වය';

  @override
  String get csDiscardTitle => 'මෙම තත්ත්වය ඉවත දමන්නද?';

  @override
  String get csDiscardBody => 'ඔබේ ඡායාරූපය සහ සිරස්තලය නැති වේ.';

  @override
  String get csKeepEditing => 'සංස්කරණය දිගටම කරන්න';

  @override
  String get csDiscard => 'ඉවත දමන්න';

  @override
  String get csPosted => 'තත්ත්වය පළ කළා! එය පැය 24ක් රේඩාරයේ පවතී.';

  @override
  String get csTapPhoto => 'අදට නැවුම් ඡායාරූපයක් එක් කිරීමට තට්ටු කරන්න';

  @override
  String get csCameraOrGallery => 'කැමරාව හෝ ගැලරිය';

  @override
  String get csChooseDifferent => 'වෙනත් රූපයක් තෝරන්න';

  @override
  String get csCaptionTitle => 'ඔබේ රස විමර්ශනය සහ වීදි සටහන';

  @override
  String get csCaptionHint =>
      'දැන් නැවුම් සහ උණු කුමක්ද? උත්සාහ කළ යුතු දේ අයට කියන්න...';

  @override
  String csInsertEmoji(String emoji) {
    return '$emoji ඇතුළත් කරන්න';
  }

  @override
  String get csFoodStall => 'ආහාර කඩය';

  @override
  String csPostingAs(Object name) {
    return '$name ලෙස පළ කරමින්';
  }

  @override
  String get csTagStall => 'කඩයක් ටැග් කරන්න';

  @override
  String get csChange => 'වෙනස් කරන්න';

  @override
  String get csNoStallTagged => 'කඩයක් ටැග් කර නැත';

  @override
  String get csTagOptional => 'අත්‍යවශ්‍ය නොවේ: ඔබේ ඡායාරූපයේ කඩය ටැග් කරන්න';

  @override
  String get csNoNearbyStalls => 'ටැග් කිරීමට අසල කඩ තවම නැත.';

  @override
  String get csWhere => 'කොහේද (අත්‍යවශ්‍ය නොවේ)';

  @override
  String get csWhereHint => 'උදා: ප්‍රධාන දොර අසල';

  @override
  String get csWhereHelper => 'ඔබේ තත්ත්වය සමඟ සාමාන්‍ය පෙළක් ලෙස පෙන්වයි';

  @override
  String get csAudience => 'ප්‍රේක්ෂක දෘශ්‍යතාව';

  @override
  String get csWhoSees => 'මෙය දකින්නේ කවුද?';

  @override
  String csPublic(String brand) {
    return 'ප්‍රසිද්ධ ($brand)';
  }

  @override
  String get csFriendsOnly => 'මිතුරන්ට පමණි';

  @override
  String get csAlwaysPublic => 'කඩ තත්ත්ව සැමවිටම ප්‍රසිද්ධයි.';

  @override
  String get csPost => 'තත්ත්වය පළ කරන්න 🚀';

  @override
  String get csNeedContent => 'පළ කිරීමට ඡායාරූපයක් හෝ සිරස්තලයක් එක් කරන්න.';

  @override
  String get csExpiryNotice =>
      'ඔබේ තත්ත්වය නැවුම් කතා රේඩාරයේ පැය 24ක් දිස් වන අතර ඉන්පසු කල් ඉකුත් වී ඔබේ ඉතිහාසයට යයි.';

  @override
  String get sdPublic => 'ප්‍රසිද්ධ';

  @override
  String sdLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ලයික් $countක්',
      one: 'ලයික් 1ක්',
    );
    return '$_temp0';
  }

  @override
  String get sdLikeLabel => 'ලයික්';

  @override
  String get sdDeleteStatus => 'තත්ත්වය මකන්න';

  @override
  String get sdViewStall => 'කඩය බලන්න';

  @override
  String get sdDeleteTitle => 'මෙම තත්ත්වය මකන්නද?';

  @override
  String get sdDeleteBody =>
      'එය රේඩාරයෙන් එහි ලයික් සහ අදහස් සමඟ අතුරුදහන් වේ.';

  @override
  String get sdKeep => 'තබා ගන්න';

  @override
  String get sdDelete => 'මකන්න';

  @override
  String sdComments(int count) {
    return 'අදහස් ($count)';
  }

  @override
  String get sdNoComments => 'තවම අදහස් නැත. යමක් කියන පළමු පුද්ගලයා වන්න.';

  @override
  String get sdReplyHint => 'ඔබේ අදහස්වලට පිළිතුරු දෙන්න...';

  @override
  String sdCommentHint(String name) {
    return '$name සඳහා අදහසක් එක් කරන්න...';
  }

  @override
  String get sdReact1 => '🔥 රසයි';

  @override
  String get sdReact2 => '🤤 කන්න ආසයි';

  @override
  String get sdReact3 => '👏 ප්‍රධාන සූපවේදියා';

  @override
  String get commonView => 'බලන්න';

  @override
  String get reviewAnonymous => 'නිර්නාමික පාරිභෝගිකයා';

  @override
  String get dayMonday => 'සඳුදා';

  @override
  String get dayTuesday => 'අඟහරුවාදා';

  @override
  String get dayWednesday => 'බදාදා';

  @override
  String get dayThursday => 'බ්‍රහස්පතින්දා';

  @override
  String get dayFriday => 'සිකුරාදා';

  @override
  String get daySaturday => 'සෙනසුරාදා';

  @override
  String get daySunday => 'ඉරිදා';

  @override
  String get dayShortMon => 'සඳු';

  @override
  String get dayShortTue => 'අඟ';

  @override
  String get dayShortWed => 'බදා';

  @override
  String get dayShortThu => 'බ්‍රහ';

  @override
  String get dayShortFri => 'සිකු';

  @override
  String get dayShortSat => 'සෙන';

  @override
  String get dayShortSun => 'ඉරි';

  @override
  String get monthJan => 'ජන';

  @override
  String get monthFeb => 'පෙබ';

  @override
  String get monthMar => 'මාර්';

  @override
  String get monthApr => 'අප්‍රේ';

  @override
  String get monthMay => 'මැයි';

  @override
  String get monthJun => 'ජූනි';

  @override
  String get monthJul => 'ජූලි';

  @override
  String get monthAug => 'අගෝ';

  @override
  String get monthSep => 'සැප්';

  @override
  String get monthOct => 'ඔක්';

  @override
  String get monthNov => 'නොවැ';

  @override
  String get monthDec => 'දෙසැ';

  @override
  String vpFollowing(String name) {
    return '$name අනුගමනය කරමින්.';
  }

  @override
  String vpUnfollowed(String name) {
    return '$name අනුගමනය කිරීම නතර කළා.';
  }

  @override
  String get vpFollow => 'කඩය අනුගමනය කරන්න';

  @override
  String get vpUnfollow => 'කඩය අනුගමනය නතර කරන්න';

  @override
  String vpInspected(String ago) {
    return 'පරීක්ෂා කළේ $ago';
  }

  @override
  String get vpShare => 'බෙදාගන්න';

  @override
  String get vpFeatureSharing => 'බෙදාගැනීම';

  @override
  String get vpCall => 'අමතන්න';

  @override
  String get vpFeatureCalling => 'කඩයට ඇමතීම';

  @override
  String vpDirectionsDistance(String distance) {
    return 'මාර්ගෝපදේශ ($distance)';
  }

  @override
  String get vpTabOverview => 'දළ විශ්ලේෂණය';

  @override
  String get vpTabHygiene => 'සනීපාරක්ෂක විස්තරය';

  @override
  String vpTabReviews(int count) {
    return 'සමාලෝචන ($count)';
  }

  @override
  String vpGrade(String grade) {
    return '$grade ශ්‍රේණිය';
  }

  @override
  String get vpGradeNone => 'තවම නැත';

  @override
  String get vpGradeNeedsWork => 'වැඩිදියුණු කළ යුතුයි';

  @override
  String get vpWaterVerified => 'සත්‍යාපිතයි';

  @override
  String get vpWaterUnverified => 'සත්‍යාපිත නැත';

  @override
  String get vpMetricFoodSafety => 'ආහාර ආරක්ෂාව';

  @override
  String get vpMetricWater => 'ජල ප්‍රභවය';

  @override
  String get vpMetricReview => 'සමාලෝචනය';

  @override
  String get vpMetricReviews => 'සමාලෝචන';

  @override
  String vpAbout(String name) {
    return '$name ගැන';
  }

  @override
  String get vpNoDescription => 'වෙළෙන්දා තවමත් විස්තරයක් එකතු කර නැත.';

  @override
  String get vpMenu => 'මෙනුව';

  @override
  String get vpNoMenu => 'මෙම කඩය තවමත් මෙනුව එකතු කර නැත.';

  @override
  String get vpLeaveReview => 'සමාලෝචනයක් සහ ඡායාරූපයක් තබන්න 📸';

  @override
  String get vpOperatingHours => 'මෙහෙයුම් වේලාවන්';

  @override
  String get vpHoursNotSet => 'වේලාවන් සකසා නැත';

  @override
  String vpHoursOpenNow(String hours) {
    return '$hours (දැන් විවෘතයි)';
  }

  @override
  String vpHoursClosedNow(String hours) {
    return '$hours (දැන් වසා ඇත)';
  }

  @override
  String get vpClosed => 'වසා ඇත';

  @override
  String get vpSoldOut => 'අවසන්';

  @override
  String get vpFreshToday => 'අද නැවුම්';

  @override
  String get vpAuditStatus => 'පරීක්ෂණ තත්ත්වය';

  @override
  String vpLastInspected(String ago) {
    return 'අවසන් වරට පරීක්ෂා කළේ $ago';
  }

  @override
  String get vpRecheckDue => 'නැවත පරීක්ෂාව දැන් කළ යුතුයි';

  @override
  String vpRecheckIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'දින $daysකින් නැවත පරීක්ෂාව',
      one: 'දවසකින් නැවත පරීක්ෂාව',
    );
    return '$_temp0';
  }

  @override
  String get vpInspectingOrg => 'පරීක්ෂා කළ ආයතනය';

  @override
  String get vpNoInspection =>
      'තවම පරීක්ෂණ වාර්තාවක් නැත. නගර සභා පරීක්ෂකවරයෙකු මෙම කඩයට පැමිණි පසු පරීක්ෂණ ලැයිස්තුව මෙහි පෙනේ.';

  @override
  String get vpChecklistTitle => 'කරුණු 5ක පරීක්ෂණ ලැයිස්තුව';

  @override
  String get vpMunicipalStandard => 'නගර සභා ප්‍රමිතිය';

  @override
  String get vpResultPartial => 'අර්ධ වශයෙන් සපුරා ඇත';

  @override
  String get vpResultFail => 'වැඩිදියුණු කළ යුතුයි';

  @override
  String get vpInspectorNotes => 'පරීක්ෂකගේ සටහන්';

  @override
  String get vpEvidencePhoto => 'පරීක්ෂණ සාක්ෂි ඡායාරූපය';

  @override
  String get vpViewArrow => 'බලන්න >';

  @override
  String vpReadReviews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'පාරිභෝගිකයන් $count දෙනෙකු කියන දේ කියවන්න',
      one: 'පාරිභෝගිකයෙකු කියන දේ කියවන්න',
      zero: 'පාරිභෝගික සමාලෝචන තවම නැත',
    );
    return '$_temp0';
  }

  @override
  String get vpReviewsArrow => 'සමාලෝචන >';

  @override
  String get vpHygieneFooter =>
      'සනීපාරක්ෂක ලකුණු නිල පරීක්ෂණවලින් ලැබෙන අතර කලින් කලට නැවත සත්‍යාපනය කෙරේ.';

  @override
  String get criterionWaterTitle => 'ජල ප්‍රභවය';

  @override
  String get criterionWaterDesc => 'සේදීමට සහ පිසීමට පිරිසිදු, ගලා එන ජලය';

  @override
  String get criterionUtensilTitle => 'භාජන සහ අත්වැසුම් සනීපාරක්ෂාව';

  @override
  String get criterionUtensilDesc =>
      'භාජන පිරිසිදුව තබා ඇත; ආහාරවලට අත්වැසුම් හෝ අඬු භාවිතා කරයි';

  @override
  String get criterionWasteTitle => 'අපද්‍රව්‍ය බැහැර කිරීම';

  @override
  String get criterionWasteDesc => 'වැසුම් සහිත බඳුන්, නිතිපතා හිස් කරයි';

  @override
  String get criterionCoveringTitle => 'ආහාර ආවරණය';

  @override
  String get criterionCoveringDesc => 'පිළියෙළ කළ සහ අමු ආහාර ආවරණය කර තබා ඇත';

  @override
  String get criterionCleanTitle => 'කඩයේ සමස්ත පිරිසිදුකම';

  @override
  String get criterionCleanDesc => 'කඩය සහ එහි අවට පරිසරය පිරිසිදුයි';

  @override
  String get reviewFilterAll => 'සියල්ල';

  @override
  String get reviewFilterPhotos => 'ඡායාරූප සහිත';

  @override
  String get reviewsNone =>
      'තවම සමාලෝචන නැත. ඔබ දුටු දේ බෙදාගන්නා පළමු පුද්ගලයා වන්න.';

  @override
  String get reviewsNonePhotos => 'ඡායාරූප සහිත සමාලෝචන තවම නැත.';

  @override
  String get reviewsLoadMore => 'තවත් සමාලෝචන පූරණය කරන්න';

  @override
  String get reviewsCaughtUp => 'සියල්ල බලා අවසන්';

  @override
  String reviewsBasedOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'සමාලෝචන $countක් මත පදනම්ව',
      one: 'සමාලෝචන 1ක් මත පදනම්ව',
      zero: 'තවම සමාලෝචන නැත',
    );
    return '$_temp0';
  }

  @override
  String get reviewReadMore => 'තව කියවන්න';

  @override
  String get reviewShowLess => 'අඩුවෙන් පෙන්වන්න';

  @override
  String get observationCleanArea => 'පිරිසිදු පිසීමේ මතුපිට';

  @override
  String get observationGlovesWorn => 'අත්වැසුම් පළඳී';

  @override
  String get observationCoveredFood => 'ආහාර ආවරණය කර ඇත';

  @override
  String get observationCleanWater => 'පිරිසිදු පෙරූ ජලය';

  @override
  String get observationCoveredBin => 'වැසුම් සහිත කුණු බඳුන';

  @override
  String get observationUncleanArea => 'අපිරිසිදු ප්‍රදේශය';

  @override
  String get observationNoGloves => 'අත්වැසුම් නැත';

  @override
  String get observationUncoveredFood => 'ආවරණය නොකළ ආහාර';

  @override
  String get observationNoWater => 'ගලා එන ජලය නැත';

  @override
  String get observationOverflowingWaste => 'ඉතිරී යන අපද්‍රව්‍ය';

  @override
  String get ruTitle => 'සමාලෝචනයක් තබන්න';

  @override
  String ruStallSubtitle(String name, String number) {
    return '$name ($number)';
  }

  @override
  String get ruTapPhoto => 'ඔබේ ආහාරයේ ඡායාරූපයක් එක් කිරීමට තට්ටු කරන්න';

  @override
  String get ruPhotoOptional =>
      'අත්‍යවශ්‍ය නොවේ, නමුත් ඡායාරූප අන් අයට උපකාරී වේ';

  @override
  String get ruRetake => 'නැවත ගන්න';

  @override
  String get ruPhotoAdded => 'ඡායාරූපය එක් කළා';

  @override
  String ruToday(String time) {
    return 'අද, $time';
  }

  @override
  String get ruPhotoHelp =>
      'ඡායාරූප අනෙක් පාරිභෝගිකයන්ට උපකාරී වේ. ඔබේ ඡායාරූපය ලැබෙන වේලාව සේවාදායකය සටහන් කරයි.';

  @override
  String get ruOverall => 'සමස්ත අත්දැකීම';

  @override
  String get ruRatingNone => 'ශ්‍රේණිගත කිරීමට තරුවක් තට්ටු කරන්න';

  @override
  String get ruRating1 => 'දුර්වලයි (1.0)';

  @override
  String get ruRating2 => 'සාමාන්‍යයට වඩා අඩුයි (2.0)';

  @override
  String get ruRating3 => 'සාමාන්‍යයි (3.0)';

  @override
  String get ruRating4 => 'හොඳයි (4.0)';

  @override
  String get ruRating5 => 'විශිෂ්ට සනීපාරක්ෂාව සහ රසය (5.0)';

  @override
  String ruStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'තරු $countක්',
      one: 'තරු 1ක්',
    );
    return '$_temp0';
  }

  @override
  String get ruObservationsTitle => 'සනීපාරක්ෂක නිරීක්ෂණ';

  @override
  String get ruTapToToggle => 'මාරු කිරීමට තට්ටු කරන්න';

  @override
  String get ruObservationsHelp =>
      'ඔබේ ආහාර වේලේදී ආහාර කරත්තයේ දුටු සනීපාරක්ෂක භාවිතයන් සියල්ල තෝරන්න.';

  @override
  String get ruFeedbackTitle => 'සවිස්තර ප්‍රතිචාර';

  @override
  String get ruFeedbackHint =>
      'ආහාරයේ රසය, කඩයේ පිරිසිදුකම, පිසීමේ සනීපාරක්ෂාව සහ බලා සිටි කාලය විස්තර කරන්න...';

  @override
  String get ruAnonymous => 'නිර්නාමිකව පළ කරන්න';

  @override
  String get ruCommunityTitle => 'ප්‍රජාව මගින් ශක්තිමත් කළ ආරක්ෂාව';

  @override
  String get ruCommunityBody =>
      'ඔබේ සමාලෝචනය සහ ඡායාරූපය අනෙක් පාරිභෝගිකයන්ට පිරිසිදු කඩ තෝරා ගැනීමට උපකාරී වන අතර වෙළෙන්දන්ට දියුණු කළ හැකි තැන් පෙන්වයි. ඔබ නිර්නාමිකව පළ නොකරන්නේ නම් සමාලෝචන ප්‍රසිද්ධයි.';

  @override
  String get ruSubmit => 'සමාලෝචනය යවන්න';

  @override
  String ruThanks(String stall) {
    return 'ස්තූතියි! $stall පිළිබඳ ඔබේ සමාලෝචනය යවන ලදී.';
  }

  @override
  String statusTimeLeftHM(int hours, int minutes) {
    return 'පැය $hoursයි මිනිත්තු $minutesක් ඉතිරියි';
  }

  @override
  String statusTimeLeftM(int minutes) {
    return 'මිනිත්තු $minutesක් ඉතිරියි';
  }

  @override
  String get statusExpired => 'කල් ඉකුත් වී ඇත';

  @override
  String statusExpiresInH(int hours) {
    return 'පැය $hoursකින් කල් ඉකුත් වේ';
  }

  @override
  String statusExpiresInM(int minutes) {
    return 'මිනිත්තු $minutesකින් කල් ඉකුත් වේ';
  }

  @override
  String get navHome => 'මුල් පිටුව';

  @override
  String get navSearch => 'සොයන්න';

  @override
  String get navAlerts => 'දැනුම්දීම්';

  @override
  String get navProfile => 'පැතිකඩ';

  @override
  String get navDashboard => 'උපකරණ පුවරුව';

  @override
  String get navAnalytics => 'විශ්ලේෂණ';

  @override
  String get commonSearch => 'සොයන්න';

  @override
  String get commonAlerts => 'දැනුම්දීම්';

  @override
  String get commonClear => 'මකන්න';

  @override
  String get commonClose => 'වසන්න';

  @override
  String get commonCamera => 'කැමරාව';

  @override
  String get commonGallery => 'ගැලරිය';

  @override
  String get commonDirections => 'මාර්ගෝපදේශ';

  @override
  String commonDistanceKm(String value) {
    return 'කි.මී. $value';
  }

  @override
  String stallNumber(int number) {
    return 'කඩ #$number';
  }

  @override
  String stallDistanceAway(String distance) {
    return '$distance දුරින්';
  }

  @override
  String get stallOpenNow => 'දැන් විවෘතයි';

  @override
  String stallOpenUntil(String time) {
    return '$time දක්වා විවෘතයි';
  }

  @override
  String get stallOpenNowCap => 'දැන් විවෘතයි';

  @override
  String stallOpenNowUntil(String time) {
    return 'දැන් විවෘතයි, $time දක්වා';
  }

  @override
  String get stallClosedNow => 'දැන් වසා ඇත';

  @override
  String get stallRatingNew => 'අලුත්';

  @override
  String get stallClean => 'පිරිසිදුයි';

  @override
  String get stallCaution => 'අවවාදයයි';

  @override
  String stallCleanPercent(int percent) {
    return '$percent% පිරිසිදුයි';
  }

  @override
  String stallWalkMinutes(int minutes) {
    return 'මාර්ගෝපදේශ (මිනිත්තු $minutes)';
  }

  @override
  String get stallViewMenu => 'මෙනුව බලන්න';

  @override
  String get stallOrderPickup => 'ඇණවුම රැගෙන යාම →';

  @override
  String get stallFeaturePickup => 'රැගෙන යාමේ ඇණවුම්';

  @override
  String get hygieneVerifiedClean => 'සත්‍යාපිත පිරිසිදු';

  @override
  String get hygieneHigh => 'ඉහළ සනීපාරක්ෂාව';

  @override
  String get hygieneNeedsRecheck => 'නැවත පරීක්ෂා කළ යුතුයි';

  @override
  String get hygieneNotInspected => 'තවම පරීක්ෂා කර නැත';

  @override
  String get hygieneReverificationPending => 'නැවත සත්‍යාපනය අපේක්ෂිතයි';

  @override
  String get timeAm => 'පෙ.ව.';

  @override
  String get timePm => 'ප.ව.';

  @override
  String get searchCenterCurrent => 'වත්මන් ස්ථානය';

  @override
  String get searchCenterDefault => 'කොළඹ (පෙරනිමි ප්‍රදේශය)';

  @override
  String get homeCurrentSpot => 'වත්මන් ස්ථානය';

  @override
  String get homeStoriesTitle => 'දෛනික නැවුම් කතා';

  @override
  String get homeStoriesCycle => 'පැය 24 චක්‍රය';

  @override
  String get homeStoriesCycleHint => 'කතා පළ කර පැය 24කට පසු අතුරුදහන් වේ.';

  @override
  String get homeNoStories =>
      'දැන් කතා නැත. ඔබ අනුගමනය කරන කඩවල සහ ඔබේ මිතුරන්ගේ තත්ත්ව මෙහි පෙනේ.';

  @override
  String homeStoryTimeLeft(int hours) {
    return 'පැය $hoursක් ඉතිරියි';
  }

  @override
  String get homeRadarTitle => 'සජීවී සනීපාරක්ෂක රේඩාරය';

  @override
  String get homeOpenMap => 'සිතියම විවෘත කරන්න';

  @override
  String get homeNoStallsNearby =>
      'මෙම ස්ථානයේ සිට කි.මී. 25ක් තුළ තවමත් කඩ හමු නොවීය.';

  @override
  String homeRadarStallsNearby(int count) {
    return 'අසල කඩ $countක්';
  }

  @override
  String get homeForYou => 'ඔබ වෙනුවෙන්';

  @override
  String get homeFilterCategory => 'ප්‍රවර්ගය පෙරන්න';

  @override
  String get homeAll => 'සියල්ල';

  @override
  String get homeBestRated => 'ඉහළම ශ්‍රේණිගත වෙළෙන්දන්ගේ කඩ';

  @override
  String get homeBestRatedSub => 'පාරිභෝගිකයන්ගේ ඉහළම තරු ශ්‍රේණිගත කිරීම්';

  @override
  String get homeSeeAll => 'සියල්ල බලන්න';

  @override
  String get homeNoRatings =>
      'තවමත් ශ්‍රේණිගත කිරීම් නැත. කඩයක් සමාලෝචනය කරන පළමු පුද්ගලයා වන්න.';

  @override
  String get homeShopsNear => 'ඔබ අසල කඩ';

  @override
  String homeSortedByProximity(String place) {
    return '$place ට ආසන්නතාව අනුව වර්ග කර ඇත';
  }

  @override
  String get homeSortedByRating => 'ශ්‍රේණිගත කිරීම අනුව වර්ග කර ඇත';

  @override
  String get homeNearbyToggle => 'ආසන්න';

  @override
  String get homeSortByNearby => 'ආසන්නතාව අනුව වර්ග කරන්න';

  @override
  String get homeNoMatch =>
      'ඔබේ පෙරහන්වලට ගැළපෙන කඩ නැත. අරය පුළුල් කරන්න හෝ ප්‍රවර්ගයක් ඉවත් කරන්න.';

  @override
  String get mapFinding => 'කඩ සොයමින්…';

  @override
  String mapOpenStallsNearby(int count) {
    return 'අසල විවෘත කඩ $countක්';
  }

  @override
  String get mapSearchHint => 'කොත්තු, ආප්ප, යුෂ සොයන්න...';

  @override
  String get mapLayers => 'සිතියම් ස්ථර';

  @override
  String get mapUseMyLocation => 'මගේ වත්මන් ස්ථානය භාවිතා කරන්න';

  @override
  String get mapFilters => 'පෙරහන්';

  @override
  String get mapNearbyStalls => 'අසල කඩ';

  @override
  String get mapSortedByDistance => 'දුර අනුව වර්ග කර ඇත';

  @override
  String get mapListView => 'ලැයිස්තු දසුන';

  @override
  String get mapNoMatch =>
      'ගැළපෙන කඩ නැත. වෙනත් සෙවුමක් උත්සාහ කරන්න හෝ පෙරහන් වෙනස් කරන්න.';

  @override
  String get splitLiveRadar => 'සජීවී රේඩාරය';

  @override
  String splitShowing(int count, String radius) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$radius ඇතුළත කඩ $countක් පෙන්වමින්',
      one: '$radius ඇතුළත කඩ 1ක් පෙන්වමින්',
    );
    return '$_temp0';
  }

  @override
  String get splitStallsTitle => 'කඩ';

  @override
  String splitStallsCount(int count) {
    return 'කඩ $countක්';
  }

  @override
  String splitHighHygieneCount(int count) {
    return 'ඉහළ සනීපාරක්ෂාවැති කඩ $countක්';
  }

  @override
  String get splitDetailedCards => 'සවිස්තර කාඩ්පත්';

  @override
  String get splitCompactCards => 'සංක්ෂිප්ත කාඩ්පත්';

  @override
  String get splitSort => 'වර්ග කරන්න';

  @override
  String get splitSortDistance => 'දුර';

  @override
  String get splitSortRating => 'ශ්‍රේණිගත කිරීම';

  @override
  String get splitNoMatch =>
      'මෙම පෙරහන්වලට ගැළපෙන කඩ නැත. අරය පුළුල් කරන්න හෝ ඉහළ සනීපාරක්ෂාව ක්‍රියාවිරහිත කරන්න.';

  @override
  String get searchHint => 'කඩ, ආහාර, ප්‍රවර්ග සොයන්න';

  @override
  String get searchEmptyHint =>
      'කඩයක්, ආහාරයක් හෝ කොත්තු, ආප්ප වැනි ප්‍රවර්ගයක් සොයන්න.';

  @override
  String get searchRecent => 'මෑත සෙවුම්';

  @override
  String searchResultsCount(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '“$query” සඳහා ප්‍රතිඵල $countක්',
      one: '“$query” සඳහා ප්‍රතිඵල 1ක්',
    );
    return '$_temp0';
  }

  @override
  String searchNoResultsTitle(String query) {
    return '“$query” සඳහා ප්‍රතිඵල නැත';
  }

  @override
  String get searchNoResultsBody =>
      'වෙනත් වචනයක් උත්සාහ කරන්න, නැතහොත් පෙරහන් වෙනස් කරන්න: අරය සහ සනීපාරක්ෂක පෙරහන් නිසා කඩ සැඟවී තිබිය හැක.';

  @override
  String get searchAdjustFilters => 'පෙරහන් වෙනස් කරන්න';

  @override
  String get filtersTitle => 'පෙරහන්';

  @override
  String get filtersReset => 'යළි පිහිටුවන්න';

  @override
  String get filtersClearAll => 'සියල්ල ඉවත් කරන්න';

  @override
  String get filtersApply => 'පෙරහන් යොදන්න';

  @override
  String get filtersNoMatch => 'ගැළපෙන කඩ නැත';

  @override
  String filtersShowResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ප්‍රතිඵල $countක් පෙන්වන්න',
      one: 'ප්‍රතිඵල 1ක් පෙන්වන්න',
    );
    return '$_temp0';
  }

  @override
  String get filtersSearchRadius => 'සෙවුම් අරය';

  @override
  String get filtersHygieneRating => 'සනීපාරක්ෂක ශ්‍රේණිය';

  @override
  String get filtersAll => 'සියල්ල';

  @override
  String get filtersHighOnly => 'ඉහළ සනීපාරක්ෂාව පමණි';

  @override
  String get filtersFoodCategory => 'ආහාර ප්‍රවර්ගය';

  @override
  String get filtersOpenNow => 'දැන් විවෘතයි';

  @override
  String get filtersOpenNowSub => 'දැන් සේවය කරන කඩ පමණි';

  @override
  String get commonBack => 'ආපසු';

  @override
  String get commonHelp => 'උදව්';

  @override
  String get commonShowPassword => 'මුරපදය පෙන්වන්න';

  @override
  String get commonHidePassword => 'මුරපදය සඟවන්න';

  @override
  String commonStepOf(int current, int total) {
    return 'පියවර $current / $total';
  }

  @override
  String get authRoleLiveProtocol => 'සජීවී වීදි සනීපාරක්ෂක ප්‍රොටෝකෝලය';

  @override
  String get authRoleVerified => 'සත්‍යාපිතයි';

  @override
  String get authRoleTagline =>
      'සනීපාරක්ෂිත වීදි ආහාර සොයාගෙන ප්‍රාදේශීය කඩවලට සහාය වන්න';

  @override
  String get authRoleSyncing => 'අසල්වැසි කඩ සමමුහුර්ත කරමින්...';

  @override
  String get authTipHeading => 'දෛනික වෙළෙන්දා ප්‍රමිතිය';

  @override
  String get authTip1 =>
      'ඉඟිය: වැසුමක් සහිත කසළ බඳුනක් සොයන්න — එය අපේ ප්‍රධාන සනීපාරක්ෂක පරීක්ෂාවලින් එකක්!';

  @override
  String get authTip2 =>
      'ඉඟිය: ඇණවුම් අතර අත්වැසුම් මාරු කරන වෙළෙන්දන්ට සනීපාරක්ෂාව සඳහා වැඩි ලකුණු ලැබේ.';

  @override
  String get authTip3 =>
      'ඉඟිය: කඩයේ පිරිසිදු, ගලා එන ජලය සෑම පරීක්ෂාවකදීම පරීක්ෂා කෙරේ.';

  @override
  String get authTip4 =>
      'ඉඟිය: දූවිලි සහ මැස්සන්ගෙන් ආවරණය කළ ආහාර, හොඳින් පවත්වාගෙන යන කඩයක ලකුණකි.';

  @override
  String get authRoleChoose => 'ඉදිරියට යාමට ඔබේ භූමිකාව තෝරන්න';

  @override
  String get authRoleCustomerTitle => 'මම පාරිභෝගිකයෙක්';

  @override
  String get authRolePopular => 'ජනප්‍රියයි';

  @override
  String get authRoleCustomerSubtitle =>
      'අසල ඇති පිරිසිදු, රසවත් වීදි ආහාර සොයාගෙන වෙළෙන්දන්ගේ සජීවී යාවත්කාලීන බලන්න';

  @override
  String get authRoleTagGps => 'GPS සොයාගැනීම';

  @override
  String get authRoleTagCleanScore => 'පිරිසිදු ලකුණු සත්‍යාපිතයි';

  @override
  String get authRoleVendorTitle => 'මම වෙළෙන්දෙක්';

  @override
  String get authRoleCommission => 'කොමිස් 0%';

  @override
  String get authRoleVendorSubtitle =>
      'බලා සිටීමකින් තොරව ඔබේ ආහාර කඩය වහාම ලැයිස්තුගත කර දිනපතා ආහාර ගන්නන් වෙත ළඟා වන්න';

  @override
  String get authRoleTagOnboarding => 'විනාඩි 3කින් ක්ෂණික ලියාපදිංචිය';

  @override
  String get authRoleTagCertified => 'පිරිසිදුකම සහතික කරගන්න';

  @override
  String get authRoleDisclaimer =>
      'තෝරා ගැනීමෙන්, ඔබ සම්මත වෙළඳපොළ ආරක්ෂණ මාර්ගෝපදේශ පිළිගනී';

  @override
  String get authFieldEmailOrMobile => 'ඊමේල් හෝ ජංගම දුරකථන අංකය';

  @override
  String get authHintEmailOrMobile => 'උදා: +94 77 123 4567 හෝ name@email.com';

  @override
  String get authHintEmailOrMobileShort => 'name@example.com හෝ +1 (555) 000';

  @override
  String get authHintEmailOrMobileLong => 'name@example.com හෝ +94 77 123 4567';

  @override
  String get authFieldPassword => 'මුරපදය';

  @override
  String get authHintPassword => 'ඔබේ මුරපදය ඇතුළත් කරන්න';

  @override
  String get authHintPasswordMin => 'අවම වශයෙන් අක්ෂර 8ක්';

  @override
  String get authFieldConfirmPassword => 'මුරපදය තහවුරු කරන්න';

  @override
  String get authHintConfirmPassword => 'ඔබේ මුරපදය නැවත ඇතුළත් කරන්න';

  @override
  String get authFieldFullName => 'සම්පූර්ණ නම';

  @override
  String get authHintFullName => 'ඔබේ සම්පූර්ණ නම';

  @override
  String get authForgotPassword => 'මුරපදය අමතකද?';

  @override
  String get authFeaturePasswordReset => 'මුරපදය යළි පිහිටුවීම';

  @override
  String get authLogIn => 'පිවිසෙන්න';

  @override
  String get authOrContinueWith => 'හෝ මෙයින් ඉදිරියට යන්න';

  @override
  String get authOrSignUpWith => 'හෝ මෙයින් ලියාපදිංචි වන්න';

  @override
  String get authGoogleContinue => 'Google සමඟ ඉදිරියට යන්න';

  @override
  String get authFeatureGoogle => 'Google මගින් පිවිසීම';

  @override
  String get authNoAccount => 'ගිණුමක් නැද්ද?';

  @override
  String get authSignUp => 'ලියාපදිංචි වන්න';

  @override
  String get authVendorPortal => 'වෙළෙන්දන්ගේ පෝටලය';

  @override
  String get authAreYouVendor => 'ඔබ ආහාර වෙළෙන්දෙක්ද?';

  @override
  String get authConsumerLoginBadge => 'සත්‍යාපිත ආරක්ෂිත වීදි ආහාර ජාලය';

  @override
  String get authConsumerLoginTitle =>
      'නැවත සාදරයෙන් පිළිගනිමු, ආහාර ප්‍රියයා 👋';

  @override
  String get authConsumerLoginSubtitle =>
      'ඔබ අසල සත්‍යාපිත සනීපාරක්ෂිත වීදි ආහාර සොයාගැනීමට පිවිසෙන්න';

  @override
  String get authTermsRequired => 'ගිණුමක් සෑදීමට ඔබ නියමයන් පිළිගත යුතුයි.';

  @override
  String get authSignupFreeBadge => 'ආහාර සොයන්නන්ට 100% නොමිලේ';

  @override
  String get authCreateAccount => 'ගිණුම සාදන්න';

  @override
  String get authSignupSubtitle =>
      'සහතික කළ සනීපාරක්ෂිත වීදි ආහාර කඩ සොයාගැනීමට සහ සජීවී නැවුම් සකස්කිරීම් නිරීක්ෂණයට එක්වන්න';

  @override
  String get authAgreePre => 'මම ';

  @override
  String get authAgreeTerms => 'සේවා නියමයන්';

  @override
  String get authAgreeAnd => ' සහ ';

  @override
  String get authAgreeGuidelines => 'ආහාර ආරක්ෂණ ප්‍රජා මාර්ගෝපදේශ';

  @override
  String get authAgreePost => ' වලට එකඟ වෙමි.';

  @override
  String get authCertifiedTitle => 'නගර සභා සෞඛ්‍ය සහතිකය ලත්';

  @override
  String get authCertifiedBody =>
      'සජීවී තෙල් පිරිසිදුතා ශ්‍රේණිගත කිරීම්, පරීක්ෂණ මුද්‍රා සහ දෛනික පිරිසිදු කිරීමේ වාර්තා.';

  @override
  String get authAlreadyAccount => 'දැනටමත් ගිණුමක් තිබේද?';

  @override
  String get authLogInArrow => 'පිවිසෙන්න >';

  @override
  String get authVendorEyebrow => 'වෙළෙන්දන්ගේ ප්‍රවේශය';

  @override
  String get authVendorLoginTitle => 'වෙළෙන්දා පිවිසුම 🏪';

  @override
  String get authVendorLoginSubtitle =>
      'ඔබේ කඩය කළමනාකරණය කරන්න, දෛනික කතා පළ කරන්න සහ සජීවී පාරිභෝගික සමාලෝචන බලන්න.';

  @override
  String get authTrustCard => 'කඩය කෙලින්ම කළමනාකරණය — පරිපාලක අතරමැදියෙකු නැත';

  @override
  String get authFieldOwnerContact => 'කඩ හිමියාගේ ජංගම අංකය හෝ ඊමේල්';

  @override
  String get authHintOwnerContact => '+1 (555) 000-0000 හෝ ඊමේල්';

  @override
  String get authFieldVendorPassword => 'මුරපදය හෝ ආරක්ෂණ PIN';

  @override
  String get authHintVendorPassword => 'වෙළෙන්දාගේ මුරපදය ඇතුළත් කරන්න';

  @override
  String get authStaySignedIn => 'පිවිසී සිටින්න';

  @override
  String get authForgotVendorPin => 'වෙළෙන්දාගේ PIN / මුරපදය අමතකද?';

  @override
  String get authVendorLogIn => 'වෙළෙන්දන්ගේ පෝටලයට පිවිසෙන්න';

  @override
  String get authSendOtp => 'SMS මගින් එක්-වරක් භාවිත රහස් කේතයක් යවන්න';

  @override
  String get authFeatureSmsOtp => 'SMS එක්-වරක් රහස් කේත';

  @override
  String get authNewStallOwner => 'නව කඩ හිමියෙක්ද?';

  @override
  String get authCreateVendorAccount => 'වෙළෙන්දා ගිණුමක් සාදන්න';

  @override
  String get authAreYouCustomer => 'ඔබ පාරිභෝගිකයෙක්ද?';

  @override
  String get authSwitchToCustomerLogin => 'පාරිභෝගික පිවිසුමට මාරු වන්න';

  @override
  String get authFooterPrivacy => 'රහස්‍යතා ප්‍රතිපත්තිය';

  @override
  String get authFooterGuidelines => 'වෙළෙන්දන්ගේ මාර්ගෝපදේශ';

  @override
  String get authFooterEmergency => 'හදිසි සහාය';

  @override
  String get authVendorRegistration => 'වෙළෙන්දා ලියාපදිංචිය';

  @override
  String get authPartner => 'හවුල්කරු';

  @override
  String get authVendorSignupSubtitle =>
      'ඔබේ වීදි කුස්සිය හෝ ආහාර කරත්තය ලියාපදිංචි කර සත්‍යාපිත ආහාර ගන්නන් වෙත ළඟා වී දෛනික නැවුම් තත්ත්ව පළ කරන්න.';

  @override
  String get authOwnerFullName => 'හිමියාගේ සම්පූර්ණ නම';

  @override
  String get authSmsReady => 'SMS සූදානම්';

  @override
  String get authAgreeVendorLink => 'වෙළෙන්දන්ගේ වෙළඳ ප්‍රමිති';

  @override
  String authAgreeVendorPost(String brand) {
    return ', නගර සභා සනීපාරක්ෂක ප්‍රොටෝකෝල මාර්ගෝපදේශ සහ $brand ප්‍රජා නියමයන් වලට එකඟ වෙමි.';
  }

  @override
  String get authLookingToOrder => 'ආහාර ඇණවුම් කිරීමට බලාපොරොත්තු වෙනවාද?';

  @override
  String get authSwitchToConsumerSignup => 'පාරිභෝගික ලියාපදිංචියට මාරු වන්න';

  @override
  String get authNextStep => 'ඊළඟ පියවර: කඩය ලියාපදිංචි කිරීම';

  @override
  String get authNextStepTime => 'විනාඩි ~2';

  @override
  String get authNextStepBody =>
      'කඩයේ ස්ථානය සහ ආහාර විශේෂතා ලියාපදිංචි කර ඔබේ සනීපාරක්ෂක සහතික ලාංඡනය උඩුගත කරන්න.';

  @override
  String get commonTryAgain => 'නැවත උත්සාහ කරන්න';

  @override
  String commonComingSoon(String feature) {
    return '$feature ඉක්මනින් එනවා.';
  }

  @override
  String get commonSoon => 'ඉක්මනින්';

  @override
  String errorOffline(String brand) {
    return '$brand වෙත සම්බන්ධ විය නොහැක. ඔබේ සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න.';
  }

  @override
  String get errorGeneric => 'යමක් වැරදුණා. කරුණාකර නැවත උත්සාහ කරන්න.';

  @override
  String get errorUnreadable =>
      'සේවාදායකයේ පිළිතුර කියවිය නොහැකි විය. කරුණාකර නැවත උත්සාහ කරන්න; නැවත නැවතත් සිදුවේ නම් සේවාදායකය පරීක්ෂා කරන්න.';

  @override
  String get errorTooManyAttempts =>
      'උත්සාහයන් වැඩියි. කරුණාකර මිනිත්තුවක් රැඳී සිට නැවත උත්සාහ කරන්න.';

  @override
  String get errorServer =>
      'අපේ පැත්තෙන් යමක් වැරදුණා. කරුණාකර ටික වේලාවකින් නැවත උත්සාහ කරන්න.';

  @override
  String get errorUnexpectedResponse =>
      'සේවාදායකයෙන් අනපේක්ෂිත පිළිතුරක් ලැබුණා. කරුණාකර නැවත උත්සාහ කරන්න.';

  @override
  String get errorSignInAgain => 'කරුණාකර නැවත පිවිසෙන්න.';

  @override
  String get errorNoStall => 'ඔබ තවමත් කඩයක් සකසා නැහැ.';

  @override
  String errorAccountNotSupported(String brand) {
    return 'මෙම ගිණුම $brand යෙදුමේ භාවිතා කළ නොහැක.';
  }

  @override
  String get errorSessionNotSaved =>
      'ඔබේ සැසිය මෙම උපාංගයේ ආරක්ෂිතව සුරැකීමට නොහැකි විය.';

  @override
  String get vendorSetUpMyStall => 'මගේ කඩය සකසන්න';

  @override
  String validationRequired(String label) {
    return '$label අවශ්‍යයි.';
  }

  @override
  String get validationLabelFullName => 'සම්පූර්ණ නම';

  @override
  String get validationLabelEmailOrMobile => 'ඊමේල් හෝ ජංගම දුරකථන අංකය';

  @override
  String get validationLabelPassword => 'මුරපදය';

  @override
  String get validationLabelConfirmPassword => 'මුරපදය තහවුරු කරන්න';

  @override
  String get validationInvalidEmail => 'වලංගු ඊමේල් ලිපිනයක් ඇතුළත් කරන්න.';

  @override
  String get validationInvalidEmailOrMobile =>
      'වලංගු ඊමේල් ලිපිනයක් හෝ ජංගම දුරකථන අංකයක් ඇතුළත් කරන්න.';

  @override
  String validationPasswordTooShort(int count) {
    return 'අවම වශයෙන් අක්ෂර $countක් භාවිතා කරන්න.';
  }

  @override
  String get validationPasswordsMismatch => 'මුරපද නොගැළපේ.';

  @override
  String get locationServicesOff =>
      'මෙම දුරකථනයේ ස්ථාන සේවාව ක්‍රියාවිරහිතයි. එය සක්‍රිය කර නැවත උත්සාහ කරන්න.';

  @override
  String get locationDenied =>
      'ස්ථාන අවසරය ප්‍රතික්ෂේප කරන ලදී. ඔබේ කඩය සලකුණු කිරීමට එයට ඉඩ දී නැවත උත්සාහ කරන්න.';

  @override
  String locationDeniedForever(String brand) {
    return 'ස්ථාන අවසරය අවහිර කර ඇත. සැකසුම් තුළ $brand සඳහා එයට ඉඩ දෙන්න.';
  }

  @override
  String get locationUnavailable =>
      'ඔබේ ස්ථානය ලබා ගැනීමට නොහැකි විය. විවෘත ස්ථානයකට ගොස් නැවත උත්සාහ කරන්න.';

  @override
  String photoCameraBlocked(String brand) {
    return 'කැමරා ප්‍රවේශය අවහිර කර ඇත. සැකසුම් තුළ $brand සඳහා එයට ඉඩ දෙන්න, නැතහොත් ඔබේ ගැලරියෙන් තෝරන්න.';
  }

  @override
  String get photoCameraFailed =>
      'කැමරාව විවෘත කළ නොහැකි විය. ඒ වෙනුවට ගැලරිය උත්සාහ කරන්න.';

  @override
  String photoGalleryBlocked(String brand) {
    return 'ඡායාරූප ප්‍රවේශය අවහිර කර ඇත. සැකසුම් තුළ $brand සඳහා එයට ඉඩ දෙන්න.';
  }

  @override
  String get photoGalleryFailed =>
      'ඔබේ ගැලරිය විවෘත කළ නොහැකි විය. ඒ වෙනුවට කැමරාව උත්සාහ කරන්න.';

  @override
  String get agoJustNow => 'දැන් ම';

  @override
  String agoMinutes(int count) {
    return 'මිනිත්තු $countකට පෙර';
  }

  @override
  String agoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'පැය $countකට පෙර',
      one: 'පැයකට පෙර',
    );
    return '$_temp0';
  }

  @override
  String agoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'දින $countකට පෙර',
      one: 'දවසකට පෙර',
    );
    return '$_temp0';
  }

  @override
  String agoWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'සති $countකට පෙර',
      one: 'සතියකට පෙර',
    );
    return '$_temp0';
  }

  @override
  String get appTitle => 'StreetBite';
}
