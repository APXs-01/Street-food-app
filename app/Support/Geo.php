<?php

namespace App\Support;

/**
 * Great-circle helpers for the map endpoints. No spatial extension needed: a
 * bounding box narrows the candidate rows in SQL and Haversine gives the exact
 * distance for the survivors.
 */
final class Geo
{
    public const EARTH_RADIUS_KM = 6371.0;

    /**
     * Rectangle that fully contains the circle of the given radius around a
     * point. It does not wrap across the 180th meridian, which is irrelevant
     * for a single-country deployment.
     *
     * @return array{min_lat: float, max_lat: float, min_lng: float, max_lng: float}
     */
    public static function boundingBox(float $lat, float $lng, float $radiusKm): array
    {
        $angular = $radiusKm / self::EARTH_RADIUS_KM;

        $minLat = max(-90.0, $lat - rad2deg($angular));
        $maxLat = min(90.0, $lat + rad2deg($angular));

        // Widest longitude reach of the circle; if it covers a pole every
        // longitude is a candidate.
        $ratio = sin($angular) / cos(deg2rad($lat));
        $lngDelta = ($minLat <= -90.0 || $maxLat >= 90.0 || $ratio >= 1.0)
            ? 180.0
            : rad2deg(asin($ratio));

        return [
            'min_lat' => $minLat,
            'max_lat' => $maxLat,
            'min_lng' => max(-180.0, $lng - $lngDelta),
            'max_lng' => min(180.0, $lng + $lngDelta),
        ];
    }

    public static function haversineKm(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return 2 * self::EARTH_RADIUS_KM * asin(min(1.0, sqrt($a)));
    }
}
