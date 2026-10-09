<?php

namespace App\Http\Requests\Friend;

use App\Models\Friendship;
use Illuminate\Foundation\Http\FormRequest;

class StoreFriendRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Friendship::class);
    }

    /**
     * The person to add, by id or by exact @username. There is no search or
     * phone lookup, so accounts cannot be discovered by guessing numbers.
     *
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'user_id' => ['nullable', 'integer', 'required_without:username'],
            'username' => ['nullable', 'string', 'max:31', 'required_without:user_id'],
        ];
    }
}
