<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Vendor;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class VendorFollowController extends Controller
{
    /**
     * Idempotent: following a stall twice is fine.
     */
    public function store(Request $request, Vendor $vendor): JsonResponse
    {
        Gate::authorize('follow', $vendor);

        $request->user()->followedVendors()->syncWithoutDetaching([$vendor->id]);

        return response()->json(['following' => true]);
    }

    public function destroy(Request $request, Vendor $vendor): JsonResponse
    {
        Gate::authorize('follow', $vendor);

        $request->user()->followedVendors()->detach($vendor->id);

        return response()->json(['following' => false]);
    }
}
