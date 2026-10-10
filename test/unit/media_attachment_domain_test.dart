import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/domain/project_message.dart';
import 'package:archi_draft/src/features/projects/presentation/widgets/dxf_viewer.dart';

void main() {
  group('ProjectMessage Media Detection Tests', () {
    test('isImageAttachment detects common image formats and MIME types', () {
      final pngMsg = ProjectMessage(
        id: '1',
        projectId: 'p1',
        senderId: 's1',
        senderName: 'Eng',
        senderRole: 'engineer',
        message: 'plan',
        createdAt: DateTime.now(),
        attachmentFileId: 'f1',
        attachmentName: 'blueprint.png',
        attachmentContentType: 'image/png',
      );
      expect(pngMsg.isImageAttachment, isTrue);

      final jpgMsg = ProjectMessage(
        id: '2',
        projectId: 'p1',
        senderId: 's1',
        senderName: 'Eng',
        senderRole: 'engineer',
        message: 'site photo',
        createdAt: DateTime.now(),
        attachmentFileId: 'f2',
        attachmentName: 'elevation.JPEG',
        attachmentContentType: 'application/octet-stream', // fallback to extension
      );
      expect(jpgMsg.isImageAttachment, isTrue);

      final webpMsg = ProjectMessage(
        id: '3',
        projectId: 'p1',
        senderId: 's1',
        senderName: 'Eng',
        senderRole: 'engineer',
        message: 'render',
        createdAt: DateTime.now(),
        attachmentFileId: 'f3',
        attachmentName: 'render.webp',
      );
      expect(webpMsg.isImageAttachment, isTrue);
    });

    test('isCadAttachment detects DXF and DWG formats accurately', () {
      final dxfMsg = ProjectMessage(
        id: '4',
        projectId: 'p1',
        senderId: 's1',
        senderName: 'Eng',
        senderRole: 'engineer',
        message: 'dxf drawing',
        createdAt: DateTime.now(),
        attachmentFileId: 'f4',
        attachmentName: 'floorplan_v2.dxf',
        attachmentContentType: 'application/dxf',
      );
      expect(dxfMsg.isCadAttachment, isTrue);
      expect(dxfMsg.isDxfAttachment, isTrue);
      expect(dxfMsg.isDwgAttachment, isFalse);

      final dwgMsg = ProjectMessage(
        id: '5',
        projectId: 'p1',
        senderId: 's1',
        senderName: 'Eng',
        senderRole: 'engineer',
        message: 'dwg file',
        createdAt: DateTime.now(),
        attachmentFileId: 'f5',
        attachmentName: 'structural_model.dwg',
        attachmentContentType: 'application/acad',
      );
      expect(dwgMsg.isCadAttachment, isTrue);
      expect(dwgMsg.isDxfAttachment, isFalse);
      expect(dwgMsg.isDwgAttachment, isTrue);
    });

    test('Non-CAD documents are not detected as CAD or Image', () {
      final pdfMsg = ProjectMessage(
        id: '6',
        projectId: 'p1',
        senderId: 's1',
        senderName: 'Eng',
        senderRole: 'engineer',
        message: 'doc',
        createdAt: DateTime.now(),
        attachmentFileId: 'f6',
        attachmentName: 'contract.pdf',
        attachmentContentType: 'application/pdf',
      );
      expect(pdfMsg.isCadAttachment, isFalse);
      expect(pdfMsg.isImageAttachment, isFalse);
      expect(pdfMsg.isVoiceMessage, isFalse);
    });
  });

  group('DXF Pure-Dart Parser Tests', () {
    test('Parses 2D DXF entities (LINE, CIRCLE, ARC) and computes bounds', () {
      const sampleDxf = '''
0
SECTION
2
ENTITIES
0
LINE
10
0.0
20
0.0
11
100.0
21
50.0
0
CIRCLE
10
200.0
20
150.0
40
25.0
0
ARC
10
50.0
20
50.0
40
30.0
50
0.0
51
90.0
0
ENDSEC
0
EOF
''';

      final model = DxfDrawing.parse(sampleDxf);
      expect(model.entities.length, equals(3));
      expect(model.entities[0], isA<DxfLine>());
      expect(model.entities[1], isA<DxfCircle>());
      expect(model.entities[2], isA<DxfArc>());

      final line = model.entities[0] as DxfLine;
      expect(line.x1, equals(0.0));
      expect(line.y1, equals(0.0));
      expect(line.x2, equals(100.0));
      expect(line.y2, equals(50.0));

      final circle = model.entities[1] as DxfCircle;
      expect(circle.cx, equals(200.0));
      expect(circle.cy, equals(150.0));
      expect(circle.radius, equals(25.0));

      // Bounding box should enclose the circle
      expect(model.bounds.right, greaterThanOrEqualTo(225.0));
    });

    test('Parses TEXT entities with correct position, scale and text content', () {
      const dxfWithText = '''
0
SECTION
2
ENTITIES
0
LWPOLYLINE
10
0.0
20
0.0
10
6000.0
20
4000.0
0
TEXT
10
500.0
20
3500.0
40
250.0
1
SAMPLE FLOOR PLAN
50
0.0
0
TEXT
10
500.0
20
3150.0
40
160.0
1
6000 x 4000 mm
50
0.0
0
ENDSEC
0
EOF
''';

      final model = DxfDrawing.parse(dxfWithText);
      final textEntities = model.entities.whereType<DxfTextEntity>().toList();

      expect(textEntities.length, equals(2));
      expect(textEntities[0].text, equals('SAMPLE FLOOR PLAN'));
      expect(textEntities[0].x, equals(500.0));
      expect(textEntities[0].y, equals(3500.0));
      expect(textEntities[0].height, equals(250.0));
      expect(textEntities[0].rotation, equals(0.0));

      expect(textEntities[1].text, equals('6000 x 4000 mm'));
      expect(textEntities[1].x, equals(500.0));
      expect(textEntities[1].y, equals(3150.0));
      expect(textEntities[1].height, equals(160.0));
      expect(textEntities[1].rotation, equals(0.0));

      // Bounds should comfortably frame the complete drawing
      expect(model.bounds.width, greaterThanOrEqualTo(6000.0));
      expect(model.bounds.height, greaterThanOrEqualTo(4000.0));
    });

    test('Handles malformed or empty DXF gracefully without crashing', () {
      final emptyModel = DxfDrawing.parse('');
      expect(emptyModel.entities.isEmpty, isTrue);

      final junkModel = DxfDrawing.parse('RANDOM JUNK DATA THAT IS NOT DXF');
      expect(junkModel.entities.isEmpty, isTrue);
    });
  });
}
