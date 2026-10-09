// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get inspTitle => 'Inspection Submission';

  @override
  String get inspSelectStall => 'Select Stall to Inspect';

  @override
  String get inspSearchHint => 'Search stall name';

  @override
  String get inspNoMatch => 'No stall matches.';

  @override
  String inspStallWithNumber(String name, int number) {
    return '$name (#$number)';
  }

  @override
  String inspLastInspected(String ago) {
    return 'Last inspected $ago';
  }

  @override
  String get inspChecklistTitle => 'Hygiene Checklist (5 Mandatory Criteria)';

  @override
  String inspScored(int count) {
    return '$count/5 Scored';
  }

  @override
  String get inspScoreAll =>
      'Score all five criteria to see the stall\'s score.';

  @override
  String inspWillScore(String score, String grade) {
    return 'The stall will score $score / 5.0 ($grade)';
  }

  @override
  String get inspAttachPhoto => 'Attach Inspection Photo';

  @override
  String get inspTapCapture => 'Tap to capture inspection evidence';

  @override
  String get inspPhotoRequired => 'Required: a photo of the stall as inspected';

  @override
  String get inspEvidence => 'Evidence attached (1 photo)';

  @override
  String inspToday(String time) {
    return 'Today, $time';
  }

  @override
  String get inspRetake => 'Retake or choose another';

  @override
  String get inspServerRecords => 'The server records when the photo arrives.';

  @override
  String get inspNotes => 'Inspector Notes (Optional)';

  @override
  String get inspNotesHint =>
      'Observations, corrective actions required, follow-up date...';

  @override
  String get inspNotesPublic =>
      'Notes appear on the stall\'s public hygiene page';

  @override
  String get inspSubmit => 'Submit Inspection Score';

  @override
  String get inspSubmitHint =>
      'Pick a stall, score all five criteria and attach a photo to submit.';

  @override
  String get inspSubmitEffect =>
      'This will update the stall\'s public hygiene rating immediately.';

  @override
  String inspSubmitted(String name, String score, String grade) {
    return 'Inspection of $name submitted. It scores $score ($grade).';
  }

  @override
  String get inspPass => 'Pass';

  @override
  String get inspPartial => 'Partial';

  @override
  String get inspFail => 'Fail';

  @override
  String get inspGradeNeedsImprovement => 'Needs Improvement';

  @override
  String get inspWaterTitle => 'Water Source';

  @override
  String get inspWaterDesc => 'Clean, running triple-filtered water available';

  @override
  String get inspUtensilTitle => 'Hand & Utensil Hygiene';

  @override
  String get inspUtensilDesc => 'Gloves & sanitized utensils in active use';

  @override
  String get inspWasteTitle => 'Waste Disposal';

  @override
  String get inspWasteDesc => 'Covered waste bin with proper sealed disposal';

  @override
  String get inspCoveringTitle => 'Food Covering';

  @override
  String get inspCoveringDesc => 'Food protected from street dust & flies';

  @override
  String get inspCleanTitle => 'Overall Stall Cleanliness';

  @override
  String get inspCleanDesc => 'Surrounding prep counter & floor sanitized';

  @override
  String get commonEdit => 'Edit';

  @override
  String get categoryKottu => 'Kottu';

  @override
  String get categoryShortEats => 'Short Eats';

  @override
  String get categoryFreshJuice => 'Fresh Juice';

  @override
  String get categoryHoppers => 'Hoppers';

  @override
  String get categoryRiceAndCurry => 'Rice & Curry';

  @override
  String get categoryBbqSeafood => 'BBQ / Seafood';

  @override
  String get obLeaveTitle => 'Leave stall setup?';

  @override
  String get obLeaveBody =>
      'You can finish later. You will be signed out for now.';

  @override
  String get obStay => 'Stay';

  @override
  String get obSignOut => 'Sign out';

  @override
  String get obTitle => 'Setup Your Food Stall';

  @override
  String get obSubtitle =>
      'Complete your profile to start receiving street-food orders instantly.';

  @override
  String get obInstantTitle => 'Instant Activation';

  @override
  String get obInstantBody =>
      'Your stall goes live immediately — no approval wait or inspector delay!';

  @override
  String get obStallName => 'Stall Name';

  @override
  String get obStallNameHint => 'e.g. your stall\'s name and signature dish';

  @override
  String get obStallNameTip =>
      'Catchy names with your signature dish get 40% more hungry customers.';

  @override
  String get obFoodCategory => 'Food Category';

  @override
  String get obMultiSelect => 'Multi-select';

  @override
  String get obCategoriesLoadFailed => 'Couldn\'t load the categories.';

  @override
  String get obStallLocation => 'Stall Location';

  @override
  String get obFindingYou => 'Finding you...';

  @override
  String get obUpdateGps => 'Update GPS Location 📍';

  @override
  String get obUseGps => 'Use Current GPS Location 📍';

  @override
  String get obOpenSettings => 'Open settings';

  @override
  String get obGpsAccurate => 'GPS Accurate';

  @override
  String get obPinnedLandmark => 'PINNED LANDMARK';

  @override
  String get obCurrentLocation => 'Current Location';

  @override
  String get obNameSpotTitle => 'Name this spot';

  @override
  String get obNameSpotHint => 'e.g. Opposite the bus stand';

  @override
  String get obOpeningTime => 'Opening time';

  @override
  String get obClosingTime => 'Closing time';

  @override
  String get obOpens => 'Opens';

  @override
  String get obCloses => 'Closes';

  @override
  String get obSelectTime => 'Select time';

  @override
  String obTimeNotSet(String label) {
    return '$label, not set';
  }

  @override
  String obTimeValue(String label, String time) {
    return '$label, $time';
  }

  @override
  String get obOpenEveryDay => 'Open 7 Days a Week';

  @override
  String get obDayMon => 'M';

  @override
  String get obDayTue => 'T';

  @override
  String get obDayWed => 'W';

  @override
  String get obDayThu => 'T';

  @override
  String get obDayFri => 'F';

  @override
  String get obDaySat => 'S';

  @override
  String get obDaySun => 'S';

  @override
  String get obPhotoTitle => 'Stall & Food Photo';

  @override
  String get obPhotoTap => 'Tap to take photo of your stall';

  @override
  String get obPhotoHelp =>
      'A clear photo of your stall and your food helps customers trust you.';

  @override
  String get obPhotoAction => 'Open Camera or Gallery';

  @override
  String get obChangePhoto => 'Change photo';

  @override
  String get obDescription => 'Short Description';

  @override
  String get obDescriptionHint => 'Keep it short & mouth-watering';

  @override
  String get obAgreement =>
      'By listing, you agree to maintain fresh ingredients and hygienic food prep standards.';

  @override
  String get obSubmit => 'List My Stall & Go Live 🚀';

  @override
  String get obZeroCommission =>
      'Zero commission on your first 50 orders • Edit anytime';

  @override
  String get obErrNameRequired => 'Give your stall a name.';

  @override
  String obErrNameLong(int max) {
    return 'Keep the name under $max characters.';
  }

  @override
  String get obErrCategories => 'Pick at least one food category.';

  @override
  String get obErrLocation =>
      'Pin your stall\'s location so customers can find you.';

  @override
  String get obErrOpens => 'Choose when you open.';

  @override
  String get obErrCloses => 'Choose when you close.';

  @override
  String get obErrCloseDiffer =>
      'Closing time must be different from opening time.';

  @override
  String get obErrDays => 'Pick the days you are open.';

  @override
  String get obErrPhoto => 'Add a photo of your stall.';

  @override
  String obErrDescLong(int max) {
    return 'Keep the description to $max characters.';
  }

  @override
  String get settingsTitle => 'App Settings';

  @override
  String get settingsRowSub => 'Language, notifications and privacy';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageHelp =>
      'Choose the language used across the app. The change applies straight away and is remembered.';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsNotifications => 'Notification Settings';

  @override
  String get settingsNotificationsSub => 'Choose which alerts you receive';

  @override
  String get settingsFeatureNotifications => 'Notification settings';

  @override
  String get settingsPrivacy => 'Privacy Settings';

  @override
  String get settingsPrivacySub => 'Control who can see your activity';

  @override
  String get settingsFeaturePrivacy => 'Privacy settings';

  @override
  String settingsLanguageSelected(String language) {
    return '$language, selected';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonNotifications => 'Notifications';

  @override
  String get commonComingSoonTag => 'Coming soon';

  @override
  String get vhQuickControls => 'Quick Vendor Controls';

  @override
  String get vhRecentReviews => 'Recent Customer Reviews';

  @override
  String get vhRecentReviewsSub => 'Latest from your customers';

  @override
  String get vhSeeAll => 'See All';

  @override
  String vhSeeAllCount(int count) {
    return 'See All ($count)';
  }

  @override
  String get vhNoReviews =>
      'No reviews yet. They appear here as customers leave them.';

  @override
  String get vhOpenNowTap => 'Open now, tap to close';

  @override
  String get vhClosedTap => 'Closed, tap to open';

  @override
  String get vhPillOpen => 'OPEN NOW 🟢';

  @override
  String get vhPillClosed => 'CLOSED';

  @override
  String get vhHygieneScore => 'HYGIENE SCORE';

  @override
  String get vhStatusCardTitle => 'Today\'s Fresh Prep Status';

  @override
  String get vhNoneLive => 'None live';

  @override
  String get vhNoStatusBody =>
      'You have no status on the radar. Post one so customers can see what is fresh right now.';

  @override
  String get vhStatLikes => 'Likes';

  @override
  String get vhStatComments => 'Comments';

  @override
  String get vhPostStatus => 'Post Daily Status';

  @override
  String get vhPostStatusDesc =>
      'Share today\'s fresh batch with nearby customers.';

  @override
  String get vhUpdateMenu => 'Update Menu';

  @override
  String get vhUpdateMenuDesc =>
      'Change prices and mark items fresh or sold out.';

  @override
  String get vhUpdateHours => 'Update Hours';

  @override
  String get vhUpdateHoursDesc => 'Adjust your opening and closing times.';

  @override
  String get vhViewProfile => 'View Stall Profile';

  @override
  String get vhViewProfileDesc => 'See your stall as customers see it.';

  @override
  String get vhSingleTap => 'SINGLE-TAP';

  @override
  String get vacctStatusOpen => 'Stall Status: OPEN';

  @override
  String get vacctStatusClosed => 'Stall Status: CLOSED';

  @override
  String get vacctOpenServing => 'Open • Serving Customers';

  @override
  String vacctOpenUntil(String time) {
    return 'Open until $time • Serving Customers';
  }

  @override
  String get vacctClosedNote => 'Closed • Not shown in \"open now\" searches';

  @override
  String get vacctAutoCloses =>
      'The stall closes itself after its closing time.';

  @override
  String get vacctChangeHours => 'Change Hours';

  @override
  String get vacctConfig => 'Vendor Configuration';

  @override
  String get vacctEditStall => 'Edit Stall Details';

  @override
  String get vacctEditStallSub => 'Name, category, location pin & cover photo';

  @override
  String get vacctFeatureEditStall => 'Editing your stall details';

  @override
  String get vacctCertificate => 'Hygiene & Inspection Certificate';

  @override
  String get vacctCertificateSub =>
      'View your hygiene score and the latest inspection checklist';

  @override
  String get vacctHelp => 'Vendor Help & Inspector Hotline';

  @override
  String get vacctHelpSub => 'Not available yet';

  @override
  String get vacctFeatureHotline => 'The inspector hotline';

  @override
  String get vacctLogOut => 'Log Out of Vendor Account';

  @override
  String vacctStallId(String code) {
    return 'Stall ID: $code';
  }

  @override
  String vacctAppVersion(String version) {
    return 'App Version $version';
  }

  @override
  String get vacctCover => 'Cover';

  @override
  String get vacctFeatureCover => 'Changing your cover photo';

  @override
  String get vacctEditPhoto => 'Edit stall photo';

  @override
  String get vacctFeatureStallPhoto => 'Changing your stall photo';

  @override
  String get vacctVerifiedCleanVendor => 'Verified Clean Vendor';

  @override
  String get vtOpenTitle => 'Stall is Open 🟢';

  @override
  String get vtClosedTitle => 'Stall is Closed';

  @override
  String get vtOpenBody => 'Customers can see you as open on the map.';

  @override
  String get vtClosedBody => 'Hidden from \"open now\" searches.';

  @override
  String get vtCloseToday => 'Close for Today';

  @override
  String get vtReopen => 'Reopen';

  @override
  String get vdMerchantControl => 'MERCHANT CONTROL';

  @override
  String get vdTitle => 'Stall Dashboard';

  @override
  String get vdCleanVerified => 'Clean & Verified';

  @override
  String vdDeleteItemTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get vdDeleteItemBody =>
      'It disappears from your menu. You can add it again later.';

  @override
  String get vdKeep => 'Keep';

  @override
  String get vdHoursSaved => 'Hours saved.';

  @override
  String get vdClosedToast => 'Closed for now. Tap Reopen to open again.';

  @override
  String get vdOpenTime => 'Open Time';

  @override
  String get vdCloseTime => 'Close Time';

  @override
  String get vdExtendHour => 'Extend 1 Hour';

  @override
  String get vdCloseEarly => 'Close Early';

  @override
  String get vdHoursSavedBtn => 'Hours saved';

  @override
  String get vdSaveHours => 'Save Hours';

  @override
  String vdEarlier(int minutes) {
    return 'Earlier by $minutes minutes';
  }

  @override
  String vdLater(int minutes) {
    return 'Later by $minutes minutes';
  }

  @override
  String get vdDailyMenu => 'Daily Menu';

  @override
  String vdDailyMenuCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Daily Menu ($count Items)',
      one: 'Daily Menu (1 Item)',
    );
    return '$_temp0';
  }

  @override
  String get vdAddItem => 'Add New Item';

  @override
  String get vdMenuEmpty =>
      'Your menu is empty. Add the dishes you are selling today.';

  @override
  String vdEditItemTooltip(String name) {
    return 'Edit $name';
  }

  @override
  String vdDeleteItemTooltip(String name) {
    return 'Delete $name';
  }

  @override
  String get vdPreparedness => 'Daily Preparedness';

  @override
  String get vdFreshOn => 'Fresh Today ON';

  @override
  String get vdFreshOff => 'OFF';

  @override
  String get vdUnavailable => 'Unavailable';

  @override
  String get vdProfileLink => 'Stall Profile & Location';

  @override
  String get vdProfileLinkBody =>
      'Editing your name, categories, location and cover photo is not available in the app yet.';

  @override
  String get vdFeatureEditProfile => 'Editing your stall profile';

  @override
  String get vdEditItemTitle => 'Edit Item';

  @override
  String get vdDishName => 'Dish name';

  @override
  String get vdPrice => 'Price';

  @override
  String get vdErrName => 'Give the dish a name.';

  @override
  String get vdErrPrice => 'Enter a price greater than zero, like 4.50.';

  @override
  String get vanFeedback => 'Recent Stall Feedback';

  @override
  String vanReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Reviews',
      one: '1 Review',
    );
    return '$_temp0';
  }

  @override
  String get vanNoReviews => 'No reviews yet.';

  @override
  String get vanShareBadge => 'Share My Hygiene Badge';

  @override
  String get vanFeatureShareBadge => 'Sharing your hygiene badge';

  @override
  String get vanTitle => 'Vendor Analytics';

  @override
  String get vanLiveStall => 'Live Stall';

  @override
  String get vanClosed => 'Closed';

  @override
  String get vanCurrentScore => 'Current Hygiene Score';

  @override
  String get vanCustomerRating => 'Customer Rating';

  @override
  String get vanNoReviewsSub => 'No reviews yet';

  @override
  String vanReviewCountLower(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get vanStatusLikes => 'Status Likes';

  @override
  String get vanNoLiveStatus => 'No live status';

  @override
  String vanOnStatuses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'On $count live statuses',
      one: 'On 1 live status',
    );
    return '$_temp0';
  }

  @override
  String get vanStatusComments => 'Status Comments';

  @override
  String get vanOnLive => 'On live statuses';

  @override
  String get vanStatusViews => 'Status Views';

  @override
  String get vanNotTracked => 'Not tracked yet';

  @override
  String get vanTrendTitle => 'Hygiene Score Trend';

  @override
  String vanLastInspections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Last $count inspections',
      one: 'Last 1 inspection',
    );
    return '$_temp0';
  }

  @override
  String get vanNoInspections =>
      'No inspections yet. Your scores appear here after an inspector visits.';

  @override
  String vanScoredOne(String score) {
    return 'Scored $score out of 5';
  }

  @override
  String vanScoredRange(String from, String to) {
    return 'From $from to $to out of 5';
  }

  @override
  String vanChartDate(int day, String month) {
    return '$day $month';
  }

  @override
  String get commonSomeone => 'Someone';

  @override
  String get alertsTitle => 'Notifications';

  @override
  String get alertsSubtitle => 'Street kitchen & stall updates';

  @override
  String alertsUnreadCount(int count) {
    return '$count unread';
  }

  @override
  String get alertsMarkAllRead => 'Mark all read';

  @override
  String get alertsCaughtUp => 'You\'re All Caught Up!';

  @override
  String get alertsCaughtUpBody =>
      'Follow stalls you love and their fresh posts will show up here.';

  @override
  String get alertsDiscover => 'Discover Nearby Stalls';

  @override
  String get alertsFilterAll => 'All';

  @override
  String get alertsFilterStalls => 'Stalls You Follow';

  @override
  String get alertsFilterCommunity => 'Community';

  @override
  String get alertTypeStallUpdate => 'Stall Update';

  @override
  String get alertTypeComment => 'New Comment';

  @override
  String get alertTypeLike => 'New Like';

  @override
  String get alertTypeFriendRequest => 'Friend Request';

  @override
  String get alertTypeNewFriend => 'New Friend';

  @override
  String get alertTypeHygieneUpdate => 'Hygiene Update';

  @override
  String get alertTypeRecheck => 'Re-check Due';

  @override
  String get alertTypeNewReview => 'New Review';

  @override
  String get alertTypeOther => 'Notification';

  @override
  String alertScoreWas(String score) {
    return 'was $score';
  }

  @override
  String get vaTitle => 'Stall Notifications';

  @override
  String get vaSubtitle => 'Reviews, hygiene scores & customer buzz';

  @override
  String get vaVendorView => 'Vendor View';

  @override
  String get vaFilterAll => 'All';

  @override
  String get vaFilterReviews => 'Customer Reviews';

  @override
  String get vaFilterHygiene => 'Hygiene Alerts';

  @override
  String get vaFilterBuzz => 'Status Buzz';

  @override
  String get vaNone => 'No notifications yet.';

  @override
  String get vaNothingForFilter => 'Nothing here for this filter.';

  @override
  String get vaSeeReviews => 'See Reviews';

  @override
  String get vaReplyUnavailable => 'Reply to Review (not available yet)';

  @override
  String get vaViewHygiene => 'View Hygiene Report';

  @override
  String get vaViewReply => 'View & Reply';

  @override
  String get vaViewStatus => 'View Status';

  @override
  String get profLiveStatuses => 'Your Live Statuses';

  @override
  String get profCreateStatus => 'Create New Status';

  @override
  String get profSettingsNetwork => 'Settings & Network';

  @override
  String get profFriendsNetwork => 'My Friends & Foodie Network';

  @override
  String profConnected(int count) {
    return '$count Connected';
  }

  @override
  String get profFriendsSub => 'Add and manage your foodie friends';

  @override
  String get profHistory => 'My Status History & Vault';

  @override
  String get profHistorySub => 'Your past statuses, live or expired';

  @override
  String get profHelp => 'Help & Food Safety Support';

  @override
  String get profHelpSub => 'Not available yet';

  @override
  String get profFeatureHelp => 'Help and food safety support';

  @override
  String get profLogOut => 'Log Out';

  @override
  String get profEditPhoto => 'Edit photo (not available yet)';

  @override
  String get profFeaturePhoto => 'Changing your photo';

  @override
  String get profStatStatuses => 'Statuses Shared';

  @override
  String get profStatFriends => 'Foodie Friends';

  @override
  String get profStatLive => 'Live Now';

  @override
  String get shTitle => 'Status History & Vault';

  @override
  String get shEmpty =>
      'You have not posted a status yet. Share what you are eating from your profile.';

  @override
  String get shLive => 'Live';

  @override
  String get shArchived => 'Archived';

  @override
  String get shHidden => 'Hidden';

  @override
  String get frTitle => 'Foodie Network';

  @override
  String get frTabAdd => 'Add Friend';

  @override
  String get frTabRequests => 'Requests';

  @override
  String get frTabFriends => 'My Friends';

  @override
  String get frFindTitle => 'Find a foodie';

  @override
  String get frFindSub =>
      'Type their exact username. There is no search by name or phone.';

  @override
  String get frUsernameHint => '@username';

  @override
  String get frFind => 'Find';

  @override
  String frNoUser(String username) {
    return 'No customer with the username @$username. Usernames must match exactly.';
  }

  @override
  String frRequestSent(String name) {
    return 'Request sent to $name.';
  }

  @override
  String frNowFriends(String name) {
    return 'You are now friends with $name.';
  }

  @override
  String get frDeclined => 'Request declined.';

  @override
  String frRemoved(String name) {
    return '$name was removed from your friends.';
  }

  @override
  String get frAdd => 'Add';

  @override
  String get frNoRequests => 'No friend requests waiting for you.';

  @override
  String get frActiveFriends => 'Active Friends';

  @override
  String get frNoFriends =>
      'No friends yet. Find someone by username in the Add tab.';

  @override
  String get frAccept => 'Accept';

  @override
  String get frDecline => 'Decline';

  @override
  String frFriendsSince(String ago) {
    return 'Friends · $ago';
  }

  @override
  String get frRemoveFriend => 'Remove friend';

  @override
  String get frMoreOptions => 'More options';

  @override
  String get frTipTitle => 'Foodie Network Tip';

  @override
  String get frTipBody =>
      'Friends see your Friends Only statuses, and you see theirs in your Daily Fresh Stories.';

  @override
  String get csTitle => 'New Status';

  @override
  String get csDiscardTitle => 'Discard this status?';

  @override
  String get csDiscardBody => 'Your photo and caption will be lost.';

  @override
  String get csKeepEditing => 'Keep editing';

  @override
  String get csDiscard => 'Discard';

  @override
  String get csPosted => 'Status posted! It stays on the radar for 24 hours.';

  @override
  String get csTapPhoto => 'Tap to add today\'s fresh photo';

  @override
  String get csCameraOrGallery => 'Camera or gallery';

  @override
  String get csChooseDifferent => 'Choose a different image';

  @override
  String get csCaptionTitle => 'Your Taste Review & Street Note';

  @override
  String get csCaptionHint =>
      'What is fresh and hot right now? Tell people what to try...';

  @override
  String csInsertEmoji(String emoji) {
    return 'Insert $emoji';
  }

  @override
  String get csFoodStall => 'FOOD STALL';

  @override
  String csPostingAs(Object name) {
    return 'Posting as $name';
  }

  @override
  String get csTagStall => 'Tag a stall';

  @override
  String get csChange => 'Change';

  @override
  String get csNoStallTagged => 'No stall tagged';

  @override
  String get csTagOptional => 'Optional: tag the stall in your photo';

  @override
  String get csNoNearbyStalls => 'No nearby stalls to tag yet.';

  @override
  String get csWhere => 'WHERE (OPTIONAL)';

  @override
  String get csWhereHint => 'e.g. Near the main gate';

  @override
  String get csWhereHelper => 'Shown with your status as plain text';

  @override
  String get csAudience => 'Audience Visibility';

  @override
  String get csWhoSees => 'Who sees this?';

  @override
  String csPublic(String brand) {
    return 'Public ($brand)';
  }

  @override
  String get csFriendsOnly => 'Friends Only';

  @override
  String get csAlwaysPublic => 'Stall statuses are always public.';

  @override
  String get csPost => 'Post Status 🚀';

  @override
  String get csNeedContent => 'Add a photo or a caption to post.';

  @override
  String get csExpiryNotice =>
      'Your status is visible for 24 hours on the Fresh Stories radar, then it expires and moves to your history.';

  @override
  String get sdPublic => 'Public';

  @override
  String sdLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Likes',
      one: '1 Like',
    );
    return '$_temp0';
  }

  @override
  String get sdLikeLabel => 'Like';

  @override
  String get sdDeleteStatus => 'Delete Status';

  @override
  String get sdViewStall => 'View Stall';

  @override
  String get sdDeleteTitle => 'Delete this status?';

  @override
  String get sdDeleteBody =>
      'It disappears from the radar, along with its likes and comments.';

  @override
  String get sdKeep => 'Keep';

  @override
  String get sdDelete => 'Delete';

  @override
  String sdComments(int count) {
    return 'Comments ($count)';
  }

  @override
  String get sdNoComments => 'No comments yet. Be the first to say something.';

  @override
  String get sdReplyHint => 'Reply to your comments...';

  @override
  String sdCommentHint(String name) {
    return 'Add a comment for $name...';
  }

  @override
  String get sdReact1 => '🔥 Sizzling';

  @override
  String get sdReact2 => '🤤 Craving';

  @override
  String get sdReact3 => '👏 Master Chef';

  @override
  String get commonView => 'View';

  @override
  String get reviewAnonymous => 'Anonymous customer';

  @override
  String get dayMonday => 'Monday';

  @override
  String get dayTuesday => 'Tuesday';

  @override
  String get dayWednesday => 'Wednesday';

  @override
  String get dayThursday => 'Thursday';

  @override
  String get dayFriday => 'Friday';

  @override
  String get daySaturday => 'Saturday';

  @override
  String get daySunday => 'Sunday';

  @override
  String get dayShortMon => 'Mon';

  @override
  String get dayShortTue => 'Tue';

  @override
  String get dayShortWed => 'Wed';

  @override
  String get dayShortThu => 'Thu';

  @override
  String get dayShortFri => 'Fri';

  @override
  String get dayShortSat => 'Sat';

  @override
  String get dayShortSun => 'Sun';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String vpFollowing(String name) {
    return 'Following $name.';
  }

  @override
  String vpUnfollowed(String name) {
    return 'Stopped following $name.';
  }

  @override
  String get vpFollow => 'Follow stall';

  @override
  String get vpUnfollow => 'Unfollow stall';

  @override
  String vpInspected(String ago) {
    return 'Inspected $ago';
  }

  @override
  String get vpShare => 'Share';

  @override
  String get vpFeatureSharing => 'Sharing';

  @override
  String get vpCall => 'Call';

  @override
  String get vpFeatureCalling => 'Calling the stall';

  @override
  String vpDirectionsDistance(String distance) {
    return 'Directions ($distance)';
  }

  @override
  String get vpTabOverview => 'Overview';

  @override
  String get vpTabHygiene => 'Hygiene Breakdown';

  @override
  String vpTabReviews(int count) {
    return 'Reviews ($count)';
  }

  @override
  String vpGrade(String grade) {
    return '$grade Grade';
  }

  @override
  String get vpGradeNone => 'Not yet';

  @override
  String get vpGradeNeedsWork => 'Needs work';

  @override
  String get vpWaterVerified => 'Verified';

  @override
  String get vpWaterUnverified => 'Unverified';

  @override
  String get vpMetricFoodSafety => 'Food Safety';

  @override
  String get vpMetricWater => 'Water Source';

  @override
  String get vpMetricReview => 'Review';

  @override
  String get vpMetricReviews => 'Reviews';

  @override
  String vpAbout(String name) {
    return 'About $name';
  }

  @override
  String get vpNoDescription => 'The vendor has not added a description yet.';

  @override
  String get vpMenu => 'Menu';

  @override
  String get vpNoMenu => 'This stall has not added its menu yet.';

  @override
  String get vpLeaveReview => 'Leave a Review & Photo 📸';

  @override
  String get vpOperatingHours => 'Operating Hours';

  @override
  String get vpHoursNotSet => 'Hours not set';

  @override
  String vpHoursOpenNow(String hours) {
    return '$hours (Open now)';
  }

  @override
  String vpHoursClosedNow(String hours) {
    return '$hours (Closed now)';
  }

  @override
  String get vpClosed => 'Closed';

  @override
  String get vpSoldOut => 'Sold out';

  @override
  String get vpFreshToday => 'Fresh today';

  @override
  String get vpAuditStatus => 'AUDIT STATUS';

  @override
  String vpLastInspected(String ago) {
    return 'Last inspected $ago';
  }

  @override
  String get vpRecheckDue => 'Re-check due now';

  @override
  String vpRecheckIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Re-check in $days days',
      one: 'Re-check in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get vpInspectingOrg => 'Inspecting organisation';

  @override
  String get vpNoInspection =>
      'No inspection on record yet. The checklist appears here after a municipal inspector visits this stall.';

  @override
  String get vpChecklistTitle => '5-Point Checklist';

  @override
  String get vpMunicipalStandard => 'Municipal Standard';

  @override
  String get vpResultPartial => 'Partly Met';

  @override
  String get vpResultFail => 'Needs Improvement';

  @override
  String get vpInspectorNotes => 'Inspector\'s notes';

  @override
  String get vpEvidencePhoto => 'Inspection evidence photo';

  @override
  String get vpViewArrow => 'View >';

  @override
  String vpReadReviews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Read what $count customers say',
      one: 'Read what 1 customer says',
      zero: 'No customer reviews yet',
    );
    return '$_temp0';
  }

  @override
  String get vpReviewsArrow => 'Reviews >';

  @override
  String get vpHygieneFooter =>
      'Hygiene scores come from official inspections and are re-verified periodically.';

  @override
  String get criterionWaterTitle => 'Water Source';

  @override
  String get criterionWaterDesc =>
      'Clean, running water for washing and cooking';

  @override
  String get criterionUtensilTitle => 'Utensil & Glove Hygiene';

  @override
  String get criterionUtensilDesc =>
      'Utensils kept clean; gloves or tongs used on food';

  @override
  String get criterionWasteTitle => 'Waste Disposal';

  @override
  String get criterionWasteDesc => 'Covered bins, emptied regularly';

  @override
  String get criterionCoveringTitle => 'Food Covering';

  @override
  String get criterionCoveringDesc => 'Prepared and raw food kept covered';

  @override
  String get criterionCleanTitle => 'Overall Stall Cleanliness';

  @override
  String get criterionCleanDesc => 'The stall and its surroundings are clean';

  @override
  String get reviewFilterAll => 'All';

  @override
  String get reviewFilterPhotos => 'With Photos';

  @override
  String get reviewsNone =>
      'No reviews yet. Be the first to share what you saw.';

  @override
  String get reviewsNonePhotos => 'No reviews with photos yet.';

  @override
  String get reviewsLoadMore => 'Load more reviews';

  @override
  String get reviewsCaughtUp => 'You\'re all caught up';

  @override
  String reviewsBasedOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Based on $count reviews',
      one: 'Based on 1 review',
      zero: 'No reviews yet',
    );
    return '$_temp0';
  }

  @override
  String get reviewReadMore => 'Read more';

  @override
  String get reviewShowLess => 'Show less';

  @override
  String get observationCleanArea => 'Clean Cooking Surface';

  @override
  String get observationGlovesWorn => 'Gloves Worn';

  @override
  String get observationCoveredFood => 'Food Kept Covered';

  @override
  String get observationCleanWater => 'Clean Filtered Water';

  @override
  String get observationCoveredBin => 'Covered Dustbin';

  @override
  String get observationUncleanArea => 'Unclean Area';

  @override
  String get observationNoGloves => 'No Gloves';

  @override
  String get observationUncoveredFood => 'Uncovered Food';

  @override
  String get observationNoWater => 'No Running Water';

  @override
  String get observationOverflowingWaste => 'Overflowing Waste';

  @override
  String get ruTitle => 'Leave a Review';

  @override
  String ruStallSubtitle(String name, String number) {
    return '$name ($number)';
  }

  @override
  String get ruTapPhoto => 'Tap to add a photo of your meal';

  @override
  String get ruPhotoOptional => 'Optional, but verified photos help others';

  @override
  String get ruRetake => 'Retake';

  @override
  String get ruPhotoAdded => 'Photo added';

  @override
  String ruToday(String time) {
    return 'Today, $time';
  }

  @override
  String get ruPhotoHelp =>
      'Photos help other customers. The server records when yours arrives.';

  @override
  String get ruOverall => 'Overall Experience';

  @override
  String get ruRatingNone => 'Tap a star to rate';

  @override
  String get ruRating1 => 'Poor (1.0)';

  @override
  String get ruRating2 => 'Below Average (2.0)';

  @override
  String get ruRating3 => 'Average (3.0)';

  @override
  String get ruRating4 => 'Good (4.0)';

  @override
  String get ruRating5 => 'Excellent Hygiene & Taste (5.0)';

  @override
  String ruStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get ruObservationsTitle => 'Hygiene Observation Checks';

  @override
  String get ruTapToToggle => 'Tap to toggle';

  @override
  String get ruObservationsHelp =>
      'Select all sanitary practices observed at the food cart during your meal.';

  @override
  String get ruFeedbackTitle => 'Detailed Feedback';

  @override
  String get ruFeedbackHint =>
      'Describe the food taste, stall cleanliness, cooking hygiene and wait time...';

  @override
  String get ruAnonymous => 'Post anonymously';

  @override
  String get ruCommunityTitle => 'Community-Powered Safety';

  @override
  String get ruCommunityBody =>
      'Your review and photo help other customers choose clean stalls, and show vendors where they can improve. Reviews are public unless you post anonymously.';

  @override
  String get ruSubmit => 'Submit Review';

  @override
  String ruThanks(String stall) {
    return 'Thanks! Your review of $stall was submitted.';
  }

  @override
  String statusTimeLeftHM(int hours, int minutes) {
    return '${hours}h ${minutes}m left';
  }

  @override
  String statusTimeLeftM(int minutes) {
    return '${minutes}m left';
  }

  @override
  String get statusExpired => 'Expired';

  @override
  String statusExpiresInH(int hours) {
    return 'Expires in ${hours}h';
  }

  @override
  String statusExpiresInM(int minutes) {
    return 'Expires in ${minutes}m';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get navProfile => 'Profile';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonAlerts => 'Alerts';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonClose => 'Close';

  @override
  String get commonCamera => 'Camera';

  @override
  String get commonGallery => 'Gallery';

  @override
  String get commonDirections => 'Directions';

  @override
  String commonDistanceKm(String value) {
    return '$value km';
  }

  @override
  String stallNumber(int number) {
    return 'Stall #$number';
  }

  @override
  String stallDistanceAway(String distance) {
    return '$distance away';
  }

  @override
  String get stallOpenNow => 'Open now';

  @override
  String stallOpenUntil(String time) {
    return 'Open until $time';
  }

  @override
  String get stallOpenNowCap => 'Open Now';

  @override
  String stallOpenNowUntil(String time) {
    return 'Open Now until $time';
  }

  @override
  String get stallClosedNow => 'Closed now';

  @override
  String get stallRatingNew => 'New';

  @override
  String get stallClean => 'Clean';

  @override
  String get stallCaution => 'Caution';

  @override
  String stallCleanPercent(int percent) {
    return '$percent% Clean';
  }

  @override
  String stallWalkMinutes(int minutes) {
    return 'Directions ($minutes min)';
  }

  @override
  String get stallViewMenu => 'View Menu';

  @override
  String get stallOrderPickup => 'Order Pick-up →';

  @override
  String get stallFeaturePickup => 'Pick-up orders';

  @override
  String get hygieneVerifiedClean => 'Verified Clean';

  @override
  String get hygieneHigh => 'High Hygiene';

  @override
  String get hygieneNeedsRecheck => 'Needs re-check';

  @override
  String get hygieneNotInspected => 'Not yet inspected';

  @override
  String get hygieneReverificationPending => 'Re-verification Pending';

  @override
  String get timeAm => 'AM';

  @override
  String get timePm => 'PM';

  @override
  String get searchCenterCurrent => 'Current location';

  @override
  String get searchCenterDefault => 'Colombo (default area)';

  @override
  String get homeCurrentSpot => 'CURRENT SPOT';

  @override
  String get homeStoriesTitle => 'Daily Fresh Stories';

  @override
  String get homeStoriesCycle => '24h cycle';

  @override
  String get homeStoriesCycleHint =>
      'Stories disappear 24 hours after they are posted.';

  @override
  String get homeNoStories =>
      'No stories right now. Statuses from stalls you follow and your friends show up here.';

  @override
  String homeStoryTimeLeft(int hours) {
    return '${hours}h left';
  }

  @override
  String get homeRadarTitle => 'Live Hygiene Radar';

  @override
  String get homeOpenMap => 'Open map';

  @override
  String get homeNoStallsNearby =>
      'No stalls found within 25 km of this spot yet.';

  @override
  String homeRadarStallsNearby(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stalls nearby',
      one: '1 stall nearby',
    );
    return '$_temp0';
  }

  @override
  String get homeForYou => 'For You';

  @override
  String get homeFilterCategory => 'Filter Category';

  @override
  String get homeAll => 'All';

  @override
  String get homeBestRated => 'Best Rating Vendor Shop';

  @override
  String get homeBestRatedSub => 'Highest customer star ratings';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeNoRatings => 'No ratings yet. Be the first to review a stall.';

  @override
  String get homeShopsNear => 'Shops Near You';

  @override
  String homeSortedByProximity(String place) {
    return 'Sorted by proximity to $place';
  }

  @override
  String get homeSortedByRating => 'Sorted by rating';

  @override
  String get homeNearbyToggle => 'Nearby';

  @override
  String get homeSortByNearby => 'Sort by nearby';

  @override
  String get homeNoMatch =>
      'No stalls match your filters. Widen the radius or clear a category.';

  @override
  String get mapFinding => 'Finding stalls…';

  @override
  String mapOpenStallsNearby(int count) {
    return '$count Open Stalls Nearby';
  }

  @override
  String get mapSearchHint => 'Search kottu, hoppers, juice...';

  @override
  String get mapLayers => 'Map layers';

  @override
  String get mapUseMyLocation => 'Use my current location';

  @override
  String get mapFilters => 'Filters';

  @override
  String get mapNearbyStalls => 'Nearby Stalls';

  @override
  String get mapSortedByDistance => 'Sorted by distance';

  @override
  String get mapListView => 'List View';

  @override
  String get mapNoMatch =>
      'No stalls match. Try another search or adjust your filters.';

  @override
  String get splitLiveRadar => 'LIVE RADAR';

  @override
  String splitShowing(int count, String radius) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Showing $count stalls within $radius',
      one: 'Showing 1 stall within $radius',
    );
    return '$_temp0';
  }

  @override
  String get splitStallsTitle => 'Stalls';

  @override
  String splitStallsCount(int count) {
    return '$count Stalls';
  }

  @override
  String splitHighHygieneCount(int count) {
    return '$count High Hygiene Stalls';
  }

  @override
  String get splitDetailedCards => 'Detailed cards';

  @override
  String get splitCompactCards => 'Compact cards';

  @override
  String get splitSort => 'Sort';

  @override
  String get splitSortDistance => 'Distance';

  @override
  String get splitSortRating => 'Rating';

  @override
  String get splitNoMatch =>
      'No stalls match these filters. Try widening the radius or turning off High Hygiene.';

  @override
  String get searchHint => 'Search stalls, dishes, categories';

  @override
  String get searchEmptyHint =>
      'Search for a stall, a dish or a category like kottu or hoppers.';

  @override
  String get searchRecent => 'Recent Searches';

  @override
  String searchResultsCount(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results for “$query”',
      one: '1 result for “$query”',
    );
    return '$_temp0';
  }

  @override
  String searchNoResultsTitle(String query) {
    return 'No results for “$query”';
  }

  @override
  String get searchNoResultsBody =>
      'Try a different word, or adjust your filters: the radius and hygiene filters may be hiding stalls.';

  @override
  String get searchAdjustFilters => 'Adjust filters';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get filtersReset => 'Reset';

  @override
  String get filtersClearAll => 'Clear All';

  @override
  String get filtersApply => 'Apply Filters';

  @override
  String get filtersNoMatch => 'No stalls match';

  @override
  String filtersShowResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count Results',
      one: 'Show 1 Result',
    );
    return '$_temp0';
  }

  @override
  String get filtersSearchRadius => 'Search Radius';

  @override
  String get filtersHygieneRating => 'Hygiene Rating';

  @override
  String get filtersAll => 'All';

  @override
  String get filtersHighOnly => 'High Hygiene Only';

  @override
  String get filtersFoodCategory => 'Food Category';

  @override
  String get filtersOpenNow => 'Open Now';

  @override
  String get filtersOpenNowSub => 'Only stalls serving right now';

  @override
  String get commonBack => 'Back';

  @override
  String get commonHelp => 'Help';

  @override
  String get commonShowPassword => 'Show password';

  @override
  String get commonHidePassword => 'Hide password';

  @override
  String commonStepOf(int current, int total) {
    return 'STEP $current OF $total';
  }

  @override
  String get authRoleLiveProtocol => 'Live Street Hygiene Protocol';

  @override
  String get authRoleVerified => 'Verified';

  @override
  String get authRoleTagline =>
      'Discover Hygienic Street Food & Support Local Stalls';

  @override
  String get authRoleSyncing => 'Syncing neighborhood stalls...';

  @override
  String get authTipHeading => 'DAILY VENDOR STANDARD';

  @override
  String get authTip1 =>
      'Tip: Look for a covered waste bin — it\'s one of our top hygiene checks!';

  @override
  String get authTip2 =>
      'Tip: Vendors who change gloves between orders score higher on hygiene.';

  @override
  String get authTip3 =>
      'Tip: Clean, running water at the stall is checked on every inspection.';

  @override
  String get authTip4 =>
      'Tip: Food covered from dust and flies is a sign of a well-run stall.';

  @override
  String get authRoleChoose => 'Choose your role to continue';

  @override
  String get authRoleCustomerTitle => 'I\'m a Customer';

  @override
  String get authRolePopular => 'Popular';

  @override
  String get authRoleCustomerSubtitle =>
      'Find clean, delicious street food nearby & see live vendor updates';

  @override
  String get authRoleTagGps => 'GPS discovery';

  @override
  String get authRoleTagCleanScore => 'Clean score verified';

  @override
  String get authRoleVendorTitle => 'I\'m a Vendor';

  @override
  String get authRoleCommission => '0% Comm.';

  @override
  String get authRoleVendorSubtitle =>
      'List your food stall immediately with no wait & reach daily eaters';

  @override
  String get authRoleTagOnboarding => 'Instant 3-min onboarding';

  @override
  String get authRoleTagCertified => 'Get clean certified';

  @override
  String get authRoleDisclaimer =>
      'By selecting, you accept standard market safety guidelines';

  @override
  String get authFieldEmailOrMobile => 'Email or Mobile Number';

  @override
  String get authHintEmailOrMobile => 'e.g. +94 77 123 4567 or name@email.com';

  @override
  String get authHintEmailOrMobileShort => 'name@example.com or +1 (555) 000';

  @override
  String get authHintEmailOrMobileLong => 'name@example.com or +94 77 123 4567';

  @override
  String get authFieldPassword => 'Password';

  @override
  String get authHintPassword => 'Enter your password';

  @override
  String get authHintPasswordMin => 'At least 8 characters';

  @override
  String get authFieldConfirmPassword => 'Confirm Password';

  @override
  String get authHintConfirmPassword => 'Re-enter your password';

  @override
  String get authFieldFullName => 'Full Name';

  @override
  String get authHintFullName => 'Your full name';

  @override
  String get authForgotPassword => 'Forgot Password?';

  @override
  String get authFeaturePasswordReset => 'Password reset';

  @override
  String get authLogIn => 'Log In';

  @override
  String get authOrContinueWith => 'or continue with';

  @override
  String get authOrSignUpWith => 'or sign up with';

  @override
  String get authGoogleContinue => 'Continue with Google';

  @override
  String get authFeatureGoogle => 'Google sign-in';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authSignUp => 'Sign Up';

  @override
  String get authVendorPortal => 'Vendor Portal';

  @override
  String get authAreYouVendor => 'Are you a food vendor?';

  @override
  String get authConsumerLoginBadge => 'Verified Safe Street Food Network';

  @override
  String get authConsumerLoginTitle => 'Welcome Back, Foodie 👋';

  @override
  String get authConsumerLoginSubtitle =>
      'Log in to find verified hygienic street food near you';

  @override
  String get authTermsRequired =>
      'You must accept the terms to create an account.';

  @override
  String get authSignupFreeBadge => '100% Free for food seekers';

  @override
  String get authCreateAccount => 'Create Account';

  @override
  String get authSignupSubtitle =>
      'Join to discover certified hygienic street food stalls and track live fresh preparations';

  @override
  String get authAgreePre => 'I agree to the ';

  @override
  String get authAgreeTerms => 'Terms of Service';

  @override
  String get authAgreeAnd => ' & ';

  @override
  String get authAgreeGuidelines => 'Food Safety Community Guidelines';

  @override
  String get authAgreePost => '';

  @override
  String get authCertifiedTitle => 'Municipal Health Certified';

  @override
  String get authCertifiedBody =>
      'Live oil purity ratings, inspection stamps & daily sanitization logs.';

  @override
  String get authAlreadyAccount => 'Already have an account?';

  @override
  String get authLogInArrow => 'Log In >';

  @override
  String get authVendorEyebrow => 'Merchant Access';

  @override
  String get authVendorLoginTitle => 'Vendor Sign In 🏪';

  @override
  String get authVendorLoginSubtitle =>
      'Manage your stall, post daily stories & view live customer reviews.';

  @override
  String get authTrustCard => 'Direct stall management — no admin middleman';

  @override
  String get authFieldOwnerContact => 'Stall Owner Mobile or Email';

  @override
  String get authHintOwnerContact => '+1 (555) 000-0000 or email';

  @override
  String get authFieldVendorPassword => 'Password or Security PIN';

  @override
  String get authHintVendorPassword => 'Enter vendor password';

  @override
  String get authStaySignedIn => 'Stay signed in';

  @override
  String get authForgotVendorPin => 'Forgot Vendor PIN / Password?';

  @override
  String get authVendorLogIn => 'Log In to Vendor Portal';

  @override
  String get authSendOtp => 'Send One-Time Passcode via SMS';

  @override
  String get authFeatureSmsOtp => 'SMS one-time passcodes';

  @override
  String get authNewStallOwner => 'New stall owner?';

  @override
  String get authCreateVendorAccount => 'Create Vendor Account';

  @override
  String get authAreYouCustomer => 'Are you a customer?';

  @override
  String get authSwitchToCustomerLogin => 'Switch to Customer Login';

  @override
  String get authFooterPrivacy => 'Privacy Policy';

  @override
  String get authFooterGuidelines => 'Vendor Guidelines';

  @override
  String get authFooterEmergency => 'Emergency Support';

  @override
  String get authVendorRegistration => 'Vendor Registration';

  @override
  String get authPartner => 'Partner';

  @override
  String get authVendorSignupSubtitle =>
      'Register your street kitchen or food cart to reach verified diners and broadcast daily fresh statuses.';

  @override
  String get authOwnerFullName => 'Owner Full Name';

  @override
  String get authSmsReady => 'SMS Ready';

  @override
  String get authAgreeVendorLink => 'Vendor Merchant Standards';

  @override
  String authAgreeVendorPost(String brand) {
    return ', Municipal Hygiene Protocol guidelines, and $brand Community Terms.';
  }

  @override
  String get authLookingToOrder => 'Looking to order food?';

  @override
  String get authSwitchToConsumerSignup => 'Switch to Consumer Sign-Up';

  @override
  String get authNextStep => 'Next Step: Stall Onboarding';

  @override
  String get authNextStepTime => '~2 mins';

  @override
  String get authNextStepBody =>
      'Register stall location, food craft specialties, and upload your hygiene certification badge.';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String commonComingSoon(String feature) {
    return '$feature is coming soon.';
  }

  @override
  String get commonSoon => 'Soon';

  @override
  String errorOffline(String brand) {
    return 'Can\'t reach $brand. Check your connection and try again.';
  }

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorUnreadable =>
      'The server\'s reply could not be read. Please try again, and if it keeps happening check the backend.';

  @override
  String get errorTooManyAttempts =>
      'Too many attempts. Please wait a minute and try again.';

  @override
  String get errorServer =>
      'Something went wrong on our side. Please try again shortly.';

  @override
  String get errorUnexpectedResponse =>
      'The server sent an unexpected response. Please try again.';

  @override
  String get errorSignInAgain => 'Please sign in again.';

  @override
  String get errorNoStall => 'You have not set up a stall yet.';

  @override
  String errorAccountNotSupported(String brand) {
    return 'This account can\'t be used in the $brand app.';
  }

  @override
  String get errorSessionNotSaved =>
      'Couldn\'t save your session securely on this device.';

  @override
  String get vendorSetUpMyStall => 'Set up my stall';

  @override
  String validationRequired(String label) {
    return '$label is required.';
  }

  @override
  String get validationLabelFullName => 'Full name';

  @override
  String get validationLabelEmailOrMobile => 'Email or mobile number';

  @override
  String get validationLabelPassword => 'Password';

  @override
  String get validationLabelConfirmPassword => 'Confirm password';

  @override
  String get validationInvalidEmail => 'Enter a valid email address.';

  @override
  String get validationInvalidEmailOrMobile =>
      'Enter a valid email address or mobile number.';

  @override
  String validationPasswordTooShort(int count) {
    return 'Use at least $count characters.';
  }

  @override
  String get validationPasswordsMismatch => 'Passwords do not match.';

  @override
  String get locationServicesOff =>
      'Location is switched off on this phone. Turn it on and try again.';

  @override
  String get locationDenied =>
      'Location permission was denied. Allow it to pin your stall, then try again.';

  @override
  String locationDeniedForever(String brand) {
    return 'Location permission is blocked. Allow it for $brand in Settings.';
  }

  @override
  String get locationUnavailable =>
      'Couldn\'t get your location. Move to an open area and try again.';

  @override
  String photoCameraBlocked(String brand) {
    return 'Camera access is blocked. Allow it for $brand in Settings, or choose from your gallery.';
  }

  @override
  String get photoCameraFailed =>
      'Couldn\'t open the camera. Try the gallery instead.';

  @override
  String photoGalleryBlocked(String brand) {
    return 'Photo access is blocked. Allow it for $brand in Settings.';
  }

  @override
  String get photoGalleryFailed =>
      'Couldn\'t open your gallery. Try the camera instead.';

  @override
  String get agoJustNow => 'Just now';

  @override
  String agoMinutes(int count) {
    return '$count min ago';
  }

  @override
  String agoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String agoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String agoWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String get appTitle => 'StreetBite';
}
