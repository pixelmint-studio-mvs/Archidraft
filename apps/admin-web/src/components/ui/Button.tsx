import React, { ButtonHTMLAttributes } from 'react';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger' | 'success' | 'outline' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
  icon?: React.ReactNode;
}

export function Button({
  children,
  variant = 'primary',
  size = 'md',
  loading = false,
  disabled,
  icon,
  className = '',
  ...props
}: ButtonProps) {
  const base =
    'inline-flex items-center justify-center font-medium rounded-lg transition-all focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-[#090d16] disabled:opacity-50 disabled:cursor-not-allowed select-none';

  let variantStyle = '';
  switch (variant) {
    case 'primary':
      variantStyle =
        'bg-blue-600 hover:bg-blue-500 text-white shadow-lg shadow-blue-500/20 focus:ring-blue-500 active:bg-blue-700';
      break;
    case 'secondary':
      variantStyle =
        'bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 focus:ring-slate-500 active:bg-slate-850';
      break;
    case 'danger':
      variantStyle =
        'bg-rose-600 hover:bg-rose-500 text-white shadow-lg shadow-rose-500/20 focus:ring-rose-500 active:bg-rose-700';
      break;
    case 'success':
      variantStyle =
        'bg-emerald-600 hover:bg-emerald-500 text-white shadow-lg shadow-emerald-500/20 focus:ring-emerald-500 active:bg-emerald-700';
      break;
    case 'outline':
      variantStyle =
        'border border-slate-700 hover:border-slate-600 bg-transparent text-slate-300 hover:bg-slate-800/50 focus:ring-slate-500';
      break;
    case 'ghost':
      variantStyle = 'bg-transparent hover:bg-slate-800/60 text-slate-300 hover:text-white focus:ring-slate-500';
      break;
  }

  let sizeStyle = '';
  switch (size) {
    case 'sm':
      sizeStyle = 'px-3 py-1.5 text-xs gap-1.5';
      break;
    case 'md':
      sizeStyle = 'px-4 py-2 text-sm gap-2';
      break;
    case 'lg':
      sizeStyle = 'px-5 py-2.5 text-base gap-2.5';
      break;
  }

  return (
    <button
      disabled={disabled || loading}
      className={`${base} ${variantStyle} ${sizeStyle} ${className}`}
      {...props}
    >
      {loading ? (
        <svg
          className="animate-spin -ml-0.5 h-4 w-4 text-current"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle
            className="opacity-25"
            cx="12"
            cy="12"
            r="10"
            stroke="currentColor"
            strokeWidth="4"
          />
          <path
            className="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          />
        </svg>
      ) : (
        icon
      )}
      {children}
    </button>
  );
}
