<?php

namespace App\Http\Requests\Auth;

use App\Support\Phone;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;

class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'login' => ['required', 'string', 'max:255'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ];
    }

    /**
     * The users column and normalised value the login identifier refers to.
     *
     * @return array{0: string, 1: string}
     */
    public function identifier(): array
    {
        $login = trim($this->input('login'));

        return str_contains($login, '@')
            ? ['email', Str::lower($login)]
            : ['phone', Phone::normalize($login)];
    }
}
