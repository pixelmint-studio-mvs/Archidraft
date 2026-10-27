import { describe, it, before } from 'node:test';
import assert from 'node:assert/strict';

describe('CAD Comparison DXF Parser', () => {
  let parseDxf: any;
  let cleanDxfText: any;
  let extractDwgThumbnail: any;

  before(async () => {
    const mod = await import(new URL('../src/components/cad/cadUtils.ts', import.meta.url).href);
    parseDxf = mod.parseDxf;
    cleanDxfText = mod.cleanDxfText;
    extractDwgThumbnail = mod.extractDwgThumbnail;
  });
  it('parses LINE entities and computes accurate bounds', () => {
    const sampleDxf = `0
SECTION
2
ENTITIES
0
LINE
10
10.0
20
20.0
11
110.0
21
220.0
0
ENDSEC
0
EOF`;

    const result = parseDxf(sampleDxf);
    assert.equal(result.entities.length, 1);
    const line = result.entities[0];
    assert.equal(line.type, 'LINE');
    if (line.type === 'LINE') {
      assert.equal(line.x1, 10);
      assert.equal(line.y1, 20);
      assert.equal(line.x2, 110);
      assert.equal(line.y2, 220);
    }
    assert.equal(result.bounds.minX, 10);
    assert.equal(result.bounds.minY, 20);
    assert.equal(result.bounds.maxX, 110);
    assert.equal(result.bounds.maxY, 220);
    assert.equal(result.bounds.width, 100);
    assert.equal(result.bounds.height, 200);
  });

  it('parses CIRCLE and ARC entities with correct radius bounds', () => {
    const sampleDxf = `0
SECTION
2
ENTITIES
0
CIRCLE
10
50.0
20
50.0
40
25.0
0
ARC
10
150.0
20
150.0
40
30.0
50
0.0
51
90.0
0
ENDSEC
0
EOF`;

    const result = parseDxf(sampleDxf);
    assert.equal(result.entities.length, 2);
    assert.equal(result.entities[0].type, 'CIRCLE');
    assert.equal(result.entities[1].type, 'ARC');
    assert.equal(result.bounds.minX, 25);
    assert.equal(result.bounds.maxX, 180);
  });

  it('parses LWPOLYLINE with closed flag', () => {
    const sampleDxf = `0
SECTION
2
ENTITIES
0
LWPOLYLINE
70
1
10
0.0
20
0.0
10
100.0
20
0.0
10
100.0
20
50.0
0
ENDSEC
0
EOF`;

    const result = parseDxf(sampleDxf);
    assert.equal(result.entities.length, 1);
    const poly = result.entities[0];
    assert.equal(poly.type, 'LWPOLYLINE');
    if (poly.type === 'LWPOLYLINE') {
      assert.equal(poly.points.length, 3);
      assert.equal(poly.isClosed, true);
    }
  });

  it('cleans DXF text formatting escape codes', () => {
    const raw = '{\\fArial|b0|i0;Room 101\\PArea: 120%%d sqm}';
    const cleaned = cleanDxfText(raw);
    assert.ok(cleaned.includes('Room 101'));
    assert.ok(cleaned.includes('°'));
    assert.ok(!cleaned.includes('\\fArial'));
  });

  it('returns null for non-DWG or invalid DWG bytes without crashing', () => {
    const emptyBytes = new Uint8Array(10);
    const result = extractDwgThumbnail(emptyBytes.buffer);
    assert.equal(result, null);

    const fakeDwg = new TextEncoder().encode('AC1027NOT_A_REAL_IMAGE_HEADER');
    const result2 = extractDwgThumbnail(fakeDwg.buffer);
    assert.equal(result2, null);
  });
});
