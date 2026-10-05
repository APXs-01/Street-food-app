<?php

namespace App\Http\Controllers\Admin;

use App\Enums\HygieneGrade;
use App\Http\Controllers\Controller;
use App\Models\Vendor;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

/**
 * Where every stall stands right now and what is coming due. It reads the
 * snapshot the latest inspection wrote onto the stall, and links to the
 * inspections screen for what happened in each visit, so it does not repeat
 * that detail. Read-only.
 */
class HygieneChecklistController extends Controller
{
    public function index(Request $request): View
    {
        $filters = $request->validate([
            'q' => ['nullable', 'string', 'max:100'],
            'state' => ['nullable', Rule::in(['overdue', 'due_soon', 'current', 'not_inspected'])],
            'grade' => ['nullable', Rule::enum(HygieneGrade::class)],
            'water' => ['nullable', Rule::in(['verified', 'unverified'])],
            'sort' => ['nullable', Rule::in(['due', 'score', 'name'])],
        ]);

        $soonDays = (int) config('streetbite.due_soon_days');
        $sort = $filters['sort'] ?? 'due';

        $stalls = Vendor::query()
            ->with(['user', 'latestChecklist.submission'])
            ->when($filters['q'] ?? null, function (Builder $query, string $term) {
                $like = '%'.addcslashes(trim($term), '%_\\').'%';

                $query->where(fn (Builder $match) => $match
                    ->where('name', 'like', $like)
                    ->orWhere('stall_code', 'like', $like)
                    ->orWhereHas('user', fn (Builder $owner) => $owner
                        ->where('name', 'like', $like)
                        ->orWhere('email', 'like', $like)));
            })
            ->when($filters['state'] ?? null, fn (Builder $query, string $state) => match ($state) {
                'overdue' => $query->hygieneOverdue(),
                'due_soon' => $query->hygieneDueSoon($soonDays),
                'current' => $query->hygieneCurrent($soonDays),
                'not_inspected' => $query->neverInspected(),
            })
            ->when($filters['grade'] ?? null, fn (Builder $query, string $grade) => $query->where('hygiene_grade', $grade))
            // "Unverified" means inspected but without a verified safe water source;
            // stalls never inspected are their own state.
            ->when($filters['water'] ?? null, fn (Builder $query, string $water) => $water === 'verified'
                ? $query->where('water_source_verified', true)
                : $query->whereNotNull('last_inspected_at')->where('water_source_verified', false))
            ->when($sort === 'name', fn (Builder $query) => $query->orderBy('name'))
            // Lowest score first, never-inspected stalls last.
            ->when($sort === 'score', fn (Builder $query) => $query->orderByRaw('hygiene_score IS NULL')->orderBy('hygiene_score'))
            // Most urgent first: the longest overdue, then soonest due, then never inspected.
            ->when($sort === 'due', fn (Builder $query) => $query->orderByRaw('reverification_due_at IS NULL')->orderBy('reverification_due_at'))
            ->orderBy('id')
            ->paginate(25)
            ->withQueryString();

        return view('admin.hygiene.index', [
            'stalls' => $stalls,
            'filters' => $filters,
            'sort' => $sort,
            'soonDays' => $soonDays,
            'grades' => HygieneGrade::cases(),
            'summary' => [
                'total' => Vendor::count(),
                'overdue' => Vendor::hygieneOverdue()->count(),
                'due_soon' => Vendor::hygieneDueSoon($soonDays)->count(),
                'current' => Vendor::hygieneCurrent($soonDays)->count(),
                'not_inspected' => Vendor::neverInspected()->count(),
            ],
        ]);
    }
}
