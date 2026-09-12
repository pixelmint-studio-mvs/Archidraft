import 'package:archi_draft/src/features/projects/domain/project_status.dart';
import 'package:archi_draft/src/features/projects/presentation/widgets/project_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ProjectStatusChip displays correct text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProjectStatusChip(status: ProjectStatus.draft),
        ),
      ),
    );

    expect(find.text('DRAFT'), findsOneWidget);
    
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProjectStatusChip(status: ProjectStatus.submitted),
        ),
      ),
    );

    expect(find.text('SUBMITTED'), findsOneWidget);
  });
}
