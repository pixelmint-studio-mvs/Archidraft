/**
 * CAD Utilities: Pure TypeScript DXF Vector Parser and AutoCAD DWG Thumbnail Extractor.
 * Provides client-side parsing of architectural drawing deliverables without external binaries.
 */

export interface DxfLineEntity {
  type: 'LINE';
  x1: number;
  y1: number;
  x2: number;
  y2: number;
}

export interface DxfCircleEntity {
  type: 'CIRCLE';
  cx: number;
  cy: number;
  radius: number;
}

export interface DxfArcEntity {
  type: 'ARC';
  cx: number;
  cy: number;
  radius: number;
  startAngle: number;
  endAngle: number;
}

export interface DxfPolylineEntity {
  type: 'LWPOLYLINE';
  points: { x: number; y: number }[];
  isClosed: boolean;
}

export interface DxfPointEntity {
  type: 'POINT';
  x: number;
  y: number;
}

export interface DxfTextEntity {
  type: 'TEXT';
  x: number;
  y: number;
  height: number;
  rotation: number;
  text: string;
}

export type DxfEntity =
  | DxfLineEntity
  | DxfCircleEntity
  | DxfArcEntity
  | DxfPolylineEntity
  | DxfPointEntity
  | DxfTextEntity;

export interface DxfDrawingData {
  entities: DxfEntity[];
  bounds: {
    minX: number;
    minY: number;
    maxX: number;
    maxY: number;
    width: number;
    height: number;
  };
}

export function cleanDxfText(raw: string): string {
  let s = raw;
  s = s.replace(/\\[Pp]/g, '\n');
  s = s.replace(/%%[cC]/g, 'Ø');
  s = s.replace(/%%[dD]/g, '°');
  s = s.replace(/%%[pP]/g, '±');
  s = s.replace(/%%[uU]/g, '');
  s = s.replace(/%%[oO]/g, '');
  s = s.replace(/\{([^{}]*)\}/g, '$1');
  s = s.replace(/\\[A-Za-z0-9]+;/g, '');
  s = s.replace(/\\f[^;]+;/g, '');
  s = s.replace(/\\~/g, ' ');
  return s.trim();
}

/**
 * Parses ASCII DXF string into 2D vector entities and computes accurate drawing bounds.
 */
