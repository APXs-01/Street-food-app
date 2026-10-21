<?php

namespace App\Http\Requests\Vendor;

use App\Http\Requests\Concerns\ParsesBooleanQuery;
use Illuminate\Foundation\Http\FormRequest;

class ReviewListRequest extends FormRequest
{
    use ParsesBooleanQuery;

    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->parseBooleans(['with_photos']);
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'with_photos' => ['nullable', 'boolean'],
            'per_page' => ['nullable', 'integer', 'between:1,50'],
        ];
    }
}
