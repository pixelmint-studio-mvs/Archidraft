'use client';

import React, { useEffect, ReactNode } from 'react';
import { X } from 'lucide-react';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  description?: string;
  children: ReactNode;
  maxWidth?: 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl';
}

export function Modal({
  isOpen,
  onClose,
  title,
  description,
  children,
  maxWidth = 'md',
}: ModalProps) {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    if (isOpen) {
      document.body.style.overflow = 'hidden';
      window.addEventListener('keydown', handleKeyDown);
    }
    return () => {
      document.body.style.overflow = 'unset';
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  let widthClass = 'max-w-md';
  if (maxWidth === 'sm') widthClass = 'max-w-sm';
  if (maxWidth === 'md') widthClass = 'max-w-md';
  if (maxWidth === 'lg') widthClass = 'max-w-lg';
  if (maxWidth === 'xl') widthClass = 'max-w-xl';
  if (maxWidth === '2xl') widthClass = 'max-w-2xl';
  if (maxWidth === '3xl') widthClass = 'max-w-3xl';
  if (maxWidth === '4xl') widthClass = 'max-w-4xl';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 md:p-6 overflow-hidden">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs transition-opacity"
        onClick={onClose}
      />

      {/* Modal Dialog */}
      <div
        className={`relative w-full ${widthClass} max-h-[92vh] flex flex-col bg-white border border-slate-200 rounded-2xl shadow-2xl z-10 animate-in fade-in zoom-in-95 duration-150 text-slate-900 my-auto overflow-hidden`}
      >
        {/* Modal Header */}
        <div className="flex items-start justify-between p-5 sm:p-6 pb-4 border-b border-slate-100 shrink-0 bg-white">
          <div className="min-w-0 pr-4">
            <h3 className="text-lg font-bold text-slate-900 tracking-tight truncate">{title}</h3>
            {description && <p className="text-xs text-slate-500 mt-1 font-mono break-all">{description}</p>}
          </div>
          <button
            onClick={onClose}
            aria-label="Close dialog"
            className="text-slate-400 hover:text-slate-700 p-1.5 rounded-lg hover:bg-slate-100 transition-colors cursor-pointer shrink-0"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Modal Body with vertical scrolling */}
        <div className="p-5 sm:p-6 overflow-y-auto flex-1 min-h-0 overscroll-contain">
          {children}
        </div>
      </div>
    </div>
  );
}
