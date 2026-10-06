<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Inspection\StoreInspectionRequest;
use App\Http\Resources\InspectionResource;
use App\Models\HygieneChecklist;
use App\Models\InspectorSubmission;
use App\Models\Vendor;
use App\Services\ImageStorage;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Throwable;

class InspectorController extends Controller
{
    public function __construct(private ImageStorage $images)
    {
    }

    /**
     * Submit an inspection. The checklist model derives the score and grade
     * when it is saved, and Vendor::applyChecklist copies the result (with the
     * 30 day re-verification date) onto the stall, so the formula lives only
     * in the models.
     */
    public function store(StoreInspectionRequest $request): JsonResponse
    {
        $data = $request->validated();
        $inspector = $request->user();
        $vendor = Vendor::findOrFail($data['vendor_id']);

        $evidencePath = $this->images->store(
            $request->file('evidence_photo'),
            "inspections/{$vendor->id}",
            1600,
            85,
        );

        try {
            $submission = DB::transaction(function () use ($data, $inspector, $vendor, $evidencePath) {
                $checklist = $vendor->checklists()->create(Arr::only($data, HygieneChecklist::CRITERIA));

                $submission = $checklist->submission()->create([
                    'inspector_id' => $inspector->id,
                    'notes' => $data['notes'] ?? null,
                    'organization' => $data['organization'] ?? $inspector->inspectorProfile?->organization,
                    'evidence_photo_path' => $evidencePath,
                    'evidence_capture_time' => $data['evidence_capture_time'] ?? null,
                    'evidence_latitude' => $data['evidence_latitude'] ?? null,
                    'evidence_longitude' => $data['evidence_longitude'] ?? null,
                ]);

                $vendor->applyChecklist($checklist);

                return $submission;
            });
        } catch (Throwable $e) {
            $this->images->delete($evidencePath);

            throw $e;
        }

        return (new InspectionResource($submission->load(['checklist', 'inspector'])))
            ->additional(['vendor_hygiene' => [
                'status' => $vendor->hygiene_status->value,
                'score' => $vendor->hygiene_score,
                'grade' => $vendor->hygiene_grade?->value,
                'last_inspected_at' => $vendor->last_inspected_at,
                'reverification_due_at' => $vendor->reverification_due_at,
            ]])
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Audit trail of every inspection of a stall, newest first. Submissions are
     * never deleted. Vendors see their own stall's trail without inspector
     * identity or GPS (see InspectionResource).
     */
    public function forVendor(Request $request, Vendor $vendor): AnonymousResourceCollection
    {
        Gate::authorize('viewForVendor', [InspectorSubmission::class, $vendor]);

        $request->validate(['per_page' => ['nullable', 'integer', 'between:1,50']]);

        $submissions = InspectorSubmission::query()
            ->whereHas('checklist', fn (Builder $checklist) => $checklist->where('vendor_id', $vendor->id))
            ->with(['checklist', 'inspector'])
            ->orderByDesc('submitted_at')
            ->orderByDesc('id')
            ->paginate($request->integer('per_page', 20));

        return InspectionResource::collection($submissions);
    }
}
