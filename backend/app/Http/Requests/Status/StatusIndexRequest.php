<?php

namespace App\Http\Requests\Status;

use App\Http\Requests\Concerns\ParsesBooleanQuery;
use Illuminate\Foundation\Http\FormRequest;

class StatusIndexRequest extends FormRequest
{
    use ParsesBooleanQuery;

    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->parseBooleans(['mine']);
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'mine' => ['nullable', 'boolean'],
            'per_page' => ['nullable', 'integer', 'between:1,50'],
        ];
    }
}
