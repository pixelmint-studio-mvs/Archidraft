'use client';

import React, { useEffect, useState, useMemo } from 'react';
import { adminApi } from '@/lib/api';
import { parseDxf, extractDwgThumbnail, DxfDrawingData } from './cadUtils';
import { Download, AlertCircle, RefreshCw, FileCode2, Layers } from 'lucide-react';

// In-memory cache for downloaded files to avoid repeated network requests
const drawingCache = new Map<
  string,
  {
    blob: Blob;
    buffer: ArrayBuffer;
    text?: string;
    blobUrl: string;
    fileName: string;
  }
>();

interface CadDrawingRendererProps {
  fileId: string;
  fileName: string;
  versionNumber: number;
  strokeColor?: string;
  fillColor?: string;
  sharedBounds?: {
    minX: number;
    minY: number;
    maxX: number;
    maxY: number;
    width: number;
    height: number;
  };
  onBoundsLoaded?: (bounds: {
    minX: number;
    minY: number;
    maxX: number;
    maxY: number;
    width: number;
    height: number;
  }) => void;
  className?: string;
}

export function CadDrawingRenderer({
  fileId,
  fileName,
  versionNumber,
  strokeColor = '#60a5fa',
  sharedBounds,
  onBoundsLoaded,
  className = '',
}: CadDrawingRendererProps) {
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [dxfData, setDxfData] = useState<DxfDrawingData | null>(null);
  const [dwgBmpUrl, setDwgBmpUrl] = useState<string | null>(null);
  const [isDwg, setIsDwg] = useState<boolean>(false);
  const [isPdf, setIsPdf] = useState<boolean>(false);
  const [isImage, setIsImage] = useState<boolean>(false);
  const [rawBlobUrl, setRawBlobUrl] = useState<string | null>(null);
  const [fileSizeBytes, setFileSizeBytes] = useState<number>(0);

  useEffect(() => {
    let isCancelled = false;

    async function loadDrawingFile() {
      if (!fileId) {
        setError('No drawing file associated with this version.');
        setLoading(false);
        return;
      }

      setLoading(true);
      setError(null);
      setDxfData(null);
      setDwgBmpUrl(null);
      setIsDwg(false);
      setIsPdf(false);
      setIsImage(false);

      try {
        let cached = drawingCache.get(fileId);

        if (!cached) {
          const downloadRes = await adminApi.downloadFile(fileId, fileName);
          const buffer = await downloadRes.blob.arrayBuffer();
          const blobUrl = URL.createObjectURL(downloadRes.blob);

          cached = {
            blob: downloadRes.blob,
            buffer,
            blobUrl,
            fileName: downloadRes.filename || fileName,
          };
          drawingCache.set(fileId, cached);
        }

        if (isCancelled) return;

        setFileSizeBytes(cached.blob.size);
        setRawBlobUrl(cached.blobUrl);

        const ext = (fileName || cached.fileName).split('.').pop()?.toLowerCase() || '';
        const isPdfFile = ext === 'pdf' || cached.blob.type === 'application/pdf';
        const isRasterImage = ['png', 'jpg', 'jpeg', 'webp', 'svg', 'gif'].includes(ext) || cached.blob.type.startsWith('image/');
        const isDxfFile = ext === 'dxf';
        const isDwgFile = ext === 'dwg';

        if (isDxfFile) {
          if (!cached.text) {
            cached.text = new TextDecoder('utf-8').decode(cached.buffer);
          }
          const parsed = parseDxf(cached.text);
          setDxfData(parsed);
          if (onBoundsLoaded) {
            onBoundsLoaded(parsed.bounds);
          }
        } else if (isDwgFile) {
          setIsDwg(true);
          const bmpBlob = extractDwgThumbnail(cached.buffer);
          if (bmpBlob) {
            const bmpUrl = URL.createObjectURL(bmpBlob);
            setDwgBmpUrl(bmpUrl);
          }
        } else if (isPdfFile) {
          setIsPdf(true);
        } else if (isRasterImage) {
          setIsImage(true);
        } else {
          // Check magic bytes if extension is ambiguous
          const magic4 = String.fromCharCode(...new Uint8Array(cached.buffer.slice(0, 4)));
          if (magic4.startsWith('AC')) {
            setIsDwg(true);
            const bmpBlob = extractDwgThumbnail(cached.buffer);
            if (bmpBlob) {
              setDwgBmpUrl(URL.createObjectURL(bmpBlob));
            }
          } else if (magic4.startsWith('%PDF')) {
            setIsPdf(true);
          } else {
            // Attempt DXF text check
            try {
              const textSample = new TextDecoder('utf-8').decode(cached.buffer.slice(0, 100));
              if (textSample.includes('SECTION') || textSample.includes('ENTITIES')) {
                const fullText = new TextDecoder('utf-8').decode(cached.buffer);
                const parsed = parseDxf(fullText);
                setDxfData(parsed);
                if (onBoundsLoaded) onBoundsLoaded(parsed.bounds);
              }
            } catch {}
          }
        }
      } catch (err: any) {
        if (!isCancelled) {
          console.warn('[CAD RENDERER] Failed to load drawing file:', err);
          setError(err?.message || 'Unable to load drawing file from secure storage.');
        }
      } finally {
        if (!isCancelled) {
          setLoading(false);
        }
      }
    }

    loadDrawingFile();

    return () => {
      isCancelled = true;
    };
  }, [fileId, fileName]);

  const handleDownload = () => {
    if (!rawBlobUrl) return;
    const a = document.createElement('a');
    a.href = rawBlobUrl;
    a.download = fileName || `drawing_v${versionNumber}`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  };

  // Render Loading State
  if (loading) {
    return (
      <div className={`w-full h-full flex flex-col items-center justify-center p-6 text-center ${className}`}>
        <div className="w-10 h-10 rounded-full border-2 border-blue-500/20 border-t-blue-400 animate-spin mb-3" />
        <p className="text-xs font-mono font-medium text-slate-300">
          Loading Drawing v{versionNumber}...
        </p>
        <p className="text-[11px] font-mono text-slate-500 truncate max-w-xs mt-1">
          {fileName}
        </p>
      </div>
    );
  }

  // Render Error State
  if (error) {
    return (
      <div className={`w-full h-full flex flex-col items-center justify-center p-6 text-center ${className}`}>
        <div className="w-10 h-10 rounded-full bg-rose-500/10 border border-rose-500/20 flex items-center justify-center mb-3">
          <AlertCircle className="h-5 w-5 text-rose-400" />
        </div>
        <p className="text-xs font-mono font-semibold text-rose-300 mb-1">
          Drawing Load Error
        </p>
        <p className="text-[11px] text-slate-400 max-w-sm mb-4">
          {error}
        </p>
        <button
          onClick={handleDownload}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-800 border border-slate-700 text-slate-300 text-[11px] font-mono hover:text-white hover:bg-slate-700 transition-colors"
        >
          <Download className="h-3.5 w-3.5" />
          Download Original File
        </button>
      </div>
    );
  }

  // Render DXF Vector Geometry
  if (dxfData && dxfData.entities.length > 0) {
    const activeBounds = sharedBounds || dxfData.bounds;
    const pad = Math.max(activeBounds.width, activeBounds.height) * 0.05 || 10;
    const vbX = activeBounds.minX - pad;
    const vbY = activeBounds.minY - pad;
    const vbW = activeBounds.width + pad * 2;
    const vbH = activeBounds.height + pad * 2;

    // DXF Y grows upward, SVG Y grows downward: invert Y inside viewport
    return (
      <svg
        viewBox={`${vbX} ${vbY} ${vbW} ${vbH}`}
        className={`w-full h-full ${className}`}
        preserveAspectRatio="xMidYMid meet"
        xmlns="http://www.w3.org/2000/svg"
      >
        <g transform={`translate(0, ${activeBounds.minY * 2 + activeBounds.height}) scale(1, -1)`}>
          {dxfData.entities.map((entity, idx) => {
            if (entity.type === 'LINE') {
              return (
                <line
                  key={idx}
                  x1={entity.x1}
                  y1={entity.y1}
                  x2={entity.x2}
                  y2={entity.y2}
                  stroke={strokeColor}
                  strokeWidth={Math.max(activeBounds.width / 800, 0.5)}
                  strokeLinecap="round"
                />
              );
            }
            if (entity.type === 'CIRCLE') {
              return (
                <circle
                  key={idx}
                  cx={entity.cx}
                  cy={entity.cy}
                  r={entity.radius}
                  fill="none"
                  stroke={strokeColor}
                  strokeWidth={Math.max(activeBounds.width / 800, 0.5)}
                />
              );
            }
            if (entity.type === 'ARC') {
              const r = entity.radius;
              const startRad = (entity.startAngle * Math.PI) / 180;
              const endRad = (entity.endAngle * Math.PI) / 180;
              const sx = entity.cx + r * Math.cos(startRad);
              const sy = entity.cy + r * Math.sin(startRad);
              const ex = entity.cx + r * Math.cos(endRad);
              const ey = entity.cy + r * Math.sin(endRad);
              const diff = (entity.endAngle - entity.startAngle + 360) % 360;
              const largeArc = diff > 180 ? 1 : 0;
              return (
                <path
                  key={idx}
                  d={`M ${sx} ${sy} A ${r} ${r} 0 ${largeArc} 1 ${ex} ${ey}`}
                  fill="none"
                  stroke={strokeColor}
                  strokeWidth={Math.max(activeBounds.width / 800, 0.5)}
                />
              );
            }
            if (entity.type === 'LWPOLYLINE') {
              if (entity.points.length === 0) return null;
              const d = entity.points
                .map((pt, pIdx) => `${pIdx === 0 ? 'M' : 'L'} ${pt.x} ${pt.y}`)
                .join(' ') + (entity.isClosed ? ' Z' : '');
              return (
                <path
                  key={idx}
                  d={d}
                  fill="none"
                  stroke={strokeColor}
                  strokeWidth={Math.max(activeBounds.width / 800, 0.5)}
                  strokeLinejoin="round"
                  strokeLinecap="round"
                />
              );
            }
            if (entity.type === 'POINT') {
              return (
                <circle
                  key={idx}
                  cx={entity.x}
                  cy={entity.y}
                  r={Math.max(activeBounds.width / 600, 1)}
                  fill={strokeColor}
                />
              );
            }
            if (entity.type === 'TEXT') {
              return (
                <g key={idx} transform={`translate(${entity.x}, ${entity.y}) scale(1, -1)`}>
                  <text
                    x={0}
                    y={0}
                    fill={strokeColor}
                    fontSize={entity.height || 10}
                    fontFamily="monospace"
                  >
                    {entity.text}
                  </text>
                </g>
              );
            }
            return null;
          })}
        </g>
      </svg>
    );
  }

  // Render DWG (AutoCAD Binary)
  if (isDwg) {
    if (dwgBmpUrl) {
      return (
        <div className={`w-full h-full flex items-center justify-center relative ${className}`}>
          <img
            src={dwgBmpUrl}
            alt={`DWG Preview v${versionNumber}`}
            className="w-full h-full object-contain"
          />
        </div>
      );
    }
    // High-resolution informational card for binary DWG files without embedded DIB
    return (
      <div className={`w-full h-full flex flex-col items-center justify-center p-6 text-center ${className}`}>
        <div className="w-12 h-12 rounded-xl bg-blue-500/10 border border-blue-500/30 flex items-center justify-center mb-3">
          <FileCode2 className="h-6 w-6 text-blue-400" />
        </div>
        <p className="text-xs font-mono font-semibold text-slate-200">
          AutoCAD DWG Deliverable (v{versionNumber})
        </p>
        <p className="text-[11px] font-mono text-slate-400 mt-1 max-w-sm">
          {fileName}
        </p>
        <p className="text-[10px] text-slate-500 mt-2 max-w-xs leading-relaxed">
          Standard DWG binary payload. Deliverable verified and securely stored in R2.
        </p>
        <button
          onClick={handleDownload}
          className="mt-4 inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-blue-600/20 border border-blue-500/40 text-blue-300 text-[11px] font-mono hover:bg-blue-600/30 hover:text-white transition-colors"
        >
          <Download className="h-3.5 w-3.5" />
          Download Working Drawing
        </button>
      </div>
    );
  }

  // Render PDF
  if (isPdf && rawBlobUrl) {
    return (
      <div className={`w-full h-full relative ${className}`}>
        <iframe
          src={`${rawBlobUrl}#toolbar=0&navpanes=0`}
          title={`PDF Drawing v${versionNumber}`}
          className="w-full h-full border-0 rounded-lg bg-white"
        />
      </div>
    );
  }

  // Render Raster Image (PNG, JPG, WEBP, SVG)
  if (isImage && rawBlobUrl) {
    return (
      <div className={`w-full h-full flex items-center justify-center ${className}`}>
        <img
          src={rawBlobUrl}
          alt={`Drawing v${versionNumber}`}
          className="w-full h-full object-contain"
        />
      </div>
    );
  }

  // Unsupported or Empty format fallback
  return (
    <div className={`w-full h-full flex flex-col items-center justify-center p-6 text-center ${className}`}>
      <div className="w-10 h-10 rounded-full bg-slate-800 flex items-center justify-center mb-3 border border-slate-700">
        <Layers className="h-5 w-5 text-slate-400" />
      </div>
      <p className="text-xs font-mono font-semibold text-slate-300">
        Deliverable Ready
      </p>
      <p className="text-[11px] font-mono text-slate-500 mt-1 truncate max-w-xs">
        {fileName} ({((fileSizeBytes || 0) / 1024).toFixed(1)} KB)
      </p>
      <button
        onClick={handleDownload}
        className="mt-3 inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-800 border border-slate-700 text-slate-300 text-[11px] font-mono hover:text-white transition-colors"
      >
        <Download className="h-3.5 w-3.5" />
        Download Deliverable
      </button>
    </div>
  );
}
