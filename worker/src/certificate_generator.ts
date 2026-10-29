// @ts-ignore
import QRCode from 'qrcode/lib/core/qrcode';
import { getCertificateTemplateBytes } from './assets/certificate_template_data';

export interface CertificatePdfOptions {
  studentName: string;
  lessonTitle: string;
  completionDate?: string;
  certificateId: string;
  verifyUrl: string;
}

/**
 * Escapes characters that have special meaning inside PDF text literals: (, ), \
 */
function escapePdfText(text: string): string {
  if (!text) return '';
  return text
    .replace(/\\/g, '\\\\')
    .replace(/\(/g, '\\(')
    .replace(/\)/g, '\\)');
}

/**
 * Estimates text width in points for standard Helvetica fonts.
 */
function estimateTextWidth(text: string, fontSize: number, isBold: boolean = false): number {
  const avgCharFactor = isBold ? 0.60 : 0.52;
  return text.length * fontSize * avgCharFactor;
}

/**
 * Generates an ISO PDF-1.4 binary certificate embedding the official high-resolution
 * Archi Draft Student Achievement Certificate visual design, dynamic student name,
 * exact custom lesson title, completion date, unique certificate ID, and unique verification QR code.
 */
export function generateCertificatePdf(options: CertificatePdfOptions): Uint8Array {
  const imgBytes = getCertificateTemplateBytes();
  const imgLength = imgBytes.length;

  const rawName = (options.studentName || 'Student').trim();
  const rawLesson = (options.lessonTitle || 'Architectural Drafting Lesson').trim();
  const rawDate = (options.completionDate || new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })).trim();
  const rawId = (options.certificateId || 'DS-AD-LES-0001').trim();
  const rawUrl = (options.verifyUrl || 'https://www.draughtsmanstudio.com/verify').trim();

  const safeName = escapePdfText(rawName);
  const safeLesson = escapePdfText(rawLesson);
  const safeDate = escapePdfText(rawDate);
  const safeId = escapePdfText(rawId);

  // Generate 2D QR Code Matrix
  const qr = QRCode.create(rawUrl, { errorCorrectionLevel: 'M' });
  const qrSize = 72; // points
  const qrBoxX = 701;
  const qrBoxY = 127;
  const N = qr.modules.size;
  const modSize = qrSize / N;

  let qrDrawing = `1 1 1 rg\n${qrBoxX} ${qrBoxY} ${qrSize} ${qrSize} re f\n0 0 0 rg\n`;
  for (let r = 0; r < N; r++) {
    for (let c = 0; c < N; c++) {
      if (qr.modules.get(c, r)) {
        const modX = (qrBoxX + c * modSize).toFixed(2);
        const modY = (qrBoxY + (N - 1 - r) * modSize).toFixed(2);
        qrDrawing += `${modX} ${modY} ${modSize.toFixed(2)} ${modSize.toFixed(2)} re f\n`;
      }
    }
  }

  // Student Name Positioning (centered at X = 421, Y = 272)
  let nameFontSize = 22;
  if (rawName.length > 30) {
    nameFontSize = 18;
  } else if (rawName.length > 40) {
    nameFontSize = 15;
  }
  const nameWidth = estimateTextWidth(rawName, nameFontSize, true);
  const nameX = Math.max(80, Math.round(421 - nameWidth / 2));
  const nameY = 272;

  // Lesson Title Positioning (centered at X = 421, Y = 222)
  // Adaptively scale down font size for long custom lesson titles so they never overflow
  let lessonFontSize = 16;
  if (rawLesson.length > 55) {
    lessonFontSize = 12;
  } else if (rawLesson.length > 40) {
    lessonFontSize = 13.5;
  } else if (rawLesson.length > 28) {
    lessonFontSize = 15;
  }
  const lessonWidth = estimateTextWidth(rawLesson, lessonFontSize, true);
  const lessonX = Math.max(80, Math.round(421 - lessonWidth / 2));
  const lessonY = 222;

  // Completion Date Positioning (centered at X = 421, Y = 148)
  const dateStr = `Issued on ${safeDate}`;
  const dateFontSize = 10;
  const dateWidth = estimateTextWidth(`Issued on ${rawDate}`, dateFontSize, false);
  const dateX = Math.round(421 - dateWidth / 2);
  const dateY = 148;

  // Certificate ID Positioning (centered inside box at X = 738, Y = 61)
  const idFontSize = 9;
  const idWidth = estimateTextWidth(rawId, idFontSize, true);
  const idX = Math.round(738 - idWidth / 2);
  const idY = 61;

  const contentStream = `
q
842 0 0 631.5 0 0 cm
/Im1 Do
Q
${qrDrawing}
BT
/F1 ${nameFontSize} Tf
0.12 0.12 0.12 rg
${nameX} ${nameY} Td
(${safeName}) Tj
ET
BT
/F1 ${lessonFontSize} Tf
0.15 0.15 0.15 rg
${lessonX} ${lessonY} Td
(${safeLesson}) Tj
ET
BT
/F2 ${dateFontSize} Tf
0.40 0.40 0.40 rg
${dateX} ${dateY} Td
(${dateStr}) Tj
ET
BT
/F1 ${idFontSize} Tf
0.18 0.18 0.18 rg
${idX} ${idY} Td
(${safeId}) Tj
ET
`.trim();

  const encoder = new TextEncoder();
  const contentBytes = encoder.encode(contentStream);

  // Build PDF Binary Buffers
  let currentOffset = 0;
  const xrefOffsets: number[] = [];
  const parts: Uint8Array[] = [];

  function append(data: string | Uint8Array) {
    const b = typeof data === 'string' ? encoder.encode(data) : data;
    parts.push(b);
    currentOffset += b.length;
  }

  append('%PDF-1.4\n');

  // Obj 1: Catalog
  xrefOffsets[1] = currentOffset;
  append('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

  // Obj 2: Pages
  xrefOffsets[2] = currentOffset;
  append('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');

  // Obj 3: Page
  xrefOffsets[3] = currentOffset;
  append(
    '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 842 631.5] /Contents 4 0 R /Resources << /XObject << /Im1 5 0 R >> /Font << /F1 6 0 R /F2 7 0 R >> >> >>\nendobj\n'
  );

  // Obj 4: Contents Stream
  xrefOffsets[4] = currentOffset;
  append(`4 0 obj\n<< /Length ${contentBytes.length} >>\nstream\n`);
  append(contentBytes);
  append('\nendstream\nendobj\n');

  // Obj 5: Image XObject
  xrefOffsets[5] = currentOffset;
  append(
    `5 0 obj\n<< /Type /XObject /Subtype /Image /Width 1920 /Height 1440 /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${imgLength} >>\nstream\n`
  );
  append(imgBytes);
  append('\nendstream\nendobj\n');

  // Obj 6: Font F1 (Helvetica-Bold)
  xrefOffsets[6] = currentOffset;
  append('6 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\nendobj\n');

  // Obj 7: Font F2 (Helvetica)
  xrefOffsets[7] = currentOffset;
  append('7 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n');

  // XRef Table
  const startXref = currentOffset;
  append('xref\n0 8\n0000000000 65535 f \n');
  for (let i = 1; i <= 7; i++) {
    const padded = xrefOffsets[i].toString().padStart(10, '0');
    append(`${padded} 00000 n \n`);
  }

  // Trailer
  append(`trailer\n<< /Size 8 /Root 1 0 R >>\nstartxref\n${startXref}\n%%EOF`);

  // Concatenate all parts into a single Uint8Array
  const totalLength = parts.reduce((acc, p) => acc + p.length, 0);
  const result = new Uint8Array(totalLength);
  let pos = 0;
  for (const part of parts) {
    result.set(part, pos);
    pos += part.length;
  }

  return result;
}
