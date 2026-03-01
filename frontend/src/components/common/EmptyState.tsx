import { Inbox } from 'lucide-react';

interface EmptyStateProps { message?: string; icon?: React.ReactNode; }

export default function EmptyState({ message = 'Sin datos', icon }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-gray-400">
      {icon || <Inbox size={48} strokeWidth={1} />}
      <p className="mt-3 text-sm">{message}</p>
    </div>
  );
}
