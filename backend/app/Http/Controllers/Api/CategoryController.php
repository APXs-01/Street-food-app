<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\JsonResponse;

/**
 * The fixed list of food categories a stall can be listed under. The app builds
 * its category picker from this; `slug` is what vendor onboarding and the
 * `category` filter accept. Same `slug` and `name` shape as `categories` on a stall.
 */
class CategoryController extends Controller
{
    public function __invoke(): JsonResponse
    {
        return response()->json([
            // Seeded order, not alphabetical: it is the order the app shows them in.
            'data' => Category::query()->orderBy('id')->get(['slug', 'name'])->map(fn (Category $category) => [
                'slug' => $category->slug,
                'name' => $category->name,
            ])->values(),
        ]);
    }
}
