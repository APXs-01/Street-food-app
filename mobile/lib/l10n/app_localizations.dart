import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
  ];

  /// Title of the inspector checklist screen.
  ///
  /// In en, this message translates to:
  /// **'Inspection Submission'**
  String get inspTitle;

  /// Heading above the stall search.
  ///
  /// In en, this message translates to:
  /// **'Select Stall to Inspect'**
  String get inspSelectStall;

  /// Hint of the stall search field.
  ///
  /// In en, this message translates to:
  /// **'Search stall name'**
  String get inspSearchHint;

  /// Shown when the stall search finds nothing.
  ///
  /// In en, this message translates to:
  /// **'No stall matches.'**
  String get inspNoMatch;

  /// Selected stall's name with its number.
  ///
  /// In en, this message translates to:
  /// **'{name} (#{number})'**
  String inspStallWithNumber(String name, int number);

  /// Selected stall's last inspection, with a relative time.
  ///
  /// In en, this message translates to:
  /// **'Last inspected {ago}'**
  String inspLastInspected(String ago);

  /// Heading of the five criteria.
  ///
  /// In en, this message translates to:
  /// **'Hygiene Checklist (5 Mandatory Criteria)'**
  String get inspChecklistTitle;

  /// How many criteria have been answered.
  ///
  /// In en, this message translates to:
  /// **'{count}/5 Scored'**
  String inspScored(int count);

  /// Hint before every criterion is answered.
  ///
  /// In en, this message translates to:
  /// **'Score all five criteria to see the stall\'s score.'**
  String get inspScoreAll;

  /// Preview of the score once every criterion is answered.
  ///
  /// In en, this message translates to:
  /// **'The stall will score {score} / 5.0 ({grade})'**
  String inspWillScore(String score, String grade);

  /// Heading of the photo section.
  ///
  /// In en, this message translates to:
  /// **'Attach Inspection Photo'**
  String get inspAttachPhoto;

  /// Photo drop zone heading.
  ///
  /// In en, this message translates to:
  /// **'Tap to capture inspection evidence'**
  String get inspTapCapture;

  /// Photo drop zone help text.
  ///
  /// In en, this message translates to:
  /// **'Required: a photo of the stall as inspected'**
  String get inspPhotoRequired;

  /// Shown once a photo is chosen.
  ///
  /// In en, this message translates to:
  /// **'Evidence attached (1 photo)'**
  String get inspEvidence;

  /// When the photo was taken.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String inspToday(String time);

  /// Link under the chosen photo.
  ///
  /// In en, this message translates to:
  /// **'Retake or choose another'**
  String get inspRetake;

  /// Note under the photo section.
  ///
  /// In en, this message translates to:
  /// **'The server records when the photo arrives.'**
  String get inspServerRecords;

  /// Heading of the notes field.
  ///
  /// In en, this message translates to:
  /// **'Inspector Notes (Optional)'**
  String get inspNotes;

  /// Hint of the notes field.
  ///
  /// In en, this message translates to:
  /// **'Observations, corrective actions required, follow-up date...'**
  String get inspNotesHint;

  /// Note under the notes field.
  ///
  /// In en, this message translates to:
  /// **'Notes appear on the stall\'s public hygiene page'**
  String get inspNotesPublic;

  /// Submit button.
  ///
  /// In en, this message translates to:
  /// **'Submit Inspection Score'**
  String get inspSubmit;

  /// Caption under the disabled submit button.
  ///
  /// In en, this message translates to:
  /// **'Pick a stall, score all five criteria and attach a photo to submit.'**
  String get inspSubmitHint;

  /// Caption under the enabled submit button.
  ///
  /// In en, this message translates to:
  /// **'This will update the stall\'s public hygiene rating immediately.'**
  String get inspSubmitEffect;

  /// Snackbar after a successful submission.
  ///
  /// In en, this message translates to:
  /// **'Inspection of {name} submitted. It scores {score} ({grade}).'**
  String inspSubmitted(String name, String score, String grade);

  /// Answer for a criterion.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get inspPass;

  /// Answer for a criterion.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get inspPartial;

  /// Answer for a criterion.
  ///
  /// In en, this message translates to:
  /// **'Fail'**
  String get inspFail;

  /// Grade below B. The grades A+, A and B are not translated.
  ///
  /// In en, this message translates to:
  /// **'Needs Improvement'**
  String get inspGradeNeedsImprovement;

  /// Criterion title.
  ///
  /// In en, this message translates to:
  /// **'Water Source'**
  String get inspWaterTitle;

  /// Criterion description.
  ///
  /// In en, this message translates to:
  /// **'Clean, running triple-filtered water available'**
  String get inspWaterDesc;

  /// Criterion title.
  ///
  /// In en, this message translates to:
  /// **'Hand & Utensil Hygiene'**
  String get inspUtensilTitle;

  /// Criterion description.
  ///
  /// In en, this message translates to:
  /// **'Gloves & sanitized utensils in active use'**
  String get inspUtensilDesc;

  /// Criterion title.
  ///
  /// In en, this message translates to:
  /// **'Waste Disposal'**
  String get inspWasteTitle;

  /// Criterion description.
  ///
  /// In en, this message translates to:
  /// **'Covered waste bin with proper sealed disposal'**
  String get inspWasteDesc;

  /// Criterion title.
  ///
  /// In en, this message translates to:
  /// **'Food Covering'**
  String get inspCoveringTitle;

  /// Criterion description.
  ///
  /// In en, this message translates to:
  /// **'Food protected from street dust & flies'**
  String get inspCoveringDesc;

  /// Criterion title.
  ///
  /// In en, this message translates to:
  /// **'Overall Stall Cleanliness'**
  String get inspCleanTitle;

  /// Criterion description.
  ///
  /// In en, this message translates to:
  /// **'Surrounding prep counter & floor sanitized'**
  String get inspCleanDesc;

  /// Edit link or button.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// Food category name (slug kottu).
  ///
  /// In en, this message translates to:
  /// **'Kottu'**
  String get categoryKottu;

  /// Food category name (slug short-eats). TODO(si-review): Transliterated; confirm whether a Sinhala term (e.g. කෙටි ආහාර) is preferred.
  ///
  /// In en, this message translates to:
  /// **'Short Eats'**
  String get categoryShortEats;

  /// Food category name (slug fresh-juice).
  ///
  /// In en, this message translates to:
  /// **'Fresh Juice'**
  String get categoryFreshJuice;

  /// Food category name (slug hoppers).
  ///
  /// In en, this message translates to:
  /// **'Hoppers'**
  String get categoryHoppers;

  /// Food category name (slug rice-and-curry).
  ///
  /// In en, this message translates to:
  /// **'Rice & Curry'**
  String get categoryRiceAndCurry;

  /// Food category name (slug bbq-seafood). TODO(si-review): 'BBQ' transliterated; confirm.
  ///
  /// In en, this message translates to:
  /// **'BBQ / Seafood'**
  String get categoryBbqSeafood;

  /// Dialog title when leaving the onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Leave stall setup?'**
  String get obLeaveTitle;

  /// Dialog body when leaving the onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'You can finish later. You will be signed out for now.'**
  String get obLeaveBody;

  /// Dialog button that stays on the onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get obStay;

  /// Dialog button that signs out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get obSignOut;

  /// Heading of the onboarding form.
  ///
  /// In en, this message translates to:
  /// **'Setup Your Food Stall'**
  String get obTitle;

  /// Subheading of the onboarding form.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to start receiving street-food orders instantly.'**
  String get obSubtitle;

  /// Title of the green info card.
  ///
  /// In en, this message translates to:
  /// **'Instant Activation'**
  String get obInstantTitle;

  /// Body of the green info card.
  ///
  /// In en, this message translates to:
  /// **'Your stall goes live immediately — no approval wait or inspector delay!'**
  String get obInstantBody;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Stall Name'**
  String get obStallName;

  /// Field hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. your stall\'s name and signature dish'**
  String get obStallNameHint;

  /// Tip under the stall name field (marketing copy from the design; the 40% figure is not backed by data). TODO(si-review): Marketing wording; confirm tone.
  ///
  /// In en, this message translates to:
  /// **'Catchy names with your signature dish get 40% more hungry customers.'**
  String get obStallNameTip;

  /// Card title.
  ///
  /// In en, this message translates to:
  /// **'Food Category'**
  String get obFoodCategory;

  /// Pill: more than one category may be picked.
  ///
  /// In en, this message translates to:
  /// **'Multi-select'**
  String get obMultiSelect;

  /// Shown when the categories request fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the categories.'**
  String get obCategoriesLoadFailed;

  /// Card title.
  ///
  /// In en, this message translates to:
  /// **'Stall Location'**
  String get obStallLocation;

  /// Shown while the GPS fix is taken.
  ///
  /// In en, this message translates to:
  /// **'Finding you...'**
  String get obFindingYou;

  /// Button when a location is already pinned.
  ///
  /// In en, this message translates to:
  /// **'Update GPS Location 📍'**
  String get obUpdateGps;

  /// Button to pin the current location.
  ///
  /// In en, this message translates to:
  /// **'Use Current GPS Location 📍'**
  String get obUseGps;

  /// Link to the system settings when location is blocked.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get obOpenSettings;

  /// Indicator once a GPS fix is pinned.
  ///
  /// In en, this message translates to:
  /// **'GPS Accurate'**
  String get obGpsAccurate;

  /// Caption on the pinned location card. TODO(si-review): 'Landmark' = a recognisable nearby place the vendor names.
  ///
  /// In en, this message translates to:
  /// **'PINNED LANDMARK'**
  String get obPinnedLandmark;

  /// Name of the pinned spot when the vendor has not named it.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get obCurrentLocation;

  /// Dialog title.
  ///
  /// In en, this message translates to:
  /// **'Name this spot'**
  String get obNameSpotTitle;

  /// Dialog field hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Opposite the bus stand'**
  String get obNameSpotHint;

  /// Title of the time picker for the opening time.
  ///
  /// In en, this message translates to:
  /// **'Opening time'**
  String get obOpeningTime;

  /// Title of the time picker for the closing time.
  ///
  /// In en, this message translates to:
  /// **'Closing time'**
  String get obClosingTime;

  /// Label of the opening-time field.
  ///
  /// In en, this message translates to:
  /// **'Opens'**
  String get obOpens;

  /// Label of the closing-time field.
  ///
  /// In en, this message translates to:
  /// **'Closes'**
  String get obCloses;

  /// Placeholder of a time field with no time.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get obSelectTime;

  /// Screen-reader label of an empty time field.
  ///
  /// In en, this message translates to:
  /// **'{label}, not set'**
  String obTimeNotSet(String label);

  /// Screen-reader label of a time field with a time.
  ///
  /// In en, this message translates to:
  /// **'{label}, {time}'**
  String obTimeValue(String label, String time);

  /// Switch label.
  ///
  /// In en, this message translates to:
  /// **'Open 7 Days a Week'**
  String get obOpenEveryDay;

  /// One-letter weekday chip: Monday.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get obDayMon;

  /// One-letter weekday chip: Tuesday.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get obDayTue;

  /// One-letter weekday chip: Wednesday.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get obDayWed;

  /// One-letter weekday chip: Thursday.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get obDayThu;

  /// One-letter weekday chip: Friday.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get obDayFri;

  /// One-letter weekday chip: Saturday.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get obDaySat;

  /// One-letter weekday chip: Sunday. TODO(si-review): Single-letter weekday abbreviations (ස අ බ බ්‍ර සි සෙ ඉ); confirm the convention you prefer.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get obDaySun;

  /// Card title.
  ///
  /// In en, this message translates to:
  /// **'Stall & Food Photo'**
  String get obPhotoTitle;

  /// Photo drop zone heading.
  ///
  /// In en, this message translates to:
  /// **'Tap to take photo of your stall'**
  String get obPhotoTap;

  /// Photo drop zone help text.
  ///
  /// In en, this message translates to:
  /// **'A clear photo of your stall and your food helps customers trust you.'**
  String get obPhotoHelp;

  /// Pill on the photo drop zone.
  ///
  /// In en, this message translates to:
  /// **'Open Camera or Gallery'**
  String get obPhotoAction;

  /// Button over the chosen photo.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get obChangePhoto;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Short Description'**
  String get obDescription;

  /// Field hint. TODO(si-review): 'Mouth-watering' is idiomatic; confirm the phrasing.
  ///
  /// In en, this message translates to:
  /// **'Keep it short & mouth-watering'**
  String get obDescriptionHint;

  /// Notice above the submit button.
  ///
  /// In en, this message translates to:
  /// **'By listing, you agree to maintain fresh ingredients and hygienic food prep standards.'**
  String get obAgreement;

  /// Submit button.
  ///
  /// In en, this message translates to:
  /// **'List My Stall & Go Live 🚀'**
  String get obSubmit;

  /// Caption under the submit button.
  ///
  /// In en, this message translates to:
  /// **'Zero commission on your first 50 orders • Edit anytime'**
  String get obZeroCommission;

  /// Validation message.
  ///
  /// In en, this message translates to:
  /// **'Give your stall a name.'**
  String get obErrNameRequired;

  /// Validation message.
  ///
  /// In en, this message translates to:
  /// **'Keep the name under {max} characters.'**
  String obErrNameLong(int max);

  /// Validation message.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one food category.'**
  String get obErrCategories;

  /// Validation message.
  ///
  /// In en, this message translates to:
  /// **'Pin your stall\'s location so customers can find you.'**
  String get obErrLocation;

  /// Validation message.
  ///
  /// In en, this message translates to:
  /// **'Choose when you open.'**
  String get obErrOpens;

  /// Validation message.
  ///
  /// In en, this message translates to:
  /// **'Choose when you close.'**
  String get obErrCloses;

  /// Validation message.
  ///
  /// In en, this message translates to:
  /// **'Closing time must be different from opening time.'**
  String get obErrCloseDiffer;

  /// Validation message.
  ///
  /// In en, this message translates to:
  /// **'Pick the days you are open.'**
  String get obErrDays;

  /// Validation message.
  ///
  /// In en, this message translates to:
  /// **'Add a photo of your stall.'**
  String get obErrPhoto;

  /// Validation message.
  ///
  /// In en, this message translates to:
  /// **'Keep the description to {max} characters.'**
  String obErrDescLong(int max);

  /// Title of the settings screen and of the menu row that opens it (customer and vendor).
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get settingsTitle;

  /// Subtitle of the App Settings menu row.
  ///
  /// In en, this message translates to:
  /// **'Language, notifications and privacy'**
  String get settingsRowSub;

  /// Heading of the language section.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Help text under the language heading.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used across the app. The change applies straight away and is remembered.'**
  String get settingsLanguageHelp;

  /// Heading of the section with the not-yet-built settings.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// Row (not built yet).
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get settingsNotifications;

  /// Row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which alerts you receive'**
  String get settingsNotificationsSub;

  /// Feature name in the coming-soon snackbar.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get settingsFeatureNotifications;

  /// Row (not built yet).
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get settingsPrivacy;

  /// Row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Control who can see your activity'**
  String get settingsPrivacySub;

  /// Feature name in the coming-soon snackbar.
  ///
  /// In en, this message translates to:
  /// **'Privacy settings'**
  String get settingsFeaturePrivacy;

  /// Screen-reader label of the chosen language option.
  ///
  /// In en, this message translates to:
  /// **'{language}, selected'**
  String settingsLanguageSelected(String language);

  /// Dismisses a dialog without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Saves what was entered in a dialog.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Destructive confirm button.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Tooltip of the bell button.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get commonNotifications;

  /// Small caption under a feature that is not built yet.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get commonComingSoonTag;

  /// Section title of the vendor home shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Quick Vendor Controls'**
  String get vhQuickControls;

  /// Section title on the vendor home.
  ///
  /// In en, this message translates to:
  /// **'Recent Customer Reviews'**
  String get vhRecentReviews;

  /// Subtitle of the recent reviews section.
  ///
  /// In en, this message translates to:
  /// **'Latest from your customers'**
  String get vhRecentReviewsSub;

  /// Link to all reviews.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get vhSeeAll;

  /// Link to all reviews, with how many there are.
  ///
  /// In en, this message translates to:
  /// **'See All ({count})'**
  String vhSeeAllCount(int count);

  /// Empty state of the recent reviews list.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet. They appear here as customers leave them.'**
  String get vhNoReviews;

  /// Screen-reader label of the open/closed pill when open.
  ///
  /// In en, this message translates to:
  /// **'Open now, tap to close'**
  String get vhOpenNowTap;

  /// Screen-reader label of the open/closed pill when closed.
  ///
  /// In en, this message translates to:
  /// **'Closed, tap to open'**
  String get vhClosedTap;

  /// Open/closed pill, open state.
  ///
  /// In en, this message translates to:
  /// **'OPEN NOW 🟢'**
  String get vhPillOpen;

  /// Open/closed pill, closed state.
  ///
  /// In en, this message translates to:
  /// **'CLOSED'**
  String get vhPillClosed;

  /// Caption above the hygiene score number.
  ///
  /// In en, this message translates to:
  /// **'HYGIENE SCORE'**
  String get vhHygieneScore;

  /// Title of the live status card on the vendor home. TODO(si-review): 'Fresh prep' (food freshly prepared today) has no short Sinhala equivalent; confirm wording.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Fresh Prep Status'**
  String get vhStatusCardTitle;

  /// Pill shown when the vendor has no live status.
  ///
  /// In en, this message translates to:
  /// **'None live'**
  String get vhNoneLive;

  /// Body of the status card when none is live. TODO(si-review): 'on the radar' follows the consumer 'Radar' term; confirm.
  ///
  /// In en, this message translates to:
  /// **'You have no status on the radar. Post one so customers can see what is fresh right now.'**
  String get vhNoStatusBody;

  /// Label after the like count on the status card.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get vhStatLikes;

  /// Label after the comment count on the status card.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get vhStatComments;

  /// Quick control title.
  ///
  /// In en, this message translates to:
  /// **'Post Daily Status'**
  String get vhPostStatus;

  /// Quick control description.
  ///
  /// In en, this message translates to:
  /// **'Share today\'s fresh batch with nearby customers.'**
  String get vhPostStatusDesc;

  /// Quick control title.
  ///
  /// In en, this message translates to:
  /// **'Update Menu'**
  String get vhUpdateMenu;

  /// Quick control description.
  ///
  /// In en, this message translates to:
  /// **'Change prices and mark items fresh or sold out.'**
  String get vhUpdateMenuDesc;

  /// Quick control title.
  ///
  /// In en, this message translates to:
  /// **'Update Hours'**
  String get vhUpdateHours;

  /// Quick control description.
  ///
  /// In en, this message translates to:
  /// **'Adjust your opening and closing times.'**
  String get vhUpdateHoursDesc;

  /// Quick control title.
  ///
  /// In en, this message translates to:
  /// **'View Stall Profile'**
  String get vhViewProfile;

  /// Quick control description.
  ///
  /// In en, this message translates to:
  /// **'See your stall as customers see it.'**
  String get vhViewProfileDesc;

  /// Caption on a quick control card: it works with one tap. TODO(si-review): Short caption; confirm it reads naturally.
  ///
  /// In en, this message translates to:
  /// **'SINGLE-TAP'**
  String get vhSingleTap;

  /// Heading of the open/closed card, open.
  ///
  /// In en, this message translates to:
  /// **'Stall Status: OPEN'**
  String get vacctStatusOpen;

  /// Heading of the open/closed card, closed.
  ///
  /// In en, this message translates to:
  /// **'Stall Status: CLOSED'**
  String get vacctStatusClosed;

  /// Line under the open/closed switch.
  ///
  /// In en, this message translates to:
  /// **'Open • Serving Customers'**
  String get vacctOpenServing;

  /// Line under the open/closed switch, with the closing time.
  ///
  /// In en, this message translates to:
  /// **'Open until {time} • Serving Customers'**
  String vacctOpenUntil(String time);

  /// Line under the open/closed switch when closed.
  ///
  /// In en, this message translates to:
  /// **'Closed • Not shown in \"open now\" searches'**
  String get vacctClosedNote;

  /// Note beside the Change Hours link.
  ///
  /// In en, this message translates to:
  /// **'The stall closes itself after its closing time.'**
  String get vacctAutoCloses;

  /// Link to the hours editor.
  ///
  /// In en, this message translates to:
  /// **'Change Hours'**
  String get vacctChangeHours;

  /// Section title of the profile menu.
  ///
  /// In en, this message translates to:
  /// **'Vendor Configuration'**
  String get vacctConfig;

  /// Menu row (not built yet).
  ///
  /// In en, this message translates to:
  /// **'Edit Stall Details'**
  String get vacctEditStall;

  /// Menu row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, category, location pin & cover photo'**
  String get vacctEditStallSub;

  /// Feature name in the coming-soon snackbar.
  ///
  /// In en, this message translates to:
  /// **'Editing your stall details'**
  String get vacctFeatureEditStall;

  /// Menu row title.
  ///
  /// In en, this message translates to:
  /// **'Hygiene & Inspection Certificate'**
  String get vacctCertificate;

  /// Menu row subtitle.
  ///
  /// In en, this message translates to:
  /// **'View your hygiene score and the latest inspection checklist'**
  String get vacctCertificateSub;

  /// Menu row title (not built yet). TODO(si-review): 'Hotline' - confirm the term used locally (e.g. ක්ෂණික ඇමතුම් අංකය).
  ///
  /// In en, this message translates to:
  /// **'Vendor Help & Inspector Hotline'**
  String get vacctHelp;

  /// Menu row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get vacctHelpSub;

  /// Feature name in the coming-soon snackbar.
  ///
  /// In en, this message translates to:
  /// **'The inspector hotline'**
  String get vacctFeatureHotline;

  /// Log-out button.
  ///
  /// In en, this message translates to:
  /// **'Log Out of Vendor Account'**
  String get vacctLogOut;

  /// Footer, the stall's code.
  ///
  /// In en, this message translates to:
  /// **'Stall ID: {code}'**
  String vacctStallId(String code);

  /// Footer, the app version.
  ///
  /// In en, this message translates to:
  /// **'App Version {version}'**
  String vacctAppVersion(String version);

  /// Small button on the cover photo to change it. TODO(si-review): 'Cover' as in cover photo; short label.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get vacctCover;

  /// Feature name in the coming-soon snackbar.
  ///
  /// In en, this message translates to:
  /// **'Changing your cover photo'**
  String get vacctFeatureCover;

  /// Tooltip of the pencil on the avatar.
  ///
  /// In en, this message translates to:
  /// **'Edit stall photo'**
  String get vacctEditPhoto;

  /// Feature name in the coming-soon snackbar.
  ///
  /// In en, this message translates to:
  /// **'Changing your stall photo'**
  String get vacctFeatureStallPhoto;

  /// Hygiene pill on the vendor profile.
  ///
  /// In en, this message translates to:
  /// **'Verified Clean Vendor'**
  String get vacctVerifiedCleanVendor;

  /// Banner title when open.
  ///
  /// In en, this message translates to:
  /// **'Stall is Open 🟢'**
  String get vtOpenTitle;

  /// Banner title when closed.
  ///
  /// In en, this message translates to:
  /// **'Stall is Closed'**
  String get vtClosedTitle;

  /// Banner body when open.
  ///
  /// In en, this message translates to:
  /// **'Customers can see you as open on the map.'**
  String get vtOpenBody;

  /// Banner body when closed.
  ///
  /// In en, this message translates to:
  /// **'Hidden from \"open now\" searches.'**
  String get vtClosedBody;

  /// Button that closes the stall.
  ///
  /// In en, this message translates to:
  /// **'Close for Today'**
  String get vtCloseToday;

  /// Button that reopens the stall.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get vtReopen;

  /// Small caption above the dashboard title.
  ///
  /// In en, this message translates to:
  /// **'MERCHANT CONTROL'**
  String get vdMerchantControl;

  /// Title of the vendor dashboard.
  ///
  /// In en, this message translates to:
  /// **'Stall Dashboard'**
  String get vdTitle;

  /// Hygiene pill on the dashboard.
  ///
  /// In en, this message translates to:
  /// **'Clean & Verified'**
  String get vdCleanVerified;

  /// Dialog title when deleting a menu item.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String vdDeleteItemTitle(String name);

  /// Dialog body when deleting a menu item.
  ///
  /// In en, this message translates to:
  /// **'It disappears from your menu. You can add it again later.'**
  String get vdDeleteItemBody;

  /// Dialog button that keeps the menu item.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get vdKeep;

  /// Snackbar after saving the hours.
  ///
  /// In en, this message translates to:
  /// **'Hours saved.'**
  String get vdHoursSaved;

  /// Snackbar after Close Early.
  ///
  /// In en, this message translates to:
  /// **'Closed for now. Tap Reopen to open again.'**
  String get vdClosedToast;

  /// Caption of the opening-time stepper.
  ///
  /// In en, this message translates to:
  /// **'Open Time'**
  String get vdOpenTime;

  /// Caption of the closing-time stepper.
  ///
  /// In en, this message translates to:
  /// **'Close Time'**
  String get vdCloseTime;

  /// Preset: closing time later by one hour.
  ///
  /// In en, this message translates to:
  /// **'Extend 1 Hour'**
  String get vdExtendHour;

  /// Preset: close the stall now.
  ///
  /// In en, this message translates to:
  /// **'Close Early'**
  String get vdCloseEarly;

  /// Disabled save button when nothing changed.
  ///
  /// In en, this message translates to:
  /// **'Hours saved'**
  String get vdHoursSavedBtn;

  /// Save button of the hours editor.
  ///
  /// In en, this message translates to:
  /// **'Save Hours'**
  String get vdSaveHours;

  /// Tooltip of the minus button.
  ///
  /// In en, this message translates to:
  /// **'Earlier by {minutes} minutes'**
  String vdEarlier(int minutes);

  /// Tooltip of the plus button.
  ///
  /// In en, this message translates to:
  /// **'Later by {minutes} minutes'**
  String vdLater(int minutes);

  /// Section title of the menu list, before it loads.
  ///
  /// In en, this message translates to:
  /// **'Daily Menu'**
  String get vdDailyMenu;

  /// Section title of the menu list, with the count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Daily Menu (1 Item)} other{Daily Menu ({count} Items)}}'**
  String vdDailyMenuCount(int count);

  /// Button and dialog title for a new menu item.
  ///
  /// In en, this message translates to:
  /// **'Add New Item'**
  String get vdAddItem;

  /// Empty state of the menu list.
  ///
  /// In en, this message translates to:
  /// **'Your menu is empty. Add the dishes you are selling today.'**
  String get vdMenuEmpty;

  /// Tooltip of the pencil on a menu item.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String vdEditItemTooltip(String name);

  /// Tooltip of the bin on a menu item.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String vdDeleteItemTooltip(String name);

  /// Label of the fresh-today switch. TODO(si-review): 'Preparedness' = whether the dish is freshly prepared today; confirm.
  ///
  /// In en, this message translates to:
  /// **'Daily Preparedness'**
  String get vdPreparedness;

  /// Fresh-today switch, on.
  ///
  /// In en, this message translates to:
  /// **'Fresh Today ON'**
  String get vdFreshOn;

  /// Fresh-today switch, off.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get vdFreshOff;

  /// Fresh-today switch, disabled because the dish is sold out.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get vdUnavailable;

  /// Row title (not built yet).
  ///
  /// In en, this message translates to:
  /// **'Stall Profile & Location'**
  String get vdProfileLink;

  /// Row body (not built yet).
  ///
  /// In en, this message translates to:
  /// **'Editing your name, categories, location and cover photo is not available in the app yet.'**
  String get vdProfileLinkBody;

  /// Feature name in the coming-soon snackbar.
  ///
  /// In en, this message translates to:
  /// **'Editing your stall profile'**
  String get vdFeatureEditProfile;

  /// Dialog title when editing a menu item.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get vdEditItemTitle;

  /// Field label in the menu item dialog.
  ///
  /// In en, this message translates to:
  /// **'Dish name'**
  String get vdDishName;

  /// Field label in the menu item dialog.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get vdPrice;

  /// Validation message.
  ///
  /// In en, this message translates to:
  /// **'Give the dish a name.'**
  String get vdErrName;

  /// Validation message.
  ///
  /// In en, this message translates to:
  /// **'Enter a price greater than zero, like 4.50.'**
  String get vdErrPrice;

  /// Section title on the analytics screen.
  ///
  /// In en, this message translates to:
  /// **'Recent Stall Feedback'**
  String get vanFeedback;

  /// Pill beside the feedback title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Review} other{{count} Reviews}}'**
  String vanReviewCount(int count);

  /// Empty state of the feedback list.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get vanNoReviews;

  /// Button (not built yet).
  ///
  /// In en, this message translates to:
  /// **'Share My Hygiene Badge'**
  String get vanShareBadge;

  /// Feature name in the coming-soon snackbar.
  ///
  /// In en, this message translates to:
  /// **'Sharing your hygiene badge'**
  String get vanFeatureShareBadge;

  /// Title of the analytics screen.
  ///
  /// In en, this message translates to:
  /// **'Vendor Analytics'**
  String get vanTitle;

  /// Pill beside the title when the stall is open.
  ///
  /// In en, this message translates to:
  /// **'Live Stall'**
  String get vanLiveStall;

  /// Pill beside the title when the stall is closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get vanClosed;

  /// Caption above the big score.
  ///
  /// In en, this message translates to:
  /// **'Current Hygiene Score'**
  String get vanCurrentScore;

  /// Metric card title.
  ///
  /// In en, this message translates to:
  /// **'Customer Rating'**
  String get vanCustomerRating;

  /// Metric card note.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get vanNoReviewsSub;

  /// Metric card note.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String vanReviewCountLower(int count);

  /// Metric card title.
  ///
  /// In en, this message translates to:
  /// **'Status Likes'**
  String get vanStatusLikes;

  /// Metric card note.
  ///
  /// In en, this message translates to:
  /// **'No live status'**
  String get vanNoLiveStatus;

  /// Metric card note.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{On 1 live status} other{On {count} live statuses}}'**
  String vanOnStatuses(int count);

  /// Metric card title.
  ///
  /// In en, this message translates to:
  /// **'Status Comments'**
  String get vanStatusComments;

  /// Metric card note.
  ///
  /// In en, this message translates to:
  /// **'On live statuses'**
  String get vanOnLive;

  /// Metric card title.
  ///
  /// In en, this message translates to:
  /// **'Status Views'**
  String get vanStatusViews;

  /// Metric card note: the server does not count views.
  ///
  /// In en, this message translates to:
  /// **'Not tracked yet'**
  String get vanNotTracked;

  /// Chart card title.
  ///
  /// In en, this message translates to:
  /// **'Hygiene Score Trend'**
  String get vanTrendTitle;

  /// Pill on the chart card.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Last 1 inspection} other{Last {count} inspections}}'**
  String vanLastInspections(int count);

  /// Empty state of the chart card.
  ///
  /// In en, this message translates to:
  /// **'No inspections yet. Your scores appear here after an inspector visits.'**
  String get vanNoInspections;

  /// Chart summary for a single inspection.
  ///
  /// In en, this message translates to:
  /// **'Scored {score} out of 5'**
  String vanScoredOne(String score);

  /// Chart summary for several inspections.
  ///
  /// In en, this message translates to:
  /// **'From {from} to {to} out of 5'**
  String vanScoredRange(String from, String to);

  /// Chart axis label: day and short month name.
  ///
  /// In en, this message translates to:
  /// **'{day} {month}'**
  String vanChartDate(int day, String month);

  /// Name shown when a comment's author is unknown.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get commonSomeone;

  /// Title of the customer notifications screen.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get alertsTitle;

  /// Subtitle when nothing is unread.
  ///
  /// In en, this message translates to:
  /// **'Street kitchen & stall updates'**
  String get alertsSubtitle;

  /// Subtitle with the number of unread notifications.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String alertsUnreadCount(int count);

  /// Button that marks every notification as read.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get alertsMarkAllRead;

  /// Empty state heading.
  ///
  /// In en, this message translates to:
  /// **'You\'re All Caught Up!'**
  String get alertsCaughtUp;

  /// Empty state text.
  ///
  /// In en, this message translates to:
  /// **'Follow stalls you love and their fresh posts will show up here.'**
  String get alertsCaughtUpBody;

  /// Empty state button.
  ///
  /// In en, this message translates to:
  /// **'Discover Nearby Stalls'**
  String get alertsDiscover;

  /// Notification filter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get alertsFilterAll;

  /// Notification filter.
  ///
  /// In en, this message translates to:
  /// **'Stalls You Follow'**
  String get alertsFilterStalls;

  /// Notification filter.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get alertsFilterCommunity;

  /// Notification category.
  ///
  /// In en, this message translates to:
  /// **'Stall Update'**
  String get alertTypeStallUpdate;

  /// Notification category.
  ///
  /// In en, this message translates to:
  /// **'New Comment'**
  String get alertTypeComment;

  /// Notification category.
  ///
  /// In en, this message translates to:
  /// **'New Like'**
  String get alertTypeLike;

  /// Notification category.
  ///
  /// In en, this message translates to:
  /// **'Friend Request'**
  String get alertTypeFriendRequest;

  /// Notification category.
  ///
  /// In en, this message translates to:
  /// **'New Friend'**
  String get alertTypeNewFriend;

  /// Notification category.
  ///
  /// In en, this message translates to:
  /// **'Hygiene Update'**
  String get alertTypeHygieneUpdate;

  /// Notification category.
  ///
  /// In en, this message translates to:
  /// **'Re-check Due'**
  String get alertTypeRecheck;

  /// Notification category.
  ///
  /// In en, this message translates to:
  /// **'New Review'**
  String get alertTypeNewReview;

  /// Notification category for a kind this app does not know.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get alertTypeOther;

  /// The previous hygiene score.
  ///
  /// In en, this message translates to:
  /// **'was {score}'**
  String alertScoreWas(String score);

  /// Title of the vendor notifications screen.
  ///
  /// In en, this message translates to:
  /// **'Stall Notifications'**
  String get vaTitle;

  /// Subtitle when nothing is unread.
  ///
  /// In en, this message translates to:
  /// **'Reviews, hygiene scores & customer buzz'**
  String get vaSubtitle;

  /// Badge in the vendor notifications header.
  ///
  /// In en, this message translates to:
  /// **'Vendor View'**
  String get vaVendorView;

  /// Vendor notification filter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get vaFilterAll;

  /// Vendor notification filter.
  ///
  /// In en, this message translates to:
  /// **'Customer Reviews'**
  String get vaFilterReviews;

  /// Vendor notification filter.
  ///
  /// In en, this message translates to:
  /// **'Hygiene Alerts'**
  String get vaFilterHygiene;

  /// Vendor notification filter: likes and comments.
  ///
  /// In en, this message translates to:
  /// **'Status Buzz'**
  String get vaFilterBuzz;

  /// Empty list.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get vaNone;

  /// Empty list under a filter.
  ///
  /// In en, this message translates to:
  /// **'Nothing here for this filter.'**
  String get vaNothingForFilter;

  /// Button on a review notification.
  ///
  /// In en, this message translates to:
  /// **'See Reviews'**
  String get vaSeeReviews;

  /// Disabled button: review replies are not supported by the server.
  ///
  /// In en, this message translates to:
  /// **'Reply to Review (not available yet)'**
  String get vaReplyUnavailable;

  /// Button on a hygiene notification.
  ///
  /// In en, this message translates to:
  /// **'View Hygiene Report'**
  String get vaViewHygiene;

  /// Button on a comment notification.
  ///
  /// In en, this message translates to:
  /// **'View & Reply'**
  String get vaViewReply;

  /// Button on a like notification.
  ///
  /// In en, this message translates to:
  /// **'View Status'**
  String get vaViewStatus;

  /// Section title on the profile.
  ///
  /// In en, this message translates to:
  /// **'Your Live Statuses'**
  String get profLiveStatuses;

  /// Tile that opens the create-status screen.
  ///
  /// In en, this message translates to:
  /// **'Create New Status'**
  String get profCreateStatus;

  /// Section title on the profile.
  ///
  /// In en, this message translates to:
  /// **'Settings & Network'**
  String get profSettingsNetwork;

  /// Profile menu item. TODO(si-review): 'Foodie Network' (ආහාර ප්‍රිය ජාලය); confirm.
  ///
  /// In en, this message translates to:
  /// **'My Friends & Foodie Network'**
  String get profFriendsNetwork;

  /// Badge with the number of friends.
  ///
  /// In en, this message translates to:
  /// **'{count} Connected'**
  String profConnected(int count);

  /// Subtitle of the friends menu item.
  ///
  /// In en, this message translates to:
  /// **'Add and manage your foodie friends'**
  String get profFriendsSub;

  /// Profile menu item. TODO(si-review): 'Vault' (සුරැකුම) means the kept archive; confirm.
  ///
  /// In en, this message translates to:
  /// **'My Status History & Vault'**
  String get profHistory;

  /// Subtitle of the history menu item.
  ///
  /// In en, this message translates to:
  /// **'Your past statuses, live or expired'**
  String get profHistorySub;

  /// Profile menu item (not built yet).
  ///
  /// In en, this message translates to:
  /// **'Help & Food Safety Support'**
  String get profHelp;

  /// Subtitle of an item that is not built yet.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get profHelpSub;

  /// Name of the not-yet-built feature.
  ///
  /// In en, this message translates to:
  /// **'Help and food safety support'**
  String get profFeatureHelp;

  /// Signs the customer out.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get profLogOut;

  /// Tooltip of the edit-photo button.
  ///
  /// In en, this message translates to:
  /// **'Edit photo (not available yet)'**
  String get profEditPhoto;

  /// Name of the not-yet-built feature.
  ///
  /// In en, this message translates to:
  /// **'Changing your photo'**
  String get profFeaturePhoto;

  /// Profile count caption.
  ///
  /// In en, this message translates to:
  /// **'Statuses Shared'**
  String get profStatStatuses;

  /// Profile count caption.
  ///
  /// In en, this message translates to:
  /// **'Foodie Friends'**
  String get profStatFriends;

  /// Profile count caption: statuses live right now.
  ///
  /// In en, this message translates to:
  /// **'Live Now'**
  String get profStatLive;

  /// Title of the status history screen. TODO(si-review): 'Vault' (සුරැකුම) means the kept archive; confirm.
  ///
  /// In en, this message translates to:
  /// **'Status History & Vault'**
  String get shTitle;

  /// Empty state.
  ///
  /// In en, this message translates to:
  /// **'You have not posted a status yet. Share what you are eating from your profile.'**
  String get shEmpty;

  /// A status that is on the radar.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get shLive;

  /// A status that has expired.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get shArchived;

  /// A status a moderator hid.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get shHidden;

  /// Title of the friends screen. TODO(si-review): 'Foodie' (ආහාර ප්‍රිය) is a coined term; confirm.
  ///
  /// In en, this message translates to:
  /// **'Foodie Network'**
  String get frTitle;

  /// Tab.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get frTabAdd;

  /// Tab.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get frTabRequests;

  /// Tab.
  ///
  /// In en, this message translates to:
  /// **'My Friends'**
  String get frTabFriends;

  /// Heading of the add-friend tab.
  ///
  /// In en, this message translates to:
  /// **'Find a foodie'**
  String get frFindTitle;

  /// Explains that only exact usernames work.
  ///
  /// In en, this message translates to:
  /// **'Type their exact username. There is no search by name or phone.'**
  String get frFindSub;

  /// Placeholder of the username field.
  ///
  /// In en, this message translates to:
  /// **'@username'**
  String get frUsernameHint;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get frFind;

  /// No user found.
  ///
  /// In en, this message translates to:
  /// **'No customer with the username @{username}. Usernames must match exactly.'**
  String frNoUser(String username);

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Request sent to {name}.'**
  String frRequestSent(String name);

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'You are now friends with {name}.'**
  String frNowFriends(String name);

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Request declined.'**
  String get frDeclined;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'{name} was removed from your friends.'**
  String frRemoved(String name);

  /// Button that sends a friend request.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get frAdd;

  /// Empty requests list.
  ///
  /// In en, this message translates to:
  /// **'No friend requests waiting for you.'**
  String get frNoRequests;

  /// Heading of the friends list.
  ///
  /// In en, this message translates to:
  /// **'Active Friends'**
  String get frActiveFriends;

  /// Empty friends list.
  ///
  /// In en, this message translates to:
  /// **'No friends yet. Find someone by username in the Add tab.'**
  String get frNoFriends;

  /// Accepts a friend request.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get frAccept;

  /// Declines a friend request.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get frDecline;

  /// How long ago the friendship began.
  ///
  /// In en, this message translates to:
  /// **'Friends · {ago}'**
  String frFriendsSince(String ago);

  /// Menu item.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get frRemoveFriend;

  /// Tooltip of the three-dot menu.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get frMoreOptions;

  /// Heading of the tip card. TODO(si-review): 'Foodie' (ආහාර ප්‍රිය) is a coined term; confirm.
  ///
  /// In en, this message translates to:
  /// **'Foodie Network Tip'**
  String get frTipTitle;

  /// Text of the tip card.
  ///
  /// In en, this message translates to:
  /// **'Friends see your Friends Only statuses, and you see theirs in your Daily Fresh Stories.'**
  String get frTipBody;

  /// Title of the create-status screen.
  ///
  /// In en, this message translates to:
  /// **'New Status'**
  String get csTitle;

  /// Dialog title.
  ///
  /// In en, this message translates to:
  /// **'Discard this status?'**
  String get csDiscardTitle;

  /// Dialog text.
  ///
  /// In en, this message translates to:
  /// **'Your photo and caption will be lost.'**
  String get csDiscardBody;

  /// Dialog button.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get csKeepEditing;

  /// Dialog button.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get csDiscard;

  /// Snackbar after posting. TODO(si-review): Register: this string is spoken-style (-ළා); most others are written-style (-න ලදී). Confirm which register you want app-wide.
  ///
  /// In en, this message translates to:
  /// **'Status posted! It stays on the radar for 24 hours.'**
  String get csPosted;

  /// Photo placeholder.
  ///
  /// In en, this message translates to:
  /// **'Tap to add today\'s fresh photo'**
  String get csTapPhoto;

  /// Photo placeholder hint.
  ///
  /// In en, this message translates to:
  /// **'Camera or gallery'**
  String get csCameraOrGallery;

  /// Tooltip of the gallery button.
  ///
  /// In en, this message translates to:
  /// **'Choose a different image'**
  String get csChooseDifferent;

  /// Heading of the caption card. TODO(si-review): 'Taste Review & Street Note' is a creative title; confirm.
  ///
  /// In en, this message translates to:
  /// **'Your Taste Review & Street Note'**
  String get csCaptionTitle;

  /// Placeholder of the caption field.
  ///
  /// In en, this message translates to:
  /// **'What is fresh and hot right now? Tell people what to try...'**
  String get csCaptionHint;

  /// Accessibility label of an emoji button.
  ///
  /// In en, this message translates to:
  /// **'Insert {emoji}'**
  String csInsertEmoji(String emoji);

  /// Small label of the stall row.
  ///
  /// In en, this message translates to:
  /// **'FOOD STALL'**
  String get csFoodStall;

  /// Helper text for a vendor.
  ///
  /// In en, this message translates to:
  /// **'Posting as {name}'**
  String csPostingAs(Object name);

  /// Link that picks a stall to tag.
  ///
  /// In en, this message translates to:
  /// **'Tag a stall'**
  String get csTagStall;

  /// Link that changes the tagged stall.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get csChange;

  /// No stall chosen.
  ///
  /// In en, this message translates to:
  /// **'No stall tagged'**
  String get csNoStallTagged;

  /// Helper text.
  ///
  /// In en, this message translates to:
  /// **'Optional: tag the stall in your photo'**
  String get csTagOptional;

  /// Shown in the tag-a-stall sheet when the list is empty.
  ///
  /// In en, this message translates to:
  /// **'No nearby stalls to tag yet.'**
  String get csNoNearbyStalls;

  /// Small label of the place row.
  ///
  /// In en, this message translates to:
  /// **'WHERE (OPTIONAL)'**
  String get csWhere;

  /// Placeholder of the place field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Near the main gate'**
  String get csWhereHint;

  /// Helper text of the place row.
  ///
  /// In en, this message translates to:
  /// **'Shown with your status as plain text'**
  String get csWhereHelper;

  /// Heading of the audience card.
  ///
  /// In en, this message translates to:
  /// **'Audience Visibility'**
  String get csAudience;

  /// Hint beside the audience heading.
  ///
  /// In en, this message translates to:
  /// **'Who sees this?'**
  String get csWhoSees;

  /// Audience option.
  ///
  /// In en, this message translates to:
  /// **'Public ({brand})'**
  String csPublic(String brand);

  /// Audience option and badge.
  ///
  /// In en, this message translates to:
  /// **'Friends Only'**
  String get csFriendsOnly;

  /// Note shown to vendors, whose statuses cannot be Friends Only.
  ///
  /// In en, this message translates to:
  /// **'Stall statuses are always public.'**
  String get csAlwaysPublic;

  /// Post button.
  ///
  /// In en, this message translates to:
  /// **'Post Status 🚀'**
  String get csPost;

  /// Hint under the disabled post button.
  ///
  /// In en, this message translates to:
  /// **'Add a photo or a caption to post.'**
  String get csNeedContent;

  /// Note at the bottom.
  ///
  /// In en, this message translates to:
  /// **'Your status is visible for 24 hours on the Fresh Stories radar, then it expires and moves to your history.'**
  String get csExpiryNotice;

  /// Audience shown on a status.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get sdPublic;

  /// Like button label.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Like} other{{count} Likes}}'**
  String sdLikes(int count);

  /// Accessibility label of the like button.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get sdLikeLabel;

  /// Button for the author.
  ///
  /// In en, this message translates to:
  /// **'Delete Status'**
  String get sdDeleteStatus;

  /// Button for a status about a stall.
  ///
  /// In en, this message translates to:
  /// **'View Stall'**
  String get sdViewStall;

  /// Dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete this status?'**
  String get sdDeleteTitle;

  /// Dialog text.
  ///
  /// In en, this message translates to:
  /// **'It disappears from the radar, along with its likes and comments.'**
  String get sdDeleteBody;

  /// Dialog button.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get sdKeep;

  /// Dialog button.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get sdDelete;

  /// Heading of the comment list.
  ///
  /// In en, this message translates to:
  /// **'Comments ({count})'**
  String sdComments(int count);

  /// Empty comment list.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first to say something.'**
  String get sdNoComments;

  /// Placeholder of the comment field for the author.
  ///
  /// In en, this message translates to:
  /// **'Reply to your comments...'**
  String get sdReplyHint;

  /// Placeholder of the comment field.
  ///
  /// In en, this message translates to:
  /// **'Add a comment for {name}...'**
  String sdCommentHint(String name);

  /// Quick reaction that posts a comment. TODO(si-review): 'Sizzling' reaction chip; slangy, needs a natural Sinhala equivalent.
  ///
  /// In en, this message translates to:
  /// **'🔥 Sizzling'**
  String get sdReact1;

  /// Quick reaction that posts a comment. TODO(si-review): 'Craving' reaction chip; slangy.
  ///
  /// In en, this message translates to:
  /// **'🤤 Craving'**
  String get sdReact2;

  /// Quick reaction that posts a comment. TODO(si-review): 'Master Chef' reaction chip; a playful compliment.
  ///
  /// In en, this message translates to:
  /// **'👏 Master Chef'**
  String get sdReact3;

  /// Small button that opens a stall.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get commonView;

  /// Name shown for a reviewer who posted anonymously.
  ///
  /// In en, this message translates to:
  /// **'Anonymous customer'**
  String get reviewAnonymous;

  /// Weekday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMonday;

  /// Weekday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTuesday;

  /// Weekday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWednesday;

  /// Weekday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThursday;

  /// Weekday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFriday;

  /// Weekday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySaturday;

  /// Weekday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySunday;

  /// Weekday, short, on a chip.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayShortMon;

  /// Weekday, short, on a chip.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayShortTue;

  /// Weekday, short, on a chip.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayShortWed;

  /// Weekday, short, on a chip.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayShortThu;

  /// Weekday, short, on a chip.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayShortFri;

  /// Weekday, short, on a chip.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get dayShortSat;

  /// Weekday, short, on a chip.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get dayShortSun;

  /// Month, short.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// Month, short.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// Month, short.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// Month, short.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// Month, short.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// Month, short.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// Month, short.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// Month, short.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// Month, short.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// Month, short.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// Month, short.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// Month, short.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// Snackbar after following a stall.
  ///
  /// In en, this message translates to:
  /// **'Following {name}.'**
  String vpFollowing(String name);

  /// Snackbar after unfollowing a stall.
  ///
  /// In en, this message translates to:
  /// **'Stopped following {name}.'**
  String vpUnfollowed(String name);

  /// Tooltip of the bookmark button.
  ///
  /// In en, this message translates to:
  /// **'Follow stall'**
  String get vpFollow;

  /// Tooltip of the bookmark button when already following.
  ///
  /// In en, this message translates to:
  /// **'Unfollow stall'**
  String get vpUnfollow;

  /// Badge on the stall photo.
  ///
  /// In en, this message translates to:
  /// **'Inspected {ago}'**
  String vpInspected(String ago);

  /// Tooltip of the share button.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get vpShare;

  /// Name of the not-yet-built feature.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get vpFeatureSharing;

  /// Tooltip of the call button.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get vpCall;

  /// Name of the not-yet-built feature.
  ///
  /// In en, this message translates to:
  /// **'Calling the stall'**
  String get vpFeatureCalling;

  /// Big directions button with the distance.
  ///
  /// In en, this message translates to:
  /// **'Directions ({distance})'**
  String vpDirectionsDistance(String distance);

  /// Tab of the stall profile.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get vpTabOverview;

  /// Tab of the stall profile.
  ///
  /// In en, this message translates to:
  /// **'Hygiene Breakdown'**
  String get vpTabHygiene;

  /// Tab of the stall profile with the number of reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews ({count})'**
  String vpTabReviews(int count);

  /// Food safety grade such as A+.
  ///
  /// In en, this message translates to:
  /// **'{grade} Grade'**
  String vpGrade(String grade);

  /// No grade or water check yet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get vpGradeNone;

  /// Grade: needs improvement.
  ///
  /// In en, this message translates to:
  /// **'Needs work'**
  String get vpGradeNeedsWork;

  /// Water source was verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get vpWaterVerified;

  /// Water source was not verified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get vpWaterUnverified;

  /// Caption of a quick fact.
  ///
  /// In en, this message translates to:
  /// **'Food Safety'**
  String get vpMetricFoodSafety;

  /// Caption of a quick fact.
  ///
  /// In en, this message translates to:
  /// **'Water Source'**
  String get vpMetricWater;

  /// Caption of the review count (one).
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get vpMetricReview;

  /// Caption of the review count (many).
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get vpMetricReviews;

  /// Heading of the description card.
  ///
  /// In en, this message translates to:
  /// **'About {name}'**
  String vpAbout(String name);

  /// Shown when the stall has no description.
  ///
  /// In en, this message translates to:
  /// **'The vendor has not added a description yet.'**
  String get vpNoDescription;

  /// Heading of the menu card.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get vpMenu;

  /// Shown when the stall has no menu items.
  ///
  /// In en, this message translates to:
  /// **'This stall has not added its menu yet.'**
  String get vpNoMenu;

  /// Button on the overview tab.
  ///
  /// In en, this message translates to:
  /// **'Leave a Review & Photo 📸'**
  String get vpLeaveReview;

  /// Heading of the hours card.
  ///
  /// In en, this message translates to:
  /// **'Operating Hours'**
  String get vpOperatingHours;

  /// The vendor has not set opening hours.
  ///
  /// In en, this message translates to:
  /// **'Hours not set'**
  String get vpHoursNotSet;

  /// Opening hours and live status.
  ///
  /// In en, this message translates to:
  /// **'{hours} (Open now)'**
  String vpHoursOpenNow(String hours);

  /// Opening hours and live status.
  ///
  /// In en, this message translates to:
  /// **'{hours} (Closed now)'**
  String vpHoursClosedNow(String hours);

  /// A weekday on which the stall is closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get vpClosed;

  /// A menu item that is sold out.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get vpSoldOut;

  /// A menu item marked fresh today.
  ///
  /// In en, this message translates to:
  /// **'Fresh today'**
  String get vpFreshToday;

  /// Small heading on the hygiene tab.
  ///
  /// In en, this message translates to:
  /// **'AUDIT STATUS'**
  String get vpAuditStatus;

  /// When the stall was last inspected.
  ///
  /// In en, this message translates to:
  /// **'Last inspected {ago}'**
  String vpLastInspected(String ago);

  /// Re-verification is overdue.
  ///
  /// In en, this message translates to:
  /// **'Re-check due now'**
  String get vpRecheckDue;

  /// Days until re-verification.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Re-check in 1 day} other{Re-check in {days} days}}'**
  String vpRecheckIn(int days);

  /// Caption under the name of the inspecting organisation.
  ///
  /// In en, this message translates to:
  /// **'Inspecting organisation'**
  String get vpInspectingOrg;

  /// Shown on the hygiene tab before the first inspection.
  ///
  /// In en, this message translates to:
  /// **'No inspection on record yet. The checklist appears here after a municipal inspector visits this stall.'**
  String get vpNoInspection;

  /// Heading of the checklist.
  ///
  /// In en, this message translates to:
  /// **'5-Point Checklist'**
  String get vpChecklistTitle;

  /// Label beside the checklist heading. TODO(si-review): 'Municipal' rendered නගර සභා; confirm.
  ///
  /// In en, this message translates to:
  /// **'Municipal Standard'**
  String get vpMunicipalStandard;

  /// Checklist result: half marks. TODO(si-review): 'Partly Met' as අර්ධ වශයෙන් සපුරා ඇත; confirm.
  ///
  /// In en, this message translates to:
  /// **'Partly Met'**
  String get vpResultPartial;

  /// Checklist result: failed.
  ///
  /// In en, this message translates to:
  /// **'Needs Improvement'**
  String get vpResultFail;

  /// Heading of the inspector's notes.
  ///
  /// In en, this message translates to:
  /// **'Inspector\'s notes'**
  String get vpInspectorNotes;

  /// Row that opens the evidence photo.
  ///
  /// In en, this message translates to:
  /// **'Inspection evidence photo'**
  String get vpEvidencePhoto;

  /// Link.
  ///
  /// In en, this message translates to:
  /// **'View >'**
  String get vpViewArrow;

  /// Link from the hygiene tab to the reviews.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No customer reviews yet} =1{Read what 1 customer says} other{Read what {count} customers say}}'**
  String vpReadReviews(int count);

  /// Link.
  ///
  /// In en, this message translates to:
  /// **'Reviews >'**
  String get vpReviewsArrow;

  /// Small print at the bottom of the hygiene tab.
  ///
  /// In en, this message translates to:
  /// **'Hygiene scores come from official inspections and are re-verified periodically.'**
  String get vpHygieneFooter;

  /// Checklist point.
  ///
  /// In en, this message translates to:
  /// **'Water Source'**
  String get criterionWaterTitle;

  /// What the water point covers.
  ///
  /// In en, this message translates to:
  /// **'Clean, running water for washing and cooking'**
  String get criterionWaterDesc;

  /// Checklist point.
  ///
  /// In en, this message translates to:
  /// **'Utensil & Glove Hygiene'**
  String get criterionUtensilTitle;

  /// What the utensil point covers.
  ///
  /// In en, this message translates to:
  /// **'Utensils kept clean; gloves or tongs used on food'**
  String get criterionUtensilDesc;

  /// Checklist point.
  ///
  /// In en, this message translates to:
  /// **'Waste Disposal'**
  String get criterionWasteTitle;

  /// What the waste point covers.
  ///
  /// In en, this message translates to:
  /// **'Covered bins, emptied regularly'**
  String get criterionWasteDesc;

  /// Checklist point.
  ///
  /// In en, this message translates to:
  /// **'Food Covering'**
  String get criterionCoveringTitle;

  /// What the covering point covers.
  ///
  /// In en, this message translates to:
  /// **'Prepared and raw food kept covered'**
  String get criterionCoveringDesc;

  /// Checklist point.
  ///
  /// In en, this message translates to:
  /// **'Overall Stall Cleanliness'**
  String get criterionCleanTitle;

  /// What the cleanliness point covers.
  ///
  /// In en, this message translates to:
  /// **'The stall and its surroundings are clean'**
  String get criterionCleanDesc;

  /// Review filter chip.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reviewFilterAll;

  /// Review filter chip.
  ///
  /// In en, this message translates to:
  /// **'With Photos'**
  String get reviewFilterPhotos;

  /// Empty reviews list.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet. Be the first to share what you saw.'**
  String get reviewsNone;

  /// Empty reviews list with the photos filter.
  ///
  /// In en, this message translates to:
  /// **'No reviews with photos yet.'**
  String get reviewsNonePhotos;

  /// Button at the end of the reviews list.
  ///
  /// In en, this message translates to:
  /// **'Load more reviews'**
  String get reviewsLoadMore;

  /// Shown when all reviews are loaded.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get reviewsCaughtUp;

  /// Under the average rating.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No reviews yet} =1{Based on 1 review} other{Based on {count} reviews}}'**
  String reviewsBasedOn(int count);

  /// Expands a long review.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get reviewReadMore;

  /// Collapses a long review.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get reviewShowLess;

  /// Review observation chip.
  ///
  /// In en, this message translates to:
  /// **'Clean Cooking Surface'**
  String get observationCleanArea;

  /// Review observation chip.
  ///
  /// In en, this message translates to:
  /// **'Gloves Worn'**
  String get observationGlovesWorn;

  /// Review observation chip.
  ///
  /// In en, this message translates to:
  /// **'Food Kept Covered'**
  String get observationCoveredFood;

  /// Review observation chip.
  ///
  /// In en, this message translates to:
  /// **'Clean Filtered Water'**
  String get observationCleanWater;

  /// Review observation chip.
  ///
  /// In en, this message translates to:
  /// **'Covered Dustbin'**
  String get observationCoveredBin;

  /// Negative review observation.
  ///
  /// In en, this message translates to:
  /// **'Unclean Area'**
  String get observationUncleanArea;

  /// Negative review observation.
  ///
  /// In en, this message translates to:
  /// **'No Gloves'**
  String get observationNoGloves;

  /// Negative review observation.
  ///
  /// In en, this message translates to:
  /// **'Uncovered Food'**
  String get observationUncoveredFood;

  /// Negative review observation.
  ///
  /// In en, this message translates to:
  /// **'No Running Water'**
  String get observationNoWater;

  /// Negative review observation.
  ///
  /// In en, this message translates to:
  /// **'Overflowing Waste'**
  String get observationOverflowingWaste;

  /// Title of the review screen.
  ///
  /// In en, this message translates to:
  /// **'Leave a Review'**
  String get ruTitle;

  /// Stall name and number under the title.
  ///
  /// In en, this message translates to:
  /// **'{name} ({number})'**
  String ruStallSubtitle(String name, String number);

  /// Photo placeholder.
  ///
  /// In en, this message translates to:
  /// **'Tap to add a photo of your meal'**
  String get ruTapPhoto;

  /// Photo placeholder hint.
  ///
  /// In en, this message translates to:
  /// **'Optional, but verified photos help others'**
  String get ruPhotoOptional;

  /// Button on the chosen photo.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get ruRetake;

  /// Label over the chosen photo.
  ///
  /// In en, this message translates to:
  /// **'Photo added'**
  String get ruPhotoAdded;

  /// When the photo was added.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String ruToday(String time);

  /// Note under the photo.
  ///
  /// In en, this message translates to:
  /// **'Photos help other customers. The server records when yours arrives.'**
  String get ruPhotoHelp;

  /// Heading of the rating card.
  ///
  /// In en, this message translates to:
  /// **'Overall Experience'**
  String get ruOverall;

  /// Rating caption before a star is tapped.
  ///
  /// In en, this message translates to:
  /// **'Tap a star to rate'**
  String get ruRatingNone;

  /// Rating caption.
  ///
  /// In en, this message translates to:
  /// **'Poor (1.0)'**
  String get ruRating1;

  /// Rating caption.
  ///
  /// In en, this message translates to:
  /// **'Below Average (2.0)'**
  String get ruRating2;

  /// Rating caption.
  ///
  /// In en, this message translates to:
  /// **'Average (3.0)'**
  String get ruRating3;

  /// Rating caption.
  ///
  /// In en, this message translates to:
  /// **'Good (4.0)'**
  String get ruRating4;

  /// Rating caption.
  ///
  /// In en, this message translates to:
  /// **'Excellent Hygiene & Taste (5.0)'**
  String get ruRating5;

  /// Accessibility label of a star.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String ruStars(int count);

  /// Heading of the observations card.
  ///
  /// In en, this message translates to:
  /// **'Hygiene Observation Checks'**
  String get ruObservationsTitle;

  /// Hint beside the observations heading.
  ///
  /// In en, this message translates to:
  /// **'Tap to toggle'**
  String get ruTapToToggle;

  /// Text under the observations heading.
  ///
  /// In en, this message translates to:
  /// **'Select all sanitary practices observed at the food cart during your meal.'**
  String get ruObservationsHelp;

  /// Heading of the comment card.
  ///
  /// In en, this message translates to:
  /// **'Detailed Feedback'**
  String get ruFeedbackTitle;

  /// Placeholder of the comment field.
  ///
  /// In en, this message translates to:
  /// **'Describe the food taste, stall cleanliness, cooking hygiene and wait time...'**
  String get ruFeedbackHint;

  /// Switch: hide my name.
  ///
  /// In en, this message translates to:
  /// **'Post anonymously'**
  String get ruAnonymous;

  /// Heading of the note at the bottom.
  ///
  /// In en, this message translates to:
  /// **'Community-Powered Safety'**
  String get ruCommunityTitle;

  /// Text of the note at the bottom.
  ///
  /// In en, this message translates to:
  /// **'Your review and photo help other customers choose clean stalls, and show vendors where they can improve. Reviews are public unless you post anonymously.'**
  String get ruCommunityBody;

  /// Submit button.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get ruSubmit;

  /// Snackbar after a review is sent.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Your review of {stall} was submitted.'**
  String ruThanks(String stall);

  /// Time left on a status, hours and minutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m left'**
  String statusTimeLeftHM(int hours, int minutes);

  /// Time left on a status, minutes only.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m left'**
  String statusTimeLeftM(int minutes);

  /// A status that has expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// Pill on the vendor home.
  ///
  /// In en, this message translates to:
  /// **'Expires in {hours}h'**
  String statusExpiresInH(int hours);

  /// Pill on the vendor home.
  ///
  /// In en, this message translates to:
  /// **'Expires in {minutes}m'**
  String statusExpiresInM(int minutes);

  /// Bottom navigation label.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation label (customer).
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// Bottom navigation label (customer).
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// Bottom navigation label.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Bottom navigation label (vendor).
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// Bottom navigation label (vendor).
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// Tooltip of a search icon.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// Tooltip of the bell icon.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get commonAlerts;

  /// Clears a text field or a list.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// Closes a sheet or dialog.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Photo source choice.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get commonCamera;

  /// Photo source choice.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get commonGallery;

  /// Directions button (not built yet).
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get commonDirections;

  /// A distance in kilometres.
  ///
  /// In en, this message translates to:
  /// **'{value} km'**
  String commonDistanceKm(String value);

  /// A stall's number, from its stall code.
  ///
  /// In en, this message translates to:
  /// **'Stall #{number}'**
  String stallNumber(int number);

  /// Distance from the person to a stall.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String stallDistanceAway(String distance);

  /// Stall is open.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get stallOpenNow;

  /// Stall is open until a closing time.
  ///
  /// In en, this message translates to:
  /// **'Open until {time}'**
  String stallOpenUntil(String time);

  /// Stall is open (title case, on a card).
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get stallOpenNowCap;

  /// Stall is open until a closing time (title case).
  ///
  /// In en, this message translates to:
  /// **'Open Now until {time}'**
  String stallOpenNowUntil(String time);

  /// Stall is closed.
  ///
  /// In en, this message translates to:
  /// **'Closed now'**
  String get stallClosedNow;

  /// Shown instead of a star rating when nobody has reviewed the stall.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get stallRatingNew;

  /// Small pill: the stall is clean.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get stallClean;

  /// Small pill: the stall needs attention.
  ///
  /// In en, this message translates to:
  /// **'Caution'**
  String get stallCaution;

  /// Inspection score as a percentage.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Clean'**
  String stallCleanPercent(int percent);

  /// Directions button with the walking time.
  ///
  /// In en, this message translates to:
  /// **'Directions ({minutes} min)'**
  String stallWalkMinutes(int minutes);

  /// Button on a stall card.
  ///
  /// In en, this message translates to:
  /// **'View Menu'**
  String get stallViewMenu;

  /// Link on a stall card (not built yet).
  ///
  /// In en, this message translates to:
  /// **'Order Pick-up →'**
  String get stallOrderPickup;

  /// Name of the not-yet-built feature.
  ///
  /// In en, this message translates to:
  /// **'Pick-up orders'**
  String get stallFeaturePickup;

  /// Hygiene level label.
  ///
  /// In en, this message translates to:
  /// **'Verified Clean'**
  String get hygieneVerifiedClean;

  /// Hygiene level label.
  ///
  /// In en, this message translates to:
  /// **'High Hygiene'**
  String get hygieneHigh;

  /// Hygiene level label: re-verification is due.
  ///
  /// In en, this message translates to:
  /// **'Needs re-check'**
  String get hygieneNeedsRecheck;

  /// Hygiene level label: never inspected.
  ///
  /// In en, this message translates to:
  /// **'Not yet inspected'**
  String get hygieneNotInspected;

  /// Hygiene level label. TODO(si-review): Reworded in this pass; confirm.
  ///
  /// In en, this message translates to:
  /// **'Re-verification Pending'**
  String get hygieneReverificationPending;

  /// Before noon, after a clock time.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get timeAm;

  /// After noon, after a clock time.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get timePm;

  /// Where the app searches from: the phone's GPS.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get searchCenterCurrent;

  /// Where the app searches from when GPS is not available.
  ///
  /// In en, this message translates to:
  /// **'Colombo (default area)'**
  String get searchCenterDefault;

  /// Small label above the current location in the home header.
  ///
  /// In en, this message translates to:
  /// **'CURRENT SPOT'**
  String get homeCurrentSpot;

  /// Section title. TODO(si-review): 'Stories' (කතා) is ambiguous; Instagram-style stories are often left as ස්ටෝරි. Confirm.
  ///
  /// In en, this message translates to:
  /// **'Daily Fresh Stories'**
  String get homeStoriesTitle;

  /// Link beside the stories title.
  ///
  /// In en, this message translates to:
  /// **'24h cycle'**
  String get homeStoriesCycle;

  /// Snackbar explaining the 24h cycle. TODO(si-review): 'Stories' (කතා); see homeStoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Stories disappear 24 hours after they are posted.'**
  String get homeStoriesCycleHint;

  /// Empty state of the stories row.
  ///
  /// In en, this message translates to:
  /// **'No stories right now. Statuses from stalls you follow and your friends show up here.'**
  String get homeNoStories;

  /// Hours left on a story.
  ///
  /// In en, this message translates to:
  /// **'{hours}h left'**
  String homeStoryTimeLeft(int hours);

  /// Section title above the map preview. TODO(si-review): 'Radar' transliterated as රේඩාරය; confirm.
  ///
  /// In en, this message translates to:
  /// **'Live Hygiene Radar'**
  String get homeRadarTitle;

  /// Link beside the radar title.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get homeOpenMap;

  /// Empty state of the map preview.
  ///
  /// In en, this message translates to:
  /// **'No stalls found within 25 km of this spot yet.'**
  String get homeNoStallsNearby;

  /// Pill on the map preview.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stall nearby} other{{count} stalls nearby}}'**
  String homeRadarStallsNearby(int count);

  /// Section title above the category chips.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get homeForYou;

  /// Link that opens the filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Filter Category'**
  String get homeFilterCategory;

  /// The 'every category' chip.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get homeAll;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Best Rating Vendor Shop'**
  String get homeBestRated;

  /// Subtitle of the best-rated section.
  ///
  /// In en, this message translates to:
  /// **'Highest customer star ratings'**
  String get homeBestRatedSub;

  /// Link to the full list.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// Empty state of the best-rated row.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet. Be the first to review a stall.'**
  String get homeNoRatings;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Shops Near You'**
  String get homeShopsNear;

  /// Subtitle: the list is sorted by distance.
  ///
  /// In en, this message translates to:
  /// **'Sorted by proximity to {place}'**
  String homeSortedByProximity(String place);

  /// Subtitle: the list is sorted by rating.
  ///
  /// In en, this message translates to:
  /// **'Sorted by rating'**
  String get homeSortedByRating;

  /// Toggle: sort by distance.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get homeNearbyToggle;

  /// Accessibility label of the nearby toggle.
  ///
  /// In en, this message translates to:
  /// **'Sort by nearby'**
  String get homeSortByNearby;

  /// Empty state of the nearby list.
  ///
  /// In en, this message translates to:
  /// **'No stalls match your filters. Widen the radius or clear a category.'**
  String get homeNoMatch;

  /// While the nearby stalls load.
  ///
  /// In en, this message translates to:
  /// **'Finding stalls…'**
  String get mapFinding;

  /// Pill on the full map.
  ///
  /// In en, this message translates to:
  /// **'{count} Open Stalls Nearby'**
  String mapOpenStallsNearby(int count);

  /// Placeholder of the map search field.
  ///
  /// In en, this message translates to:
  /// **'Search kottu, hoppers, juice...'**
  String get mapSearchHint;

  /// Tooltip and feature name (not built yet).
  ///
  /// In en, this message translates to:
  /// **'Map layers'**
  String get mapLayers;

  /// Tooltip of the GPS button.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get mapUseMyLocation;

  /// Tooltip of the filter button.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get mapFilters;

  /// Title of the draggable list.
  ///
  /// In en, this message translates to:
  /// **'Nearby Stalls'**
  String get mapNearbyStalls;

  /// Subtitle of the draggable list.
  ///
  /// In en, this message translates to:
  /// **'Sorted by distance'**
  String get mapSortedByDistance;

  /// Link to the split map and list screen.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get mapListView;

  /// Empty state of the map list.
  ///
  /// In en, this message translates to:
  /// **'No stalls match. Try another search or adjust your filters.'**
  String get mapNoMatch;

  /// Small label above the location on the split screen. TODO(si-review): 'Radar' transliterated as රේඩාරය; confirm.
  ///
  /// In en, this message translates to:
  /// **'LIVE RADAR'**
  String get splitLiveRadar;

  /// Pill on the split map.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Showing 1 stall within {radius}} other{Showing {count} stalls within {radius}}}'**
  String splitShowing(int count, String radius);

  /// List title while loading.
  ///
  /// In en, this message translates to:
  /// **'Stalls'**
  String get splitStallsTitle;

  /// List title with the count.
  ///
  /// In en, this message translates to:
  /// **'{count} Stalls'**
  String splitStallsCount(int count);

  /// List title when the High Hygiene filter is on.
  ///
  /// In en, this message translates to:
  /// **'{count} High Hygiene Stalls'**
  String splitHighHygieneCount(int count);

  /// Tooltip: switch to detailed cards.
  ///
  /// In en, this message translates to:
  /// **'Detailed cards'**
  String get splitDetailedCards;

  /// Tooltip: switch to compact cards.
  ///
  /// In en, this message translates to:
  /// **'Compact cards'**
  String get splitCompactCards;

  /// Tooltip of the sort menu.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get splitSort;

  /// Sort option.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get splitSortDistance;

  /// Sort option.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get splitSortRating;

  /// Empty state of the split list.
  ///
  /// In en, this message translates to:
  /// **'No stalls match these filters. Try widening the radius or turning off High Hygiene.'**
  String get splitNoMatch;

  /// Placeholder of the search field.
  ///
  /// In en, this message translates to:
  /// **'Search stalls, dishes, categories'**
  String get searchHint;

  /// Shown before anything is typed and nothing is recent.
  ///
  /// In en, this message translates to:
  /// **'Search for a stall, a dish or a category like kottu or hoppers.'**
  String get searchEmptyHint;

  /// Heading of the recent searches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get searchRecent;

  /// Line above the search results.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result for “{query}”} other{{count} results for “{query}”}}'**
  String searchResultsCount(int count, String query);

  /// Empty state heading.
  ///
  /// In en, this message translates to:
  /// **'No results for “{query}”'**
  String searchNoResultsTitle(String query);

  /// Empty state text.
  ///
  /// In en, this message translates to:
  /// **'Try a different word, or adjust your filters: the radius and hygiene filters may be hiding stalls.'**
  String get searchNoResultsBody;

  /// Button that opens the filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Adjust filters'**
  String get searchAdjustFilters;

  /// Title of the filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// Resets the draft filters.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filtersReset;

  /// Removes every filter and closes the sheet.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get filtersClearAll;

  /// Apply button while the number of results is not known.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get filtersApply;

  /// Disabled apply button when nothing matches.
  ///
  /// In en, this message translates to:
  /// **'No stalls match'**
  String get filtersNoMatch;

  /// Apply button with the number of results.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Show 1 Result} other{Show {count} Results}}'**
  String filtersShowResults(int count);

  /// Section label.
  ///
  /// In en, this message translates to:
  /// **'Search Radius'**
  String get filtersSearchRadius;

  /// Section label.
  ///
  /// In en, this message translates to:
  /// **'Hygiene Rating'**
  String get filtersHygieneRating;

  /// Hygiene filter: any level.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filtersAll;

  /// Hygiene filter.
  ///
  /// In en, this message translates to:
  /// **'High Hygiene Only'**
  String get filtersHighOnly;

  /// Section label.
  ///
  /// In en, this message translates to:
  /// **'Food Category'**
  String get filtersFoodCategory;

  /// Switch label.
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get filtersOpenNow;

  /// Text under the Open Now switch.
  ///
  /// In en, this message translates to:
  /// **'Only stalls serving right now'**
  String get filtersOpenNowSub;

  /// Tooltip of a back arrow.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Help button or link.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get commonHelp;

  /// Tooltip of the eye button on a password field.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get commonShowPassword;

  /// Tooltip of the eye button on a password field.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get commonHidePassword;

  /// Progress label of a multi-step flow.
  ///
  /// In en, this message translates to:
  /// **'STEP {current} OF {total}'**
  String commonStepOf(int current, int total);

  /// Badge on the first screen.
  ///
  /// In en, this message translates to:
  /// **'Live Street Hygiene Protocol'**
  String get authRoleLiveProtocol;

  /// Badge next to the app name.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get authRoleVerified;

  /// Tagline under the app name.
  ///
  /// In en, this message translates to:
  /// **'Discover Hygienic Street Food & Support Local Stalls'**
  String get authRoleTagline;

  /// Caption under the decorative progress bar.
  ///
  /// In en, this message translates to:
  /// **'Syncing neighborhood stalls...'**
  String get authRoleSyncing;

  /// Heading of the hygiene tip card.
  ///
  /// In en, this message translates to:
  /// **'DAILY VENDOR STANDARD'**
  String get authTipHeading;

  /// Rotating hygiene tip.
  ///
  /// In en, this message translates to:
  /// **'Tip: Look for a covered waste bin — it\'s one of our top hygiene checks!'**
  String get authTip1;

  /// Rotating hygiene tip.
  ///
  /// In en, this message translates to:
  /// **'Tip: Vendors who change gloves between orders score higher on hygiene.'**
  String get authTip2;

  /// Rotating hygiene tip.
  ///
  /// In en, this message translates to:
  /// **'Tip: Clean, running water at the stall is checked on every inspection.'**
  String get authTip3;

  /// Rotating hygiene tip.
  ///
  /// In en, this message translates to:
  /// **'Tip: Food covered from dust and flies is a sign of a well-run stall.'**
  String get authTip4;

  /// Heading above the two role cards.
  ///
  /// In en, this message translates to:
  /// **'Choose your role to continue'**
  String get authRoleChoose;

  /// Role card title.
  ///
  /// In en, this message translates to:
  /// **'I\'m a Customer'**
  String get authRoleCustomerTitle;

  /// Badge on the customer role card.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get authRolePopular;

  /// Customer role card text.
  ///
  /// In en, this message translates to:
  /// **'Find clean, delicious street food nearby & see live vendor updates'**
  String get authRoleCustomerSubtitle;

  /// Small tag on the customer card.
  ///
  /// In en, this message translates to:
  /// **'GPS discovery'**
  String get authRoleTagGps;

  /// Small tag on the customer card.
  ///
  /// In en, this message translates to:
  /// **'Clean score verified'**
  String get authRoleTagCleanScore;

  /// Role card title.
  ///
  /// In en, this message translates to:
  /// **'I\'m a Vendor'**
  String get authRoleVendorTitle;

  /// Short badge: zero percent commission.
  ///
  /// In en, this message translates to:
  /// **'0% Comm.'**
  String get authRoleCommission;

  /// Vendor role card text.
  ///
  /// In en, this message translates to:
  /// **'List your food stall immediately with no wait & reach daily eaters'**
  String get authRoleVendorSubtitle;

  /// Small tag on the vendor card.
  ///
  /// In en, this message translates to:
  /// **'Instant 3-min onboarding'**
  String get authRoleTagOnboarding;

  /// Small tag on the vendor card.
  ///
  /// In en, this message translates to:
  /// **'Get clean certified'**
  String get authRoleTagCertified;

  /// Small print under the role cards.
  ///
  /// In en, this message translates to:
  /// **'By selecting, you accept standard market safety guidelines'**
  String get authRoleDisclaimer;

  /// Label of the sign-in/sign-up identifier field.
  ///
  /// In en, this message translates to:
  /// **'Email or Mobile Number'**
  String get authFieldEmailOrMobile;

  /// Placeholder of the sign-in identifier field.
  ///
  /// In en, this message translates to:
  /// **'e.g. +94 77 123 4567 or name@email.com'**
  String get authHintEmailOrMobile;

  /// Placeholder of the customer sign-up identifier field.
  ///
  /// In en, this message translates to:
  /// **'name@example.com or +1 (555) 000'**
  String get authHintEmailOrMobileShort;

  /// Placeholder of the vendor sign-up identifier field.
  ///
  /// In en, this message translates to:
  /// **'name@example.com or +94 77 123 4567'**
  String get authHintEmailOrMobileLong;

  /// Label of a password field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authFieldPassword;

  /// Placeholder of the sign-in password field.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authHintPassword;

  /// Placeholder of a new-password field.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authHintPasswordMin;

  /// Label of the confirm-password field.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authFieldConfirmPassword;

  /// Placeholder of the confirm-password field.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get authHintConfirmPassword;

  /// Label of the name field.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get authFieldFullName;

  /// Placeholder of the name field.
  ///
  /// In en, this message translates to:
  /// **'Your full name'**
  String get authHintFullName;

  /// Link on the customer sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotPassword;

  /// Name of the not-yet-built feature, used in 'X is coming soon'.
  ///
  /// In en, this message translates to:
  /// **'Password reset'**
  String get authFeaturePasswordReset;

  /// Sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get authLogIn;

  /// Divider text above the Google button.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get authOrContinueWith;

  /// Divider text above the Google button.
  ///
  /// In en, this message translates to:
  /// **'or sign up with'**
  String get authOrSignUpWith;

  /// Google button label (not built yet).
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authGoogleContinue;

  /// Name of the not-yet-built feature.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in'**
  String get authFeatureGoogle;

  /// Text before the Sign Up link.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// Link to the sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUp;

  /// Badge and banner label for the vendor area.
  ///
  /// In en, this message translates to:
  /// **'Vendor Portal'**
  String get authVendorPortal;

  /// Banner on the customer sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Are you a food vendor?'**
  String get authAreYouVendor;

  /// Badge on the customer sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Verified Safe Street Food Network'**
  String get authConsumerLoginBadge;

  /// Heading of the customer sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back, Foodie 👋'**
  String get authConsumerLoginTitle;

  /// Text under the heading.
  ///
  /// In en, this message translates to:
  /// **'Log in to find verified hygienic street food near you'**
  String get authConsumerLoginSubtitle;

  /// Shown when the terms box is not ticked.
  ///
  /// In en, this message translates to:
  /// **'You must accept the terms to create an account.'**
  String get authTermsRequired;

  /// Badge on the customer sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'100% Free for food seekers'**
  String get authSignupFreeBadge;

  /// Heading and button of customer sign-up.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// Text under the sign-up heading.
  ///
  /// In en, this message translates to:
  /// **'Join to discover certified hygienic street food stalls and track live fresh preparations'**
  String get authSignupSubtitle;

  /// First part of the agreement sentence; the sentence is built from parts so the links keep working in every language.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get authAgreePre;

  /// Link part of the agreement sentence.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get authAgreeTerms;

  /// Joins the two links in the customer agreement sentence.
  ///
  /// In en, this message translates to:
  /// **' & '**
  String get authAgreeAnd;

  /// Link part of the agreement sentence.
  ///
  /// In en, this message translates to:
  /// **'Food Safety Community Guidelines'**
  String get authAgreeGuidelines;

  /// Last part of the customer agreement sentence; empty in English.
  ///
  /// In en, this message translates to:
  /// **''**
  String get authAgreePost;

  /// Card title on the customer sign-up screen. TODO(si-review): 'Municipal' rendered නගර සභා; confirm it is the right authority term (vs. පළාත් පාලන / මහ නගර සභා).
  ///
  /// In en, this message translates to:
  /// **'Municipal Health Certified'**
  String get authCertifiedTitle;

  /// Card text on the customer sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'Live oil purity ratings, inspection stamps & daily sanitization logs.'**
  String get authCertifiedBody;

  /// Text before the Log In link.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authAlreadyAccount;

  /// Link to the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Log In >'**
  String get authLogInArrow;

  /// Small label above the vendor sign-in heading.
  ///
  /// In en, this message translates to:
  /// **'Merchant Access'**
  String get authVendorEyebrow;

  /// Heading of the vendor sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Vendor Sign In 🏪'**
  String get authVendorLoginTitle;

  /// Text under the heading.
  ///
  /// In en, this message translates to:
  /// **'Manage your stall, post daily stories & view live customer reviews.'**
  String get authVendorLoginSubtitle;

  /// Trust note on the vendor sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Direct stall management — no admin middleman'**
  String get authTrustCard;

  /// Label of the vendor sign-in identifier field.
  ///
  /// In en, this message translates to:
  /// **'Stall Owner Mobile or Email'**
  String get authFieldOwnerContact;

  /// Placeholder of the vendor sign-in identifier field.
  ///
  /// In en, this message translates to:
  /// **'+1 (555) 000-0000 or email'**
  String get authHintOwnerContact;

  /// Label of the vendor password field.
  ///
  /// In en, this message translates to:
  /// **'Password or Security PIN'**
  String get authFieldVendorPassword;

  /// Placeholder of the vendor password field.
  ///
  /// In en, this message translates to:
  /// **'Enter vendor password'**
  String get authHintVendorPassword;

  /// Checkbox: keep the session after the app closes.
  ///
  /// In en, this message translates to:
  /// **'Stay signed in'**
  String get authStaySignedIn;

  /// Link on the vendor sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Forgot Vendor PIN / Password?'**
  String get authForgotVendorPin;

  /// Vendor sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Log In to Vendor Portal'**
  String get authVendorLogIn;

  /// Button for a feature that is not built yet. TODO(si-review): 'One-time passcode' rendered එක්-වරක් භාවිත රහස් කේතය; confirm.
  ///
  /// In en, this message translates to:
  /// **'Send One-Time Passcode via SMS'**
  String get authSendOtp;

  /// Name of the not-yet-built feature.
  ///
  /// In en, this message translates to:
  /// **'SMS one-time passcodes'**
  String get authFeatureSmsOtp;

  /// Text before the create-account link.
  ///
  /// In en, this message translates to:
  /// **'New stall owner?'**
  String get authNewStallOwner;

  /// Heading, link and button for vendor sign-up.
  ///
  /// In en, this message translates to:
  /// **'Create Vendor Account'**
  String get authCreateVendorAccount;

  /// Small label on the switch-to-customer banner.
  ///
  /// In en, this message translates to:
  /// **'Are you a customer?'**
  String get authAreYouCustomer;

  /// Banner text on the vendor sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Switch to Customer Login'**
  String get authSwitchToCustomerLogin;

  /// Footer link (not built yet).
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authFooterPrivacy;

  /// Footer link (not built yet).
  ///
  /// In en, this message translates to:
  /// **'Vendor Guidelines'**
  String get authFooterGuidelines;

  /// Footer link (not built yet).
  ///
  /// In en, this message translates to:
  /// **'Emergency Support'**
  String get authFooterEmergency;

  /// Small label above the vendor sign-up heading.
  ///
  /// In en, this message translates to:
  /// **'Vendor Registration'**
  String get authVendorRegistration;

  /// Orange badge on the vendor sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get authPartner;

  /// Text under the vendor sign-up heading.
  ///
  /// In en, this message translates to:
  /// **'Register your street kitchen or food cart to reach verified diners and broadcast daily fresh statuses.'**
  String get authVendorSignupSubtitle;

  /// Label of the vendor's name field.
  ///
  /// In en, this message translates to:
  /// **'Owner Full Name'**
  String get authOwnerFullName;

  /// Badge shown once the typed identifier is a mobile number.
  ///
  /// In en, this message translates to:
  /// **'SMS Ready'**
  String get authSmsReady;

  /// Link part of the vendor agreement sentence.
  ///
  /// In en, this message translates to:
  /// **'Vendor Merchant Standards'**
  String get authAgreeVendorLink;

  /// Last part of the vendor agreement sentence.
  ///
  /// In en, this message translates to:
  /// **', Municipal Hygiene Protocol guidelines, and {brand} Community Terms.'**
  String authAgreeVendorPost(String brand);

  /// Text before the switch-to-customer link.
  ///
  /// In en, this message translates to:
  /// **'Looking to order food?'**
  String get authLookingToOrder;

  /// Link on the vendor sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'Switch to Consumer Sign-Up'**
  String get authSwitchToConsumerSignup;

  /// Card title on the vendor sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'Next Step: Stall Onboarding'**
  String get authNextStep;

  /// Badge: how long stall onboarding takes.
  ///
  /// In en, this message translates to:
  /// **'~2 mins'**
  String get authNextStepTime;

  /// Card text on the vendor sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'Register stall location, food craft specialties, and upload your hygiene certification badge.'**
  String get authNextStepBody;

  /// Button on an error message that repeats the request.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// Snackbar for a feature that is designed but not built yet.
  ///
  /// In en, this message translates to:
  /// **'{feature} is coming soon.'**
  String commonComingSoon(String feature);

  /// Small tag on a menu item that is not built yet.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get commonSoon;

  /// No network or the server did not answer.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach {brand}. Check your connection and try again.'**
  String errorOffline(String brand);

  /// Fallback for any failure with no better message. TODO(si-review): Register: spoken-style (-ණා). Confirm which register you want for errors.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// The server answered with something that is not valid JSON.
  ///
  /// In en, this message translates to:
  /// **'The server\'s reply could not be read. Please try again, and if it keeps happening check the backend.'**
  String get errorUnreadable;

  /// HTTP 429 rate limit.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a minute and try again.'**
  String get errorTooManyAttempts;

  /// HTTP 5xx.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Please try again shortly.'**
  String get errorServer;

  /// The reply had a shape the app does not know.
  ///
  /// In en, this message translates to:
  /// **'The server sent an unexpected response. Please try again.'**
  String get errorUnexpectedResponse;

  /// Nobody is signed in or the session ended.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get errorSignInAgain;

  /// A vendor account that has no stall.
  ///
  /// In en, this message translates to:
  /// **'You have not set up a stall yet.'**
  String get errorNoStall;

  /// The account's role is not customer or vendor.
  ///
  /// In en, this message translates to:
  /// **'This account can\'t be used in the {brand} app.'**
  String errorAccountNotSupported(String brand);

  /// The secure storage on the phone refused the sign-in token.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your session securely on this device.'**
  String get errorSessionNotSaved;

  /// Button on a vendor screen when the vendor has no stall yet; opens stall setup.
  ///
  /// In en, this message translates to:
  /// **'Set up my stall'**
  String get vendorSetUpMyStall;

  /// Empty form field.
  ///
  /// In en, this message translates to:
  /// **'{label} is required.'**
  String validationRequired(String label);

  /// Field name used inside the 'is required' message.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get validationLabelFullName;

  /// Field name used inside the 'is required' message.
  ///
  /// In en, this message translates to:
  /// **'Email or mobile number'**
  String get validationLabelEmailOrMobile;

  /// Field name used inside the 'is required' message.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get validationLabelPassword;

  /// Field name used inside the 'is required' message.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get validationLabelConfirmPassword;

  /// Validation message.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get validationInvalidEmail;

  /// Validation message.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address or mobile number.'**
  String get validationInvalidEmailOrMobile;

  /// Validation message for a short new password.
  ///
  /// In en, this message translates to:
  /// **'Use at least {count} characters.'**
  String validationPasswordTooShort(int count);

  /// Validation message when the two passwords differ.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get validationPasswordsMismatch;

  /// GPS is off.
  ///
  /// In en, this message translates to:
  /// **'Location is switched off on this phone. Turn it on and try again.'**
  String get locationServicesOff;

  /// The person said no to the location permission.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied. Allow it to pin your stall, then try again.'**
  String get locationDenied;

  /// Permission is permanently denied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is blocked. Allow it for {brand} in Settings.'**
  String locationDeniedForever(String brand);

  /// GPS gave no position.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location. Move to an open area and try again.'**
  String get locationUnavailable;

  /// Camera permission denied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is blocked. Allow it for {brand} in Settings, or choose from your gallery.'**
  String photoCameraBlocked(String brand);

  /// The camera could not start.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the camera. Try the gallery instead.'**
  String get photoCameraFailed;

  /// Gallery permission denied.
  ///
  /// In en, this message translates to:
  /// **'Photo access is blocked. Allow it for {brand} in Settings.'**
  String photoGalleryBlocked(String brand);

  /// The gallery could not open.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your gallery. Try the camera instead.'**
  String get photoGalleryFailed;

  /// Less than a minute ago.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get agoJustNow;

  /// Minutes since something happened.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String agoMinutes(int count);

  /// Hours since something happened.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String agoHours(int count);

  /// Days since something happened.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String agoDays(int count);

  /// Weeks since something happened.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String agoWeeks(int count);

  /// The app's name, shown in the task switcher.
  ///
  /// In en, this message translates to:
  /// **'StreetBite'**
  String get appTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
