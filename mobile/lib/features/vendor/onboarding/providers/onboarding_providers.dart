import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/providers/auth_providers.dart';
import '../data/location_service.dart';
import '../data/onboarding_repository.dart';
import '../data/photo_picker_service.dart';
import '../data/stall_category.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.watch(dioProvider)),
);

/// The category list for the picker. A failure is shown with a Retry button,
/// so it must not be retried silently in the background.
final categoriesProvider = FutureProvider.autoDispose<List<StallCategory>>(
  (ref) => ref.watch(onboardingRepositoryProvider).fetchCategories(),
  retry: (retryCount, error) => null,
);

final locationServiceProvider = Provider<LocationService>((ref) => GeolocatorLocationService());

final photoPickerProvider = Provider<PhotoPickerService>((ref) => ImagePickerService());
