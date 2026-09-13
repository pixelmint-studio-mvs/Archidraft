import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/project_file.dart';
import '../data/file_repository.dart';

final projectFilesProvider = FutureProvider.family<List<ProjectFile>, String>((
  ref,
  projectId,
) async {
  final repository = ref.watch(fileRepositoryProvider);
  return repository.getProjectFiles(projectId);
});
