import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show TimeOfDay, DayPeriod;

import '../../../../core/localization/l10n.dart';

/// `17:00`: the 24-hour `H:i` format the API wants.
String formatApiTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

/// `5:00 PM`: how times are shown on screen.
String formatTime12(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final period = time.period == DayPeriod.am ? l10n.timeAm : l10n.timePm;

  return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
}

/// Everything the vendor has entered on the "Add Food Stall" screen, as an
/// immutable value. The screen replaces it on every change; validation and the
/// request body are built from it here, so they can be tested without a UI.
///
/// Error keys are the screen's field names: `name`, `categories`, `location`,
/// `opens_at`, `closes_at`, `open_days`, `cover_photo`, `description`.
class OnboardingDraft {
  const OnboardingDraft({
    this.name = '',
    this.description = '',
    this.categories = const {},
    this.latitude,
    this.longitude,
    this.landmark = '',
    this.opensAt,
    this.closesAt,
    this.openEveryDay = true,
    this.openDays = const {},
    this.photoPath,
  });

  static const int maxName = 120;
  static const int maxDescription = 200;
  static const int maxLandmark = 255;

  /// The error keys the screen has a place to show. Anything else from the
  /// server goes in the banner.
  static const Set<String> errorKeys = {
    'name',
    'categories',
    'location',
    'opens_at',
    'closes_at',
    'open_days',
    'cover_photo',
    'description',
  };

  final String name;
  final String description;

  /// Category slugs, in the order they were picked.
  final Set<String> categories;
  final double? latitude;
  final double? longitude;

  /// What the vendor calls the pinned spot. Optional; coordinates are what count.
  final String landmark;
  final TimeOfDay? opensAt;
  final TimeOfDay? closesAt;

  /// On means every day; the API is then sent no `open_days` at all.
  final bool openEveryDay;

  /// ISO days, 1 (Monday) to 7 (Sunday). Only used when [openEveryDay] is off.
  final Set<int> openDays;

  /// Path of the picked image file on the device.
  final String? photoPath;

  bool get hasLocation => latitude != null && longitude != null;

  OnboardingDraft copyWith({
    String? name,
    String? description,
    Set<String>? categories,
    double? latitude,
    double? longitude,
    String? landmark,
    TimeOfDay? opensAt,
    TimeOfDay? closesAt,
    bool? openEveryDay,
    Set<int>? openDays,
    String? photoPath,
  }) {
    return OnboardingDraft(
      name: name ?? this.name,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      landmark: landmark ?? this.landmark,
      opensAt: opensAt ?? this.opensAt,
      closesAt: closesAt ?? this.closesAt,
      openEveryDay: openEveryDay ?? this.openEveryDay,
      openDays: openDays ?? this.openDays,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  /// Picks the category, or drops it if it was already picked.
  OnboardingDraft toggleCategory(String slug) {
    final next = Set<String>.of(categories);

    if (!next.remove(slug)) next.add(slug);

    return copyWith(categories: next);
  }

  /// Picks the weekday (1 to 7), or drops it if it was already picked.
  OnboardingDraft toggleDay(int day) {
    final next = Set<int>.of(openDays);

    if (!next.remove(day)) next.add(day);

    return copyWith(openDays: next);
  }

  /// What is missing or wrong, by field; empty when the form can be sent. These
  /// are the backend's rules (StoreVendorRequest) checked before a request is
  /// made. The server still has the final word.
  Map<String, String> validate() {
    final errors = <String, String>{};
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      errors['name'] = l10n.obErrNameRequired;
    } else if (trimmedName.length > maxName) {
      errors['name'] = l10n.obErrNameLong(maxName);
    }

    if (categories.isEmpty) {
      errors['categories'] = l10n.obErrCategories;
    }

    if (!hasLocation) {
      errors['location'] = l10n.obErrLocation;
    }

    if (opensAt == null) errors['opens_at'] = l10n.obErrOpens;

    if (closesAt == null) {
      errors['closes_at'] = l10n.obErrCloses;
    } else if (opensAt != null && opensAt == closesAt) {
      errors['closes_at'] = l10n.obErrCloseDiffer;
    }

    if (!openEveryDay && openDays.isEmpty) {
      errors['open_days'] = l10n.obErrDays;
    }

    if (photoPath == null) errors['cover_photo'] = l10n.obErrPhoto;

    if (description.length > maxDescription) {
      errors['description'] = l10n.obErrDescLong(maxDescription);
    }

    return errors;
  }

  /// The multipart body for `POST /vendors`.
  ///
  /// Arrays use bracketed names sent once per value (`categories[]`), which is
  /// what PHP reads as a list. The photo goes in `cover_photo`. Optional fields
  /// that are empty are left out. Call [validate] first; an incomplete draft
  /// throws.
  FormData toFormData(MultipartFile photo) {
    final latitude = this.latitude;
    final longitude = this.longitude;
    final opensAt = this.opensAt;
    final closesAt = this.closesAt;

    if (latitude == null || longitude == null || opensAt == null || closesAt == null) {
      throw StateError('The draft is incomplete; validate() it before building the request.');
    }

    final form = FormData();

    void add(String key, String value) => form.fields.add(MapEntry(key, value));

    add('name', name.trim());
    if (description.trim().isNotEmpty) add('description', description.trim());
    add('latitude', latitude.toStringAsFixed(7));
    add('longitude', longitude.toStringAsFixed(7));
    if (landmark.trim().isNotEmpty) add('landmark', landmark.trim());

    for (final slug in categories) {
      add('categories[]', slug);
    }

    add('opens_at', formatApiTime(opensAt));
    add('closes_at', formatApiTime(closesAt));

    if (!openEveryDay) {
      for (final day in (openDays.toList()..sort())) {
        add('open_days[]', '$day');
      }
    }

    form.files.add(MapEntry('cover_photo', photo));

    return form;
  }

  /// Turns the server's field errors into the screen's keys: list items
  /// (`categories.0`) become their list (`categories`), and latitude, longitude
  /// and landmark all point at the location card. The first message wins.
  static Map<String, String> screenErrorsFromServer(Map<String, String> serverErrors) {
    final errors = <String, String>{};

    serverErrors.forEach((key, message) {
      var field = key.split('.').first;

      if (field == 'latitude' || field == 'longitude' || field == 'landmark' || field == 'address') {
        field = 'location';
      }

      errors.putIfAbsent(field, () => message);
    });

    return errors;
  }
}
