<?php

namespace App\Http\Requests\Friend;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateFriendRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('respond', $this->route('friendship'));
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'status' => ['required', Rule::in(['accepted', 'declined'])],
        ];
    }
}
