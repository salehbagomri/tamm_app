import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/technician_repository.dart';
import '../repositories/assignment_repository.dart';

final technicianRepositoryProvider = Provider((ref) => TechnicianRepository());
final assignmentRepositoryProvider = Provider((ref) => AssignmentRepository());
