<?php

namespace App\Http\Requests\Vendor;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Stall details only. Hours and the open/closed toggle have their own requests.
 */
class UpdateVendorRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('vendor'));
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'required', 'string', 'max:120'],
            'description' => ['sometimes', 'nullable', 'string', 'max:200'],
            'address' => ['sometimes', 'nullable', 'string', 'max:255'],
            'landmark' => ['sometimes', 'nullable', 'string', 'max:255'],
            'latitude' => ['required_with:longitude', 'numeric', 'between:-90,90'],
            'longitude' => ['required_with:latitude', 'numeric', 'between:-180,180'],
            'categories' => ['sometimes', 'required', 'array', 'min:1'],
            'categories.*' => ['string', 'distinct', 'exists:categories,slug'],
            'cover_photo' => ['sometimes', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ];
    }
}
