<?php

namespace App\Http\Requests\Notification;

use App\Enums\NotificationType;
use App\Http\Requests\Concerns\ParsesBooleanQuery;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class NotificationIndexRequest extends FormRequest
{
    use ParsesBooleanQuery;

    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->parseBooleans(['unread']);
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'unread' => ['nullable', 'boolean'],
            'type' => ['nullable', Rule::enum(NotificationType::class)],
            'per_page' => ['nullable', 'integer', 'between:1,50'],
        ];
    }
}
