<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreFeatureFlagRequest;
use App\Http\Requests\Admin\UpdateFeatureFlagRequest;
use App\Models\FeatureFlag;
use App\Services\FeatureFlags;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Log;
use Illuminate\View\View;

/**
 * The switches the app reads from GET /api/features. Every change is picked up by
 * the app on its next read: the observer drops the cached flag map.
 */
class FeatureFlagController extends Controller
{
    public function index(FeatureFlags $flags): View
    {
        return view('admin.features.index', [
            'flags' => FeatureFlag::orderBy('key')->get(),
            // Exactly what the app receives.
            'payload' => (object) $flags->all(),
        ]);
    }

    public function create(): View
    {
        return view('admin.features.create');
    }

    public function store(StoreFeatureFlagRequest $request): RedirectResponse
    {
        Gate::authorize('manage-features');

        $data = $request->validated();

        $flag = FeatureFlag::create([
            'key' => $data['key'],
            'label' => $data['label'],
            'description' => $data['description'] ?? null,
            'enabled' => $request->boolean('enabled'),
        ]);

        Log::info('Admin created a feature flag.', ['admin_id' => $request->user()->id, 'key' => $flag->key, 'enabled' => $flag->enabled]);

        return redirect()->route('admin.features.index')->with('status', "Flag \"{$flag->key}\" created.");
    }

    public function edit(FeatureFlag $feature): View
    {
        return view('admin.features.edit', ['flag' => $feature]);
    }

    /**
     * The key is never touched: only the label, description and state change.
     */
    public function update(UpdateFeatureFlagRequest $request, FeatureFlag $feature): RedirectResponse
    {
        Gate::authorize('manage-features');

        $data = $request->validated();

        $feature->update([
            'label' => $data['label'],
            'description' => $data['description'] ?? null,
            'enabled' => $request->boolean('enabled'),
        ]);

        Log::info('Admin updated a feature flag.', ['admin_id' => $request->user()->id, 'key' => $feature->key, 'enabled' => $feature->enabled]);

        return redirect()->route('admin.features.index')->with('status', "Flag \"{$feature->key}\" saved.");
    }

    public function toggle(Request $request, FeatureFlag $feature): RedirectResponse
    {
        Gate::authorize('manage-features');

        $feature->update(['enabled' => ! $feature->enabled]);

        Log::info('Admin toggled a feature flag.', ['admin_id' => $request->user()->id, 'key' => $feature->key, 'enabled' => $feature->enabled]);

        return redirect()->route('admin.features.index')
            ->with('status', "\"{$feature->key}\" is now ".($feature->enabled ? 'on' : 'off').'.');
    }

    /**
     * The app then finds the key missing, which is not the same as disabled.
     */
    public function destroy(Request $request, FeatureFlag $feature): RedirectResponse
    {
        Gate::authorize('manage-features');

        $feature->delete();

        Log::warning('Admin deleted a feature flag.', ['admin_id' => $request->user()->id, 'key' => $feature->key]);

        return redirect()->route('admin.features.index')->with('status', "Flag \"{$feature->key}\" deleted.");
    }
}
