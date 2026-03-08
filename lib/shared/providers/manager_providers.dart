import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/technician_repository.dart';
import '../repositories/assignment_repository.dart';

final technicianRepositoryProvider = Provider((ref) => TechnicianRepository());
final assignmentRepositoryProvider = Provider((ref) => AssignmentRepository());

final techniciansProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.read(technicianRepositoryProvider).getTechnicians();
});

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  return ref.read(technicianRepositoryProvider).getDashboardStats();
});

final technicianDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, techId) async {
      return ref
          .read(technicianRepositoryProvider)
          .getTechnicianDetails(techId);
    });
