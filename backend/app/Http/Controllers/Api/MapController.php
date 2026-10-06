<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Map\NearbyVendorsRequest;
use App\Http\Resources\MapVendorResource;
use App\Models\Vendor;
use App\Support\Geo;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Pagination\LengthAwarePaginator;

class MapController extends Controller
{
    private const DEFAULT_RADIUS_KM = 5;

    /**
     * Stalls around a point, nearest first. SQL narrows the rows with a bounding
     * box and the cheap filters; distance, radius and live open status are then
     * settled in PHP, because "open now" depends on the auto-close rule that a
     * column cannot express.
     */
    public function nearby(NearbyVendorsRequest $request): AnonymousResourceCollection
    {
        $filters = $request->validated();

        $lat = (float) $filters['lat'];
        $lng = (float) $filters['lng'];
        $radiusKm = (float) ($filters['radius_km'] ?? self::DEFAULT_RADIUS_KM);
        $openNow = (bool) ($filters['open_now'] ?? false);

        $box = Geo::boundingBox($lat, $lng, $radiusKm);

        $vendors = Vendor::query()
            ->visible()
            ->select([
                'id', 'name', 'latitude', 'longitude',
                'is_open', 'status_updated_at', 'closes_at',
                'hygiene_grade', 'last_inspected_at', 'reverification_due_at',
                'rating_average',
            ])
            ->whereBetween('latitude', [$box['min_lat'], $box['max_lat']])
            ->whereBetween('longitude', [$box['min_lng'], $box['max_lng']])
            ->when($filters['min_rating'] ?? null, fn (Builder $query, $rating) => $query
                ->where('rating_average', '>=', $rating))
            ->when($filters['min_hygiene'] ?? null, fn (Builder $query, $score) => $query
                ->where('hygiene_score', '>=', $score))
            ->when($filters['category'] ?? null, fn (Builder $query, string $slug) => $query
                ->whereHas('categories', fn (Builder $categories) => $categories->where('slug', $slug)))
            // A stall can only be open now if its toggle is on.
            ->when($openNow, fn (Builder $query) => $query->where('is_open', true))
            ->get();

        $nearest = $vendors
            ->each(fn (Vendor $vendor) => $vendor->setAttribute(
                'distance_km',
                Geo::haversineKm($lat, $lng, $vendor->latitude, $vendor->longitude),
            ))
            ->filter(fn (Vendor $vendor) => $vendor->distance_km <= $radiusKm)
            ->when($openNow, fn ($stalls) => $stalls->filter(fn (Vendor $vendor) => $vendor->isOpenNow()))
            ->sortBy([['distance_km', 'asc'], ['id', 'asc']])
            ->values();

        $perPage = (int) ($filters['per_page'] ?? NearbyVendorsRequest::MAX_PER_PAGE);
        $page = (int) ($filters['page'] ?? 1);

        return MapVendorResource::collection(new LengthAwarePaginator(
            $nearest->forPage($page, $perPage)->values(),
            $nearest->count(),
            $perPage,
            $page,
            ['path' => $request->url(), 'query' => $request->query()],
        ));
    }
}
