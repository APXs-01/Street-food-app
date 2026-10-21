<?php

namespace App\Http\Requests\Review;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ReportReviewRequest extends FormRequest
{
    /**
     * Who may report depends on the review (and a review the person cannot see
     * answers 404), so the controller authorises it.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'reason' => ['required', 'string', Rule::in(config('streetbite.review_report_reasons'))],
            'details' => ['nullable', 'string', 'max:300'],
        ];
    }
}
