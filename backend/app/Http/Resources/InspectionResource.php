<?php

namespace App\Http\Resources;

use App\Enums\UserRole;
use App\Models\HygieneChecklist;
use App\Support\Media;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One inspection: the submission with its checklist and inspector. Staff also
 * get the inspector's identity and the evidence GPS; a vendor reading their own
 * stall's record gets the result, notes, organisation and evidence photo only.
 *
 * @mixin \App\Models\InspectorSubmission
 */
class InspectionResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $checklist = $this->checklist;
        $staff = in_array($request->user()?->role, [UserRole::Inspector, UserRole::SuperAdmin], true);

        return [
            'id' => $this->id,
            'vendor_id' => $checklist->vendor_id,
            'inspected_at' => $checklist->inspected_at,
            'score' => $checklist->score,
            'grade' => $checklist->grade->value,
            'grade_label' => $checklist->grade->label(),
            'criteria' => array_map(
                fn (string $key) => ['key' => $key, 'result' => $checklist->{$key}->value],
                HygieneChecklist::CRITERIA,
            ),
            'notes' => $this->notes,
            'organization' => $this->organization,
            'inspector' => $this->when($staff && $this->relationLoaded('inspector'), fn () => [
                'id' => $this->inspector->id,
                'name' => $this->inspector->name,
            ]),
            'evidence' => [
                'url' => Media::url($this->evidence_photo_path),
                'capture_time' => $this->evidence_capture_time,
                'latitude' => $this->when($staff, $this->evidence_latitude),
                'longitude' => $this->when($staff, $this->evidence_longitude),
                'submitted_at' => $this->submitted_at,
            ],
        ];
    }
}
