<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\DestroyVendorRequest;
use App\Models\InspectorSubmission;
use App\Models\Vendor;
use App\Services\VendorDeletion;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

/**
 * Unlike the public API, the panel sees every stall, including those hidden
 * because their owner is suspended (the {vendor} binding only scopes api/*).
 */
class VendorManagementController extends Controller
{
    /**
     * Search matches the stall's name, code, address and landmark, and its
     * owner's name, email and phone. Filter by hygiene state and by whether
     * the public can see the stall.
     */
    public function index(Request $request): View
    {
        $filters = $request->validate([
            'q' => ['nullable', 'string', 'max:100'],
            'hygiene' => ['nullable', Rule::in(['not_inspected', 'verified', 'overdue'])],
            'visibility' => ['nullable', Rule::in(['public', 'hidden'])],
        ]);

        $vendors = Vendor::query()
            ->with(['user', 'categories'])
            ->when($filters['q'] ?? null, function (Builder $query, string $term) {
                $like = '%'.addcslashes(trim($term), '%_\\').'%';

                $query->where(fn (Builder $match) => $match
                    ->where('name', 'like', $like)
                    ->orWhere('stall_code', 'like', $like)
                    ->orWhere('address', 'like', $like)
                    ->orWhere('landmark', 'like', $like)
                    ->orWhereHas('user', fn (Builder $owner) => $owner
                        ->where('name', 'like', $like)
                        ->orWhere('email', 'like', $like)
                        ->orWhere('phone', 'like', $like)));
            })
            ->when($filters['hygiene'] ?? null, fn (Builder $query, string $state) => match ($state) {
                'not_inspected' => $query->whereNull('last_inspected_at'),
                'verified' => $query->whereNotNull('last_inspected_at')->where('reverification_due_at', '>=', now()),
                'overdue' => $query->where('reverification_due_at', '<', now()),
            })
            ->when($filters['visibility'] ?? null, fn (Builder $query, string $state) => $state === 'public'
                ? $query->visible()
                : $query->whereHas('user', fn (Builder $owner) => $owner->where('is_active', false)))
            ->latest()
            ->orderByDesc('id')
            ->paginate(25)
            ->withQueryString();

        return view('admin.vendors.index', [
            'vendors' => $vendors,
            'filters' => $filters,
        ]);
    }

    public function show(Vendor $vendor, VendorDeletion $deletion): View
    {
        $vendor->load(['user', 'categories'])->loadCount('followers');

        $inspections = InspectorSubmission::query()
            ->whereHas('checklist', fn (Builder $checklist) => $checklist->where('vendor_id', $vendor->id))
            ->with(['checklist', 'inspector'])
            ->orderByDesc('submitted_at')
            ->orderByDesc('id')
            ->limit(5)
            ->get();

        return view('admin.vendors.show', [
            'vendor' => $vendor,
            'menu' => $vendor->menuItems()->orderBy('id')->get(),
            'inspections' => $inspections,
            'hiddenReviews' => $vendor->reviews()->where('is_hidden', true)->count(),
            'impact' => $deletion->impact($vendor),
        ]);
    }

    /**
     * Permanent. Everything that belongs to the stall goes with it (see
     * VendorDeletion); the owner's account stays and can set up a new stall.
     */
    public function destroy(DestroyVendorRequest $request, Vendor $vendor, VendorDeletion $deletion): RedirectResponse
    {
        $name = $vendor->name;
        $impact = $deletion->delete($vendor);

        Log::warning('Admin deleted a stall.', [
            'admin_id' => $request->user()->id,
            'vendor_id' => $vendor->id,
            'owner_id' => $vendor->user_id,
            'name' => $name,
            'removed' => $impact,
        ]);

        return redirect()
            ->route('admin.vendors.index')
            ->with('status', "\"{$name}\" and everything that belonged to it was deleted. The owner's account is untouched.");
    }
}
