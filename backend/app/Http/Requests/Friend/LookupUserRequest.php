<?php

namespace App\Http\Requests\Friend;

use App\Models\Friendship;
use Illuminate\Foundation\Http\FormRequest;

class LookupUserRequest extends FormRequest
{
    /**
     * Same audience as the friend network: active customers.
     */
    public function authorize(): bool
    {
        return $this->user()->can('create', Friendship::class);
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'username' => ['required', 'string', 'max:31'],
        ];
    }
}
