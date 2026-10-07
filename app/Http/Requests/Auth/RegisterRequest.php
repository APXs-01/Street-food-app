<?php

namespace App\Http\Requests\Auth;

use App\Support\Phone;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
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
            'email' => ['nullable', 'required_without:phone', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['nullable', 'required_without:email', 'regex:/^\+\d{9,15}$/', 'unique:users,phone'],
            'username' => ['nullable', 'string', 'min:3', 'max:30', 'alpha_dash:ascii', 'unique:users,username'],
            'password' => ['required', 'confirmed', Password::min(8)],
            'terms' => ['accepted'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'phone.regex' => 'Enter a valid mobile number, for example 077 123 4567.',
            'terms.accepted' => 'You must accept the terms to create an account.',
        ];
    }
}
