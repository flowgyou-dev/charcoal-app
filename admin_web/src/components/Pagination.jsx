import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

export default function Pagination({
  totalItems,
  currentPage,
  pageSize,
  onPageChange,
  onPageSizeChange,
  pageSizeOptions = [10, 20, 30, 40, 50],
}) {
  const totalPages = Math.max(1, Math.ceil(totalItems / pageSize));
  const safePage = Math.min(Math.max(1, currentPage), totalPages);
  const startIdx = totalItems === 0 ? 0 : (safePage - 1) * pageSize + 1;
  const endIdx = Math.min(totalItems, safePage * pageSize);

  return (
    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 px-5 py-3.5 border-t border-charcoal-border bg-[#F8FAFA] text-xs text-charcoal-muted">
      <div className="flex items-center gap-3">
        <span>
          Showing <span className="font-bold text-charcoal-ink">{startIdx}</span>–
          <span className="font-bold text-charcoal-ink">{endIdx}</span> of{' '}
          <span className="font-bold text-charcoal-ink">{totalItems}</span>
        </span>
        <div className="flex items-center gap-1.5">
          <label htmlFor="page-size-select" className="text-[11px] font-medium">
            Rows:
          </label>
          <select
            id="page-size-select"
            value={pageSize}
            onChange={(e) => {
              onPageSizeChange(Number(e.target.value));
              onPageChange(1);
            }}
            className="bg-white border border-charcoal-border rounded-lg px-2 py-1 text-xs font-semibold text-charcoal-ink focus:outline-none focus:border-charcoal-header"
          >
            {pageSizeOptions.map((opt) => (
              <option key={opt} value={opt}>
                {opt}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="flex items-center gap-2">
        <button
          type="button"
          onClick={() => onPageChange(Math.max(1, safePage - 1))}
          disabled={safePage <= 1}
          className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg border border-charcoal-border bg-white text-charcoal-ink font-semibold hover:bg-charcoal-canvas disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
        >
          <ChevronLeft className="w-3.5 h-3.5" />
          Prev
        </button>
        <span className="px-2 font-semibold text-charcoal-ink">
          Page {safePage} of {totalPages}
        </span>
        <button
          type="button"
          onClick={() => onPageChange(Math.min(totalPages, safePage + 1))}
          disabled={safePage >= totalPages}
          className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg border border-charcoal-border bg-white text-charcoal-ink font-semibold hover:bg-charcoal-canvas disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
        >
          Next
          <ChevronRight className="w-3.5 h-3.5" />
        </button>
      </div>
    </div>
  );
}
