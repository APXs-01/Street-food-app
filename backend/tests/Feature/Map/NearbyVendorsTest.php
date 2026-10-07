<?php

namespace Tests\Feature\Map;

use App\Models\Category;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NearbyVendorsTest extends TestCase
{
    use RefreshDatabase;

    private const LAT = 6.9271;

    private const LNG = 79.8612;

    protected function setUp(): void
    {
        parent::setUp();

        Sanctum::actingAs(User::factory()->create());
    }

    /**
     * A stall this many degrees of latitude north of the search centre
     * (0.01 degrees is about 1.11 km).
     *
     * @param  array<string, mixed>  $attributes
     */
    private function stallNorth(string $name, float $degrees, array $attributes = []): Vendor
    {
        return Vendor::factory()->create(array_merge([
            'name' => $name,
            'latitude' => self::LAT + $degrees,
            'longitude' => self::LNG,
        ], $attributes));
    }

    /**
     * @param  array<string, mixed>  $params
     */
    private function nearby(array $params = [])
    {
        return $this->getJson('/api/map/nearby?'.http_build_query(array_merge([
            'lat' => self::LAT,
            'lng' => self::LNG,
        ], $params)));
    }

    public function test_it_returns_stalls_within_the_radius_nearest_first(): void
    {
        $this->stallNorth('Far Away', 0.10);
        $this->stallNorth('Second', 0.02);
        $this->stallNorth('First', 0.005);

        $response = $this->nearby()
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.name', 'First')
            ->assertJsonPath('data.1.name', 'Second')
            ->assertJsonPath('data.0.walking_minutes', 7)
            ->assertJsonPath('data.1.walking_minutes', 27);

        $this->assertEquals(0.56, $response->json('data.0.distance_km'));
        $this->assertEquals(2.22, $response->json('data.1.distance_km'));
    }

    public function test_a_stall_inside_the_bounding_box_but_outside_the_circle_is_excluded(): void
    {
        // About 6.3 km away diagonally: inside the 5 km box, outside the 5 km circle.
        Vendor::factory()->create([
            'name' => 'Corner',
            'latitude' => self::LAT + 0.04,
            'longitude' => self::LNG + 0.04,
        ]);

        $this->nearby()->assertOk()->assertJsonCount(0, 'data');
        $this->nearby(['radius_km' => 7])->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_each_stall_carries_the_documented_fields(): void
    {
        $this->stallNorth('Plain', 0.005);

        $this->nearby()
            ->assertOk()
            ->assertJsonStructure(['data' => [['id', 'name', 'lat', 'lng', 'distance_km', 'walking_minutes', 'is_open', 'hygiene_grade', 'hygiene_status', 'star_rating']]])
            ->assertJsonPath('data.0.hygiene_grade', null)
            ->assertJsonPath('data.0.hygiene_status', 'not_inspected')
            ->assertJsonPath('data.0.star_rating', null)
            ->assertJsonPath('data.0.is_open', false);
    }

    public function test_hygiene_status_comes_from_the_snapshot(): void
    {
        $this->stallNorth('Verified', 0.005, [
            'hygiene_grade' => 'A',
            'hygiene_score' => 3.5,
            'last_inspected_at' => now()->subDays(2),
            'reverification_due_at' => now()->addDays(28),
        ]);
        $this->stallNorth('Overdue', 0.006, [
            'hygiene_grade' => 'A+',
            'hygiene_score' => 4.5,
            'last_inspected_at' => now()->subDays(40),
            'reverification_due_at' => now()->subDays(10),
        ]);

        $this->nearby()
            ->assertOk()
            ->assertJsonPath('data.0.hygiene_grade', 'A')
            ->assertJsonPath('data.0.hygiene_status', 'verified')
            ->assertJsonPath('data.1.hygiene_grade', 'A+')
            ->assertJsonPath('data.1.hygiene_status', 'reverification_pending');
    }

    public function test_min_rating_filters_on_the_star_rating_and_drops_unrated_stalls(): void
    {
        $this->stallNorth('Loved', 0.005, ['rating_average' => 4.6]);
        $this->stallNorth('Meh', 0.006, ['rating_average' => 3.2]);
        $this->stallNorth('Unrated', 0.007);

        $response = $this->nearby(['min_rating' => 4.5])
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Loved');

        $this->assertEquals(4.6, $response->json('data.0.star_rating'));
    }

    public function test_min_hygiene_filters_on_the_hygiene_score_and_drops_uninspected_stalls(): void
    {
        $this->stallNorth('Spotless', 0.005, ['hygiene_grade' => 'A+', 'hygiene_score' => 4.5]);
        $this->stallNorth('Fair', 0.006, ['hygiene_grade' => 'B', 'hygiene_score' => 2.5]);
        $this->stallNorth('Unchecked', 0.007);

        $this->nearby(['min_hygiene' => 4])
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Spotless');
    }

    public function test_it_filters_by_category(): void
    {
        $kottu = Category::create(['name' => 'Kottu', 'slug' => 'kottu']);
        $juice = Category::create(['name' => 'Fresh Juice', 'slug' => 'fresh-juice']);

        $this->stallNorth('Kottu Stall', 0.005)->categories()->attach($kottu);
        $this->stallNorth('Juice Stall', 0.006)->categories()->attach($juice);

        $this->nearby(['category' => 'kottu'])
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Kottu Stall');
    }

    public function test_open_now_uses_the_live_status_not_the_raw_toggle(): void
    {
        $this->travelTo(Carbon::parse('2026-10-05 18:00', 'Asia/Colombo'));

        $open = $this->stallNorth('Open Now', 0.005, ['closes_at' => '01:30']);
        $open->setOpen(true);

        // Left toggled on yesterday evening: the auto-close time has passed.
        $stale = $this->stallNorth('Forgot To Close', 0.006, ['closes_at' => '01:30']);
        $stale->forceFill([
            'is_open' => true,
            'status_updated_at' => Carbon::parse('2026-10-04 18:00', 'Asia/Colombo'),
        ])->save();

        $this->stallNorth('Closed', 0.007);

        $this->nearby(['open_now' => true])
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Open Now');

        // The flag itself is the live status even when the filter is off.
        $all = $this->nearby()->assertOk()->json('data');
        $this->assertSame(
            ['Open Now' => true, 'Forgot To Close' => false, 'Closed' => false],
            collect($all)->pluck('is_open', 'name')->all(),
        );
    }

    public function test_open_now_accepts_the_text_true(): void
    {
        $this->stallNorth('Closed', 0.005);

        $this->getJson('/api/map/nearby?lat=6.9271&lng=79.8612&open_now=true')
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    public function test_results_are_paginated_for_load_more(): void
    {
        foreach ([0.001, 0.002, 0.003] as $i => $degrees) {
            $this->stallNorth("Stall {$i}", $degrees);
        }

        $this->nearby(['per_page' => 2, 'page' => 2])
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Stall 2')
            ->assertJsonPath('meta.total', 3)
            ->assertJsonPath('meta.current_page', 2);
    }

    public function test_the_query_is_validated(): void
    {
        $this->getJson('/api/map/nearby')
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['lat', 'lng']);

        $this->nearby(['radius_km' => 26])->assertUnprocessable()->assertJsonValidationErrors('radius_km');
        $this->nearby(['per_page' => 51])->assertUnprocessable()->assertJsonValidationErrors('per_page');
        $this->nearby(['lat' => 91])->assertUnprocessable()->assertJsonValidationErrors('lat');
        $this->nearby(['category' => 'pizza'])->assertUnprocessable()->assertJsonValidationErrors('category');
    }
}
