import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/technician_repository.dart';
import '../repositories/assignment_repository.dart';
import '../repositories/service_repository.dart';

final technicianRepositoryProvider = Provider((ref) => TechnicianRepository());
final assignmentRepositoryProvider = Provider((ref) => AssignmentRepository());

final techniciansProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      return ref.read(technicianRepositoryProvider).getTechnicians();
    });

final dashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    return ref.read(technicianRepositoryProvider).getDashboardStats();
  },
);

final technicianDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, techId) async {
      return ref
          .read(technicianRepositoryProvider)
          .getTechnicianDetails(techId);
    });

// Services
final serviceRepositoryProvider = Provider((ref) => ServiceRepository());

final managerServicesProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  return ref.read(serviceRepositoryProvider).getAllServiceTypes();
});
