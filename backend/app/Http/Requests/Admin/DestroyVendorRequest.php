<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class DestroyVendorRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('delete', $this->route('vendor'));
    }

    /**
     * Deleting a stall is permanent, so the administrator has to type its name.
     *
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'confirm_name' => [
                'required',
                'string',
                function (string $attribute, mixed $value, \Closure $fail) {
                    if (trim((string) $value) !== $this->route('vendor')->name) {
                        $fail('The name you typed does not match this stall, so nothing was deleted.');
                    }
                },
            ],
        ];
    }
}
