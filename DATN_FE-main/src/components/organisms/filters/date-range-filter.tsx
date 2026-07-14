import { format, subDays, startOfMonth, subMonths, endOfMonth } from 'date-fns';

interface DateRangeFilterProps {
  fromDate: string;
  toDate: string;
  onChange: (fromDate: string, toDate: string) => void;
}

export function DateRangeFilter({ fromDate, toDate, onChange }: DateRangeFilterProps) {
  const handlePreset = (preset: string) => {
    const today = new Date();
    let start = '';
    let end = '';

    switch (preset) {
      case 'today':
        start = format(today, 'yyyy-MM-dd');
        end = format(today, 'yyyy-MM-dd');
        break;
      case 'yesterday':
        const yesterday = subDays(today, 1);
        start = format(yesterday, 'yyyy-MM-dd');
        end = format(yesterday, 'yyyy-MM-dd');
        break;
      case '7days':
        start = format(subDays(today, 6), 'yyyy-MM-dd');
        end = format(today, 'yyyy-MM-dd');
        break;
      case '30days':
        start = format(subDays(today, 29), 'yyyy-MM-dd');
        end = format(today, 'yyyy-MM-dd');
        break;
      case 'thisMonth':
        start = format(startOfMonth(today), 'yyyy-MM-dd');
        end = format(today, 'yyyy-MM-dd');
        break;
      case 'lastMonth':
        const lastMonth = subMonths(today, 1);
        start = format(startOfMonth(lastMonth), 'yyyy-MM-dd');
        end = format(endOfMonth(lastMonth), 'yyyy-MM-dd');
        break;
      default:
        start = '';
        end = '';
    }
    onChange(start, end);
  };

  const getActivePreset = () => {
    const today = new Date();
    const todayStr = format(today, 'yyyy-MM-dd');
    const yesterdayStr = format(subDays(today, 1), 'yyyy-MM-dd');
    const days7Str = format(subDays(today, 6), 'yyyy-MM-dd');
    const days30Str = format(subDays(today, 29), 'yyyy-MM-dd');
    const thisMonthStart = format(startOfMonth(today), 'yyyy-MM-dd');
    const lastMonthStart = format(startOfMonth(subMonths(today, 1)), 'yyyy-MM-dd');
    const lastMonthEnd = format(endOfMonth(subMonths(today, 1)), 'yyyy-MM-dd');

    if (fromDate === todayStr && toDate === todayStr) return 'today';
    if (fromDate === yesterdayStr && toDate === yesterdayStr) return 'yesterday';
    if (fromDate === days7Str && toDate === todayStr) return '7days';
    if (fromDate === days30Str && toDate === todayStr) return '30days';
    if (fromDate === thisMonthStart && toDate === todayStr) return 'thisMonth';
    if (fromDate === lastMonthStart && toDate === lastMonthEnd) return 'lastMonth';
    
    if (fromDate || toDate) return 'custom';
    return '';
  };

  const activePreset = getActivePreset();

  const presets = [
    { label: 'Hôm nay', value: 'today' },
    { label: 'Hôm qua', value: 'yesterday' },
    { label: '7 ngày', value: '7days' },
    { label: '30 ngày', value: '30days' },
    { label: 'Tháng này', value: 'thisMonth' },
    { label: 'Tháng trước', value: 'lastMonth' },
  ];

  return (
    <div className="flex items-center space-x-2 flex-wrap gap-y-2">
      <div className="flex bg-slate-100 p-1 rounded-lg">
        {presets.map((preset) => (
          <button
            key={preset.value}
            onClick={() => handlePreset(preset.value)}
            className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors ${
              activePreset === preset.value
                ? 'bg-white text-blue-600 shadow-sm'
                : 'text-slate-600 hover:text-slate-900 hover:bg-slate-200/50'
            }`}
          >
            {preset.label}
          </button>
        ))}
      </div>
      <div className="flex items-center space-x-2">
        <input
          type="date"
          value={fromDate}
          onChange={(e) => onChange(e.target.value, toDate)}
          className="px-2 py-1.5 border border-slate-200 rounded-lg text-sm outline-none focus:ring-2 focus:ring-blue-500/20"
        />
        <span className="text-slate-400">-</span>
        <input
          type="date"
          value={toDate}
          onChange={(e) => onChange(fromDate, e.target.value)}
          className="px-2 py-1.5 border border-slate-200 rounded-lg text-sm outline-none focus:ring-2 focus:ring-blue-500/20"
        />
      </div>
    </div>
  );
}
