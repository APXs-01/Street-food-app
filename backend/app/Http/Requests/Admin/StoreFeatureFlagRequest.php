<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;

class StoreFeatureFlagRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'key' => filled($this->input('key')) ? Str::lower(trim($this->input('key'))) : null,
        ]);
    }

    /**
     * The key is what the app looks up, so it is strict: lowercase words of
     * letters, digits and underscores, each starting with a letter, optionally
     * grouped with dots (consumer.friends).
     *
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'key' => ['required', 'string', 'min:2', 'max:64', 'regex:/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$/', 'unique:feature_flags,key'],
            'label' => ['required', 'string', 'max:120'],
            'description' => ['nullable', 'string', 'max:255'],
            'enabled' => ['nullable', 'boolean'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'key.regex' => 'Use lowercase words of letters, digits and underscores, each starting with a letter, grouped with dots if you like (2 to 64 characters), for example consumer.friends.',
            'key.unique' => 'A flag with this key already exists.',
        ];
    }
}
