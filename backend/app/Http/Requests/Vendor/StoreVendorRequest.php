<?php

namespace App\Http\Requests\Vendor;

use App\Models\Vendor;
use Illuminate\Foundation\Http\FormRequest;

class StoreVendorRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Vendor::class);
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:120'],
            'description' => ['nullable', 'string', 'max:200'],
            'address' => ['nullable', 'string', 'max:255'],
            'landmark' => ['nullable', 'string', 'max:255'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'categories' => ['required', 'array', 'min:1'],
            'categories.*' => ['string', 'distinct', 'exists:categories,slug'],
            'opens_at' => ['required', 'date_format:H:i'],
            'closes_at' => ['required', 'date_format:H:i', 'different:opens_at'],
            'open_days' => ['nullable', 'array', 'min:1'],
            'open_days.*' => ['integer', 'between:1,7', 'distinct'],
            'cover_photo' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ];
    }
}
