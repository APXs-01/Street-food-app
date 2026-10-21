<?php

namespace App\Http\Requests\Admin;

use App\Models\User;
use App\Support\Phone;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;

class StoreInspectorRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('createInspector', User::class);
    }

    protected function prepareForValidation(): void
    {
        $phone = $this->input('phone');

        $this->merge([
            'email' => filled($this->input('email')) ? Str::lower(trim($this->input('email'))) : null,
            // Input that cannot be normalised is kept as typed so the format rule rejects it.
            'phone' => filled($phone) ? (Phone::normalize($phone) ?: $phone) : null,
        ]);
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['nullable', 'regex:/^\+\d{9,15}$/', 'unique:users,phone'],
            'password' => ['required', 'confirmed', Password::min(8)],
            'organization' => ['required', 'string', 'max:120'],
            'official_id' => ['required', 'string', 'max:40', 'unique:inspector_profiles,official_id'],
            'region' => ['nullable', 'string', 'max:80'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'phone.regex' => 'Enter a valid mobile number, for example 077 123 4567.',
        ];
    }
}
