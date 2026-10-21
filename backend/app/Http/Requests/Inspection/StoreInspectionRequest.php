<?php

namespace App\Http\Requests\Inspection;

use App\Enums\CheckResult;
use App\Models\HygieneChecklist;
use App\Models\InspectorSubmission;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreInspectionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', InspectorSubmission::class);
    }

    /**
     * Score and grade are deliberately not accepted; they are derived from the
     * criteria on the server.
     *
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        $criteria = [];

        foreach (HygieneChecklist::CRITERIA as $criterion) {
            $criteria[$criterion] = ['required', Rule::enum(CheckResult::class)];
        }

        return [
            'vendor_id' => ['required', 'integer', 'exists:vendors,id'],
            ...$criteria,
            'evidence_photo' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'evidence_capture_time' => ['nullable', 'date'],
            'evidence_latitude' => ['nullable', 'required_with:evidence_longitude', 'numeric', 'between:-90,90'],
            'evidence_longitude' => ['nullable', 'required_with:evidence_latitude', 'numeric', 'between:-180,180'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'organization' => ['nullable', 'string', 'max:120'],
        ];
    }
}
