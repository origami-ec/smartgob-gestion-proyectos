import clsx from 'clsx';

interface ProgressBarProps { value: number; className?: string; }

export default function ProgressBar({ value, className }: ProgressBarProps) {
  const color = value >= 80 ? 'bg-green-500' : value >= 50 ? 'bg-yellow-500' : value >= 20 ? 'bg-orange-500' : 'bg-red-500';
  return (
    <div className={clsx('h-2 bg-gray-200 rounded-full overflow-hidden', className)}>
      <div className={clsx('h-full rounded-full transition-all', color)}
        style={{ width: `${Math.min(100, Math.max(0, value))}%` }} />
    </div>
  );
}
