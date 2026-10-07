<?php

namespace App\Http\Resources;

use App\Models\HygieneChecklist;
use App\Support\Media;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * The Hygiene Breakdown tab. Wraps a vendor with latestChecklist.submission.
 * inspector.inspectorProfile loaded. The badge fields come from the vendor's
 * snapshot; the criteria come from the latest inspection.
 *
 * @mixin \App\Models\Vendor
 */
class HygieneBreakdownResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $checklist = $this->latestChecklist;
        $submission = $checklist?->submission;

        return [
            'status' => $this->hygiene_status->value,
            'score' => $this->hygiene_score,
            'grade' => $this->hygiene_grade?->value,
            'grade_label' => $this->hygiene_grade?->label(),
            'water_source_verified' => $this->water_source_verified,
            'last_inspected_at' => $this->last_inspected_at,
            'reverification_due_at' => $this->reverification_due_at,
            'inspection' => $checklist === null ? null : [
                'inspected_at' => $checklist->inspected_at,
                'criteria' => array_map(
                    fn (string $key) => ['key' => $key, 'result' => $checklist->{$key}->value],
                    HygieneChecklist::CRITERIA,
                ),
                // Notes are part of the public record; the inspector's name is not shown.
                'notes' => $submission?->notes,
                'organization' => $submission?->organization
                    ?? $submission?->inspector?->inspectorProfile?->organization,
                'evidence' => $submission === null ? null : [
                    'url' => Media::url($submission->evidence_photo_path),
                    'capture_time' => $submission->evidence_capture_time,
                    'submitted_at' => $submission->submitted_at,
                ],
            ],
        ];
    }
}
