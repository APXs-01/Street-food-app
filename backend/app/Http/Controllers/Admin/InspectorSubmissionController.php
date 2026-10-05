<?php

namespace App\Http\Controllers\Admin;

use App\Enums\HygieneGrade;
use App\Http\Controllers\Controller;
use App\Models\HygieneChecklist;
use App\Models\InspectorSubmission;
use App\Support\Geo;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

/**
 * The audit trail of every inspection across every stall. Read-only by design:
 * submissions are never edited or deleted here (a stall's own deletion is the
 * only thing that removes them).
 */
class InspectorSubmissionController extends Controller
{
    /**
     * Newest first. Search matches the stall (name, code) and the inspector
     * (name, organisation, official ID). Filters: grade, one stall, one
     * inspector, a date range, and inspections with at least one failed
     * criterion.
     */
    public function index(Request $request): View
    {
        $filters = $request->validate([
            'q' => ['nullable', 'string', 'max:100'],
            'grade' => ['nullable', Rule::enum(HygieneGrade::class)],
            'vendor' => ['nullable', 'integer'],
            'inspector' => ['nullable', 'integer'],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
            'failures' => ['nullable', 'boolean'],
        ]);

        $inspections = InspectorSubmission::query()
            ->with(['checklist.vendor', 'inspector.inspectorProfile'])
            ->when($filters['q'] ?? null, function (Builder $query, string $term) {
                $like = '%'.addcslashes(trim($term), '%_\\').'%';

                $query->where(fn (Builder $match) => $match
                    ->where('organization', 'like', $like)
                    ->orWhereHas('checklist.vendor', fn (Builder $stall) => $stall
                        ->where('name', 'like', $like)
                        ->orWhere('stall_code', 'like', $like))
                    ->orWhereHas('inspector', fn (Builder $inspector) => $inspector
                        ->where('name', 'like', $like))
                    ->orWhereHas('inspector.inspectorProfile', fn (Builder $profile) => $profile
                        ->where('official_id', 'like', $like)
                        ->orWhere('organization', 'like', $like)));
            })
            ->when($filters['grade'] ?? null, fn (Builder $query, string $grade) => $query
                ->whereHas('checklist', fn (Builder $checklist) => $checklist->where('grade', $grade)))
            ->when($filters['vendor'] ?? null, fn (Builder $query, int|string $vendor) => $query
                ->whereHas('checklist', fn (Builder $checklist) => $checklist->where('vendor_id', $vendor)))
            ->when($filters['inspector'] ?? null, fn (Builder $query, int|string $inspector) => $query
                ->where('inspector_id', $inspector))
            ->when($filters['from'] ?? null, fn (Builder $query, string $from) => $query->whereDate('submitted_at', '>=', $from))
            ->when($filters['to'] ?? null, fn (Builder $query, string $to) => $query->whereDate('submitted_at', '<=', $to))
            ->when($request->boolean('failures'), fn (Builder $query) => $query
                ->whereHas('checklist', fn (Builder $checklist) => $checklist->where(function (Builder $any) {
                    foreach (HygieneChecklist::CRITERIA as $criterion) {
                        $any->orWhere($criterion, 'fail');
                    }
                })))
            ->orderByDesc('submitted_at')
            ->orderByDesc('id')
            ->paginate(25)
            ->withQueryString();

        return view('admin.inspections.index', [
            'inspections' => $inspections,
            'filters' => $filters,
            'grades' => HygieneGrade::cases(),
        ]);
    }

    public function show(InspectorSubmission $inspection): View
    {
        $inspection->load(['checklist.vendor.user', 'checklist.vendor.latestChecklist', 'inspector.inspectorProfile']);

        $checklist = $inspection->checklist;
        $vendor = $checklist->vendor;

        // How far from the stall the evidence photo was taken, when the device sent GPS.
        $evidenceDistance = $inspection->evidence_latitude === null
            ? null
            : Geo::haversineKm($inspection->evidence_latitude, $inspection->evidence_longitude, $vendor->latitude, $vendor->longitude) * 1000;

        return view('admin.inspections.show', [
            'inspection' => $inspection,
            'checklist' => $checklist,
            'vendor' => $vendor,
            // Later inspections replace it; only the newest one drives the stall's rating.
            'isCurrent' => $vendor->latestChecklist?->id === $checklist->id,
            'evidenceDistance' => $evidenceDistance,
        ]);
    }
}
