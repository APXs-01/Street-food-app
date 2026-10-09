import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/inspection_repository.dart';

final inspectionRepositoryProvider = Provider<InspectionRepository>((ref) => InspectionRepository(ref.watch(dioProvider)));
