<?php

namespace App\Http\Requests\Menu;

use App\Models\MenuItem;
use Illuminate\Foundation\Http\FormRequest;

class StoreMenuItemRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', MenuItem::class);
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:120'],
            'description' => ['nullable', 'string', 'max:255'],
            'price' => ['required', 'numeric', 'decimal:0,2', 'min:0', 'max:9999999.99'],
            'photo' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'is_available' => ['sometimes', 'boolean'],
            'fresh_today' => ['sometimes', 'boolean'],
        ];
    }
}
