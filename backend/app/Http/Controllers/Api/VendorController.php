<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Vendor\StoreVendorRequest;
use App\Http\Requests\Vendor\UpdateHoursRequest;
use App\Http\Requests\Vendor\UpdateStatusRequest;
use App\Http\Requests\Vendor\UpdateVendorRequest;
use App\Http\Resources\VendorResource;
use App\Models\Category;
use App\Models\Vendor;
use App\Services\ImageStorage;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Throwable;

class VendorController extends Controller
{
    public function __construct(private ImageStorage $images)
    {
    }

    /**
     * Browse stalls by name, menu item or category. Distance and hygiene
     * filtering belongs to the map endpoints.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $filters = $request->validate([
            'q' => ['nullable', 'string', 'max:100'],
            'category' => ['nullable', 'string', 'exists:categories,slug'],
            'per_page' => ['nullable', 'integer', 'between:1,50'],
        ]);

        $vendors = Vendor::query()
            ->visible()
            ->with('categories')
            ->when($filters['q'] ?? null, function (Builder $query, string $term) {
                $like = '%'.addcslashes($term, '%_\\').'%';

                $query->where(fn (Builder $match) => $match
                    ->where('name', 'like', $like)
                    ->orWhere('description', 'like', $like)
                    ->orWhereHas('menuItems', fn (Builder $items) => $items->where('name', 'like', $like)));
            })
            ->when($filters['category'] ?? null, fn (Builder $query, string $slug) => $query
                ->whereHas('categories', fn (Builder $categories) => $categories->where('slug', $slug)))
            ->orderByDesc('rating_average')
            ->orderBy('name')
            ->paginate($filters['per_page'] ?? 20);

        return VendorResource::collection($vendors);
    }

    /**
     * Stall onboarding. The stall is live as soon as it exists.
     */
    public function store(StoreVendorRequest $request): JsonResponse
    {
        $user = $request->user();

        if ($user->vendor()->exists()) {
            return $this->alreadyHasStall($user->vendor);
        }

        $data = $request->validated();
        $coverPath = $this->images->store($request->file('cover_photo'), 'vendors/covers');

        try {
            $vendor = DB::transaction(function () use ($user, $data, $coverPath) {
                $vendor = $user->vendor()->create([
                    ...Arr::except($data, ['categories', 'cover_photo', 'open_days']),
                    'open_days' => $this->normalizeOpenDays($data['open_days'] ?? null),
                    'cover_photo_path' => $coverPath,
                ]);

                $vendor->forceFill(['stall_code' => sprintf('VEND-%04d', $vendor->id)])->save();
                $vendor->categories()->sync($this->categoryIds($data['categories']));

                return $vendor;
            });
        } catch (UniqueConstraintViolationException) {
            // Two requests raced past the exists() check; the DB constraint won.
            $this->images->delete($coverPath);

            return $this->alreadyHasStall($user->vendor()->first());
        } catch (Throwable $e) {
            $this->images->delete($coverPath);

            throw $e;
        }

        return (new VendorResource($vendor->load('categories')))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Request $request, Vendor $vendor): VendorResource
    {
        $vendor->load([
            'categories',
            'menuItems' => fn ($items) => $items->orderBy('id'),
        ])->setAttribute(
            'followed_by_me',
            $vendor->followers()->where('users.id', $request->user()->id)->exists(),
        );

        return new VendorResource($vendor);
    }

    public function update(UpdateVendorRequest $request, Vendor $vendor): VendorResource
    {
        $data = $request->validated();
        $oldCover = null;

        if ($request->hasFile('cover_photo')) {
            $oldCover = $vendor->cover_photo_path;
            $data['cover_photo_path'] = $this->images->store($request->file('cover_photo'), 'vendors/covers');
        }

        DB::transaction(function () use ($vendor, $data) {
            $vendor->update(Arr::except($data, ['categories', 'cover_photo']));

            if (isset($data['categories'])) {
                $vendor->categories()->sync($this->categoryIds($data['categories']));
            }
        });

        $this->images->delete($oldCover);

        return new VendorResource($vendor->load('categories'));
    }

    /**
     * The open/closed toggle. Opening starts the auto-close clock.
     */
    public function updateStatus(UpdateStatusRequest $request, Vendor $vendor): VendorResource
    {
        $vendor->setOpen($request->boolean('is_open'));

        return new VendorResource($vendor->load('categories'));
    }

    public function updateHours(UpdateHoursRequest $request, Vendor $vendor): VendorResource
    {
        $data = $request->validated();

        $vendor->update([
            'opens_at' => $data['opens_at'],
            'closes_at' => $data['closes_at'],
            'open_days' => $this->normalizeOpenDays($data['open_days'] ?? null),
        ]);

        return new VendorResource($vendor->load('categories'));
    }

    private function alreadyHasStall(?Vendor $vendor): JsonResponse
    {
        return response()->json([
            'message' => 'You already have a stall registered. Each vendor account can manage one stall.',
            'vendor_id' => $vendor?->id,
        ], 409);
    }

    /**
     * @param  array<int, string>  $slugs
     * @return \Illuminate\Support\Collection<int, int>
     */
    private function categoryIds(array $slugs)
    {
        return Category::whereIn('slug', $slugs)->pluck('id');
    }

    /**
     * Sorted ISO weekdays (1 Monday to 7 Sunday); null means every day.
     *
     * @param  array<int, mixed>|null  $days
     * @return array<int, int>|null
     */
    private function normalizeOpenDays(?array $days): ?array
    {
        if ($days === null) {
            return null;
        }

        $days = array_values(array_unique(array_map('intval', $days)));
        sort($days);

        return count($days) === 7 ? null : $days;
    }
}
