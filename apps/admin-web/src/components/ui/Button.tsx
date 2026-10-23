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
    'inline-flex items-center justify-center font-medium rounded-lg transition-all focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-white disabled:opacity-50 disabled:cursor-not-allowed select-none active:scale-[0.99]';

  let variantStyle = '';
  switch (variant) {
    case 'primary':
      variantStyle =
        'bg-[#0d1c32] hover:bg-[#15294a] text-white shadow-sm hover:shadow focus:ring-[#0453cd] active:bg-[#081220]';
      break;
    case 'secondary':
      variantStyle =
        'bg-[#0453cd] hover:bg-[#0341a1] text-white shadow-sm hover:shadow focus:ring-[#0453cd] active:bg-[#033682]';
      break;
    case 'danger':
      variantStyle =
        'bg-rose-600 hover:bg-rose-700 text-white shadow-sm focus:ring-rose-500 active:bg-rose-800';
      break;
    case 'success':
      variantStyle =
        'bg-emerald-600 hover:bg-emerald-700 text-white shadow-sm focus:ring-emerald-500 active:bg-emerald-800';
      break;
    case 'outline':
      variantStyle =
        'border border-slate-200 hover:border-slate-300 bg-white text-slate-800 hover:bg-slate-50 shadow-sm focus:ring-slate-300 active:bg-slate-100';
      break;
    case 'ghost':
      variantStyle = 'bg-transparent hover:bg-slate-100 text-slate-600 hover:text-slate-900 focus:ring-slate-300';
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