export function parseDxf(content: string): DxfDrawingData {
  const lines = content.split(/\r?\n/);
  const entities: DxfEntity[] = [];

  let inEntities = false;
  let i = 0;

  let minX = Infinity;
  let minY = Infinity;
  let maxX = -Infinity;
  let maxY = -Infinity;

  function updateBounds(x: number, y: number) {
    if (Number.isFinite(x) && Number.isFinite(y)) {
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
  }

  while (i < lines.length - 1) {
    const code = parseInt(lines[i].trim(), 10);
    const val = lines[i + 1].trim();
    i += 2;

    if (code === 0 && val === 'SECTION') {
      if (i < lines.length - 1 && lines[i].trim() === '2' && lines[i + 1].trim() === 'ENTITIES') {
        inEntities = true;
        i += 2;
      }
    } else if (code === 0 && val === 'ENDSEC') {
      inEntities = false;
    } else if (code === 0 && val === 'EOF') {
      break;
    } else if (inEntities && code === 0) {
      const entityType = val;
      const entityCodes: Record<number, string[]> = {};

      while (i < lines.length - 1) {
        const nextCode = parseInt(lines[i].trim(), 10);
        const nextVal = lines[i + 1].trim();
        if (nextCode === 0) break;
        i += 2;
        if (!entityCodes[nextCode]) entityCodes[nextCode] = [];
        entityCodes[nextCode].push(nextVal);
      }

      const getD = (c: number): number | undefined => {
        const list = entityCodes[c];
        if (list && list.length > 0) {
          const v = parseFloat(list[0]);
          return Number.isFinite(v) ? v : undefined;
        }
        return undefined;
      };

      const getS = (c: number): string | undefined => {
        const list = entityCodes[c];
        return list && list.length > 0 ? list[0] : undefined;
      };

      if (entityType === 'LINE') {
        const x1 = getD(10) ?? 0;
        const y1 = getD(20) ?? 0;
        const x2 = getD(11) ?? 0;
        const y2 = getD(21) ?? 0;
        entities.push({ type: 'LINE', x1, y1, x2, y2 });
        updateBounds(x1, y1);
        updateBounds(x2, y2);
      } else if (entityType === 'CIRCLE') {
        const cx = getD(10) ?? 0;
        const cy = getD(20) ?? 0;
        const radius = getD(40) ?? 1;
        entities.push({ type: 'CIRCLE', cx, cy, radius });
        updateBounds(cx - radius, cy - radius);
        updateBounds(cx + radius, cy + radius);
      } else if (entityType === 'ARC') {
        const cx = getD(10) ?? 0;
        const cy = getD(20) ?? 0;
        const radius = getD(40) ?? 1;
        const startAngle = getD(50) ?? 0;
        const endAngle = getD(51) ?? 360;
        entities.push({ type: 'ARC', cx, cy, radius, startAngle, endAngle });
        updateBounds(cx - radius, cy - radius);
        updateBounds(cx + radius, cy + radius);
      } else if (entityType === 'LWPOLYLINE') {
        const xs = entityCodes[10] ?? [];
        const ys = entityCodes[20] ?? [];
        const flags = getD(70) ?? 0;
        const isClosed = (flags & 1) === 1;
        const points: { x: number; y: number }[] = [];
        const count = Math.min(xs.length, ys.length);
        for (let p = 0; p < count; p++) {
          const px = parseFloat(xs[p]) ?? 0;
          const py = parseFloat(ys[p]) ?? 0;
          points.push({ x: px, y: py });
          updateBounds(px, py);
        }
        if (points.length > 0) {
          entities.push({ type: 'LWPOLYLINE', points, isClosed });
        }
      } else if (entityType === 'POINT') {
        const px = getD(10) ?? 0;
        const py = getD(20) ?? 0;
        entities.push({ type: 'POINT', x: px, y: py });
        updateBounds(px, py);
      } else if (entityType === 'TEXT' || entityType === 'MTEXT') {
        const hAlign = getD(72) ?? 0;
        const vAlign = getD(73) ?? 0;
        const useSecond = (hAlign !== 0 || vAlign !== 0) && entityCodes[11];
        const px = useSecond ? (getD(11) ?? getD(10) ?? 0) : (getD(10) ?? 0);
        const py = useSecond ? (getD(21) ?? getD(20) ?? 0) : (getD(20) ?? 0);
        const h = (getD(40) ?? 0) > 0 ? getD(40)! : 12;
        const rotation = getD(50) ?? 0;
        const prefixChunks = entityCodes[3] ?? [];
        const mainChunk = getS(1) ?? '';
        const rawText = prefixChunks.join('') + mainChunk;
        const clean = cleanDxfText(rawText);
        if (clean.length > 0) {
          entities.push({ type: 'TEXT', x: px, y: py, height: h, rotation, text: clean });
          const approxW = clean.length * h * 0.6;
          updateBounds(px, py);
          updateBounds(px + approxW, py + h);
        }
      }
    }
  }

  if (minX === Infinity) {
    minX = 0;
    minY = 0;
    maxX = 100;
    maxY = 100;
  }

  const width = Math.abs(maxX - minX) < 1e-4 ? 10 : maxX - minX;
  const height = Math.abs(maxY - minY) < 1e-4 ? 10 : maxY - minY;

  return {
    entities,
    bounds: { minX, minY, maxX, maxY, width, height },
  };
}

/**
 * Extracts embedded DIB (Device Independent Bitmap) thumbnail from AutoCAD DWG binary.
 * Prepends a standard 14-byte BITMAPFILEHEADER to produce a valid BMP file.
 */
export function extractDwgThumbnail(buffer: ArrayBuffer): Blob | null {
  const bytes = new Uint8Array(buffer);
  if (bytes.length < 100) return null;

  // Validate AutoCAD header (e.g. AC1012, AC1014, AC1015, AC1018, AC1021, AC1024, AC1027, AC1032)
  const headerStr = String.fromCharCode(...bytes.subarray(0, 4));
  if (headerStr !== 'AC10' && headerStr !== 'AC1.' && headerStr !== 'AC15') {
    return null;
  }

  const maxScan = Math.min(bytes.length - 40, 100000);
  const view = new DataView(buffer);

  for (let i = 0; i < maxScan; i++) {
    // Look for BITMAPINFOHEADER (biSize === 40: 0x28, 0x00, 0x00, 0x00)
    if (bytes[i] === 0x28 && bytes[i + 1] === 0x00 && bytes[i + 2] === 0x00 && bytes[i + 3] === 0x00) {
      const biWidth = view.getInt32(i + 4, true);
      const biHeight = view.getInt32(i + 8, true);
      const biPlanes = view.getInt16(i + 12, true);
      const biBitCount = view.getInt16(i + 14, true);
      const biCompression = view.getInt32(i + 16, true);

      if (
        biWidth >= 32 &&
        biWidth <= 4096 &&
        Math.abs(biHeight) >= 32 &&
        Math.abs(biHeight) <= 4096 &&
        biPlanes === 1 &&
        (biBitCount === 8 || biBitCount === 24 || biBitCount === 32) &&
        biCompression === 0
      ) {
        const paletteColors = biBitCount <= 8 ? 1 << biBitCount : 0;
        const paletteSize = paletteColors * 4;
        const rowSize = Math.floor((biBitCount * biWidth + 31) / 32) * 4;
        const imageSize = rowSize * Math.abs(biHeight);
        const dibTotalSize = 40 + paletteSize + imageSize;

        if (i + dibTotalSize <= bytes.length) {
          const bmpBytes = new Uint8Array(14 + dibTotalSize);
          const bfh = new DataView(bmpBytes.buffer);
          // BITMAPFILEHEADER
          bfh.setUint8(0, 0x42); // 'B'
          bfh.setUint8(1, 0x4d); // 'M'
          bfh.setUint32(2, 14 + dibTotalSize, true); // bfSize
          bfh.setUint16(6, 0, true);
          bfh.setUint16(8, 0, true);
          bfh.setUint32(10, 14 + 40 + paletteSize, true); // bfOffBits

          bmpBytes.set(bytes.subarray(i, i + dibTotalSize), 14);
          return new Blob([bmpBytes], { type: 'image/bmp' });
        }
      }
    }
  }

  return null;
}
