<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\FeatureFlags;
use Illuminate\Http\JsonResponse;

class FeatureController extends Controller
{
    /**
     * Every flag as { key: enabled }, served from the cache. A flag that is not
     * in the map has not been defined; it is not the same as a disabled one, so
     * the app decides what to do with an unknown key. With no flags the data is
     * an empty object, not an empty array.
     */
    public function index(FeatureFlags $flags): JsonResponse
    {
        return response()->json(['data' => (object) $flags->all()]);
    }
}
