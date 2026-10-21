<?php

namespace App\Http\Requests\Map;

use App\Http\Requests\Concerns\ParsesBooleanQuery;
use Illuminate\Foundation\Http\FormRequest;

class NearbyVendorsRequest extends FormRequest
{
    use ParsesBooleanQuery;

    public const MAX_RADIUS_KM = 25;

    public const MAX_PER_PAGE = 50;

    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->parseBooleans(['open_now']);
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
            'radius_km' => ['nullable', 'numeric', 'min:0.1', 'max:'.self::MAX_RADIUS_KM],
            'min_rating' => ['nullable', 'numeric', 'between:0,5'],
            'min_hygiene' => ['nullable', 'numeric', 'between:0,5'],
            'category' => ['nullable', 'string', 'exists:categories,slug'],
            'open_now' => ['nullable', 'boolean'],
            'page' => ['nullable', 'integer', 'min:1'],
            'per_page' => ['nullable', 'integer', 'between:1,'.self::MAX_PER_PAGE],
        ];
    }
}
