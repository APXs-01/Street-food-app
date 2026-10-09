<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Menu\StoreMenuItemRequest;
use App\Http\Requests\Menu\UpdateMenuItemRequest;
use App\Http\Resources\MenuItemResource;
use App\Models\MenuItem;
use App\Models\Vendor;
use App\Services\ImageStorage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\ValidationException;

class MenuController extends Controller
{
    public function __construct(private ImageStorage $images)
    {
    }

    /**
     * A stall's menu. Vendors get their own stall by default.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate(['vendor_id' => ['nullable', 'integer', 'exists:vendors,id']]);

        $vendorId = $request->integer('vendor_id') ?: $request->user()->vendor?->id;

        if ($vendorId === null) {
            throw ValidationException::withMessages(['vendor_id' => ['The vendor id field is required.']]);
        }

        // A suspended vendor's menu is as hidden as the stall itself.
        abort_unless(Vendor::visible()->whereKey($vendorId)->exists(), 404);

        return MenuItemResource::collection(
            MenuItem::where('vendor_id', $vendorId)->orderBy('id')->get(),
        );
    }

    public function store(StoreMenuItemRequest $request): JsonResponse
    {
        $vendor = $request->user()->vendor;
        $data = $request->validated();

        $item = $vendor->menuItems()->create([
            ...Arr::only($data, ['name', 'description', 'price']),
            'is_available' => $data['is_available'] ?? true,
            'fresh_marked_at' => $request->boolean('fresh_today') ? now() : null,
            'photo_path' => $request->hasFile('photo')
                ? $this->images->store($request->file('photo'), "menu/{$vendor->id}", 800)
                : null,
        ]);

        return (new MenuItemResource($item))->response()->setStatusCode(201);
    }

    public function show(MenuItem $menuItem): MenuItemResource
    {
        abort_unless($menuItem->vendor->isVisible(), 404);

        return new MenuItemResource($menuItem);
    }

    /**
     * Edits, the "sold out" switch (is_available) and the "freshly prepared
     * today" switch (fresh_today) all go through here.
     */
    public function update(UpdateMenuItemRequest $request, MenuItem $menuItem): MenuItemResource
    {
        $attributes = Arr::only($request->validated(), ['name', 'description', 'price', 'is_available']);
        $oldPhoto = null;

        if ($request->hasFile('photo')) {
            $oldPhoto = $menuItem->photo_path;
            $attributes['photo_path'] = $this->images->store($request->file('photo'), "menu/{$menuItem->vendor_id}", 800);
        } elseif ($request->boolean('remove_photo')) {
            $oldPhoto = $menuItem->photo_path;
            $attributes['photo_path'] = null;
        }

        if ($request->has('fresh_today')) {
            $attributes['fresh_marked_at'] = $request->boolean('fresh_today') ? now() : null;
        }

        $menuItem->update($attributes);
        $this->images->delete($oldPhoto);

        return new MenuItemResource($menuItem);
    }

    public function destroy(MenuItem $menuItem): Response
    {
        Gate::authorize('delete', $menuItem);

        $menuItem->delete();
        $this->images->delete($menuItem->photo_path);

        return response()->noContent();
    }
}
