<?php

namespace App\Http\Requests\Review;

/**
 * Same rules as submitting, but every field is optional so a partial edit works.
 */
class UpdateReviewRequest extends StoreReviewRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('review'));
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return array_merge(parent::rules(), [
            'rating' => ['sometimes', 'required', 'integer', 'between:1,5'],
        ]);
    }
}
