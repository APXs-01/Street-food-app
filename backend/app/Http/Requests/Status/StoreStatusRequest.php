<?php

namespace App\Http\Requests\Status;

use App\Enums\StatusAudience;
use App\Models\DailyStatus;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class StoreStatusRequest extends FormRequest
{
    private const PHOTO_MAX_BYTES = 5 * 1024 * 1024;

    public function authorize(): bool
    {
        return $this->user()->can('create', DailyStatus::class);
    }

    /**
     * A status needs a caption, media or both. Media is a photo (jpeg, png,
     * webp) or a short video (mp4, mov). Vendors always post publicly and on
     * behalf of their own stall, so audience and vendor_id are ignored for them.
     *
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'caption' => ['nullable', 'string', 'max:200', 'required_without:media'],
            'media' => [
                'nullable', 'required_without:caption', 'file',
                'mimetypes:image/jpeg,image/png,image/webp,video/mp4,video/quicktime',
                'max:20480',
            ],
            'audience' => ['nullable', Rule::enum(StatusAudience::class)],
            'location_label' => ['nullable', 'string', 'max:120'],
            // Only a stall the public can see (its owner is not suspended) can be tagged.
            'vendor_id' => [
                'nullable', 'integer',
                Rule::exists('vendors', 'id')->where(fn ($query) => $query
                    ->whereIn('user_id', User::query()->select('id')->where('is_active', true))),
            ],
        ];
    }

    /**
     * The 20 MB cap is for videos; photos are held to 5 MB like every other photo.
     */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator) {
            $file = $this->file('media');

            if ($file && str_starts_with((string) $file->getMimeType(), 'image/') && $file->getSize() > self::PHOTO_MAX_BYTES) {
                $validator->errors()->add('media', 'Photos can be at most 5 MB.');
            }
        });
    }
}
