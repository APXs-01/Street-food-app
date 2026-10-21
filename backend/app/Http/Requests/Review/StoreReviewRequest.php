<?php

namespace App\Http\Requests\Review;

use App\Models\Review;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class StoreReviewRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Review::class);
    }

    /**
     * Rating is required; everything else is optional. Fields left out of a
     * resubmission keep their current value, an explicit null clears them.
     *
     * New photos are added to the ones the review already has, up to the
     * configured maximum (checked in the controller, which knows the current
     * count). Each photo carries its own optional device details:
     * photos[0][file], photos[0][capture_time], photos[0][latitude],
     * photos[0][longitude].
     *
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'rating' => ['required', 'integer', 'between:1,5'],
            'comment' => ['nullable', 'string', 'max:500'],
            'observations' => ['nullable', 'array', 'max:10'],
            'observations.*' => ['string', 'distinct', Rule::in($this->observationOptions())],
            'is_anonymous' => ['sometimes', 'boolean'],
            'photos' => ['nullable', 'array', 'max:'.config('streetbite.review_max_photos')],
            'photos.*.file' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'photos.*.capture_time' => ['nullable', 'date'],
            'photos.*.latitude' => ['nullable', 'required_with:photos.*.longitude', 'numeric', 'between:-90,90'],
            'photos.*.longitude' => ['nullable', 'required_with:photos.*.latitude', 'numeric', 'between:-180,180'],
            'remove_photos' => ['sometimes', 'boolean'],
            'remove_photo_ids' => ['nullable', 'array'],
            'remove_photo_ids.*' => ['integer', 'distinct'],
        ];
    }

    /**
     * Every photo is held to the freshness rule on its own: one whose
     * device-reported capture time is more than the configured number of
     * minutes (10) older than the upload is rejected, and the error names it.
     * A photo without a capture time is accepted on the server timestamp.
     */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator) {
            $maxAge = (int) config('streetbite.review_photo_max_age_minutes');
            $uploaded = (array) ($this->allFiles()['photos'] ?? []);

            foreach (array_keys($uploaded) as $index) {
                $key = "photos.{$index}.capture_time";
                $capturedAt = $this->input($key);

                if (blank($capturedAt) || $validator->errors()->has($key)) {
                    continue;
                }

                if (Carbon::parse($capturedAt)->lt(now()->subMinutes($maxAge))) {
                    $validator->errors()->add(
                        $key,
                        'Photo '.((int) $index + 1)." was taken more than {$maxAge} minutes ago. Please retake it.",
                    );
                }
            }
        });
    }

    /**
     * @return array<int, string>
     */
    private function observationOptions(): array
    {
        return array_merge(...array_values(config('streetbite.review_observations')));
    }
}
