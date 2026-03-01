import clsx from 'clsx';

interface BadgeProps {
  label: string;
  color?: string;
  bgColor?: string;
  className?: string;
}

export default function Badge({ label, color, bgColor, className }: BadgeProps) {
  return (
    <span className={clsx('inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium', className)}
      style={{ color: color || '#374151', backgroundColor: bgColor || '#F3F4F6' }}>
      {label}
    </span>
  );
}
