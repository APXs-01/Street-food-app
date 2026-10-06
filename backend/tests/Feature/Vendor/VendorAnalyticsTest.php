<?php

namespace Tests\Feature\Vendor;

use App\Models\DailyStatus;
use App\Models\HygieneChecklist;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesSocialFixtures;
use Tests\TestCase;

class VendorAnalyticsTest extends TestCase
{
    use CreatesSocialFixtures;
    use RefreshDatabase;

    /**
     * An inspection on the given day. Score: no overrides is 5.0, one fail 4.0,
     * one partial 4.5.
     *
     * @param  array<string, string>  $results
     */
    private function inspect(Vendor $vendor, string $day, array $results = []): HygieneChecklist
    {
        // Midday, so the date survives the UTC conversion in the JSON output.
        $this->travelTo(Carbon::parse("{$day} 12:00"));

        $checklist = $vendor->checklists()->create($results + array_fill_keys(HygieneChecklist::CRITERIA, 'pass'));

        $this->travelBack();

        return $checklist;
    }

    private function like(DailyStatus $status, User $by): void
    {
        $status->likes()->create(['user_id' => $by->id]);
    }

    private function comment(DailyStatus $status, User $by, string $body = 'Nice'): void
    {
        $status->comments()->create(['user_id' => $by->id, 'body' => $body]);
    }

    private function owner(Vendor $vendor): User
    {
        return tap($vendor->user, fn (User $owner) => Sanctum::actingAs($owner));
    }

    // ---- access ----------------------------------------------------------

    public function test_the_owner_can_read_their_analytics(): void
    {
        $vendor = Vendor::factory()->create();
        $this->owner($vendor);

        $this->getJson("/api/vendors/{$vendor->id}/analytics")
            ->assertOk()
            ->assertJsonStructure(['data' => [
                'vendor_id',
                'rating' => ['average', 'count'],
                'hygiene_trend',
                'engagement' => ['views', 'likes', 'comments', 'statuses'],
            ]])
            ->assertJsonPath('data.vendor_id', $vendor->id);
    }

    public function test_someone_else_gets_403_whatever_their_role(): void
    {
        $vendor = Vendor::factory()->create();
        $rival = Vendor::factory()->create();

        foreach ([
            User::factory()->create(),
            User::factory()->inspector()->create(),
            $rival->user,
        ] as $caller) {
            Sanctum::actingAs($caller);

            $this->getJson("/api/vendors/{$vendor->id}/analytics")->assertForbidden();
        }
    }

    public function test_a_signed_out_caller_gets_401(): void
    {
        $vendor = Vendor::factory()->create();

        $this->getJson("/api/vendors/{$vendor->id}/analytics")->assertUnauthorized();
    }

    public function test_an_unknown_stall_is_404(): void
    {
        Sanctum::actingAs(User::factory()->vendor()->create());

        $this->getJson('/api/vendors/999999/analytics')->assertNotFound();
    }

    // ---- rating -----------------------------------------------------------

    public function test_the_rating_is_the_stored_snapshot_not_a_recalculation(): void
    {
        // No review rows exist, so a recalculation could not produce these numbers.
        $vendor = Vendor::factory()->create();
        $vendor->forceFill(['rating_average' => 4.25, 'reviews_count' => 8])->save();
        $this->owner($vendor);

        $this->getJson("/api/vendors/{$vendor->id}/analytics")
            ->assertJsonPath('data.rating.average', 4.25)
            ->assertJsonPath('data.rating.count', 8);
    }

    public function test_a_stall_with_no_history_returns_empty_values_not_errors(): void
    {
        $vendor = Vendor::factory()->create();
        $this->owner($vendor);

        $this->getJson("/api/vendors/{$vendor->id}/analytics")
            ->assertOk()
            ->assertJsonPath('data.rating.average', null)
            ->assertJsonPath('data.rating.count', 0)
            ->assertJsonPath('data.hygiene_trend', [])
            ->assertJsonPath('data.engagement.likes', 0)
            ->assertJsonPath('data.engagement.comments', 0)
            ->assertJsonPath('data.engagement.statuses', 0);
    }

    // ---- hygiene trend ----------------------------------------------------

    public function test_the_trend_lists_inspection_scores_oldest_first(): void
    {
        $vendor = Vendor::factory()->create();
        // Created out of order on purpose: the trend follows the inspection date.
        $this->inspect($vendor, '2026-03-10');
        $this->inspect($vendor, '2026-03-01', ['waste_disposal' => 'fail']);
        $this->inspect($vendor, '2026-03-20', ['food_covering' => 'partial']);
        $this->owner($vendor);

        $trend = $this->getJson("/api/vendors/{$vendor->id}/analytics")
            ->assertJsonCount(3, 'data.hygiene_trend')
            ->assertJsonStructure(['data' => ['hygiene_trend' => [['inspected_at', 'score', 'grade']]]])
            ->json('data.hygiene_trend');

        $this->assertEquals([4.0, 5.0, 4.5], array_column($trend, 'score'));
        $this->assertSame(
            ['2026-03-01', '2026-03-10', '2026-03-20'],
            array_map(fn (array $point) => substr($point['inspected_at'], 0, 10), $trend),
        );
    }

    public function test_the_trend_is_capped_at_the_latest_ten_inspections(): void
    {
        $vendor = Vendor::factory()->create();

        // Twelve inspections: the two oldest fail everything (0.0), the rest pass.
        foreach (range(0, 11) as $i) {
            $this->inspect(
                $vendor,
                Carbon::parse('2026-01-01')->addDays($i)->toDateString(),
                $i < 2 ? array_fill_keys(HygieneChecklist::CRITERIA, 'fail') : [],
            );
        }

        $this->owner($vendor);

        $trend = $this->getJson("/api/vendors/{$vendor->id}/analytics")
            ->assertJsonCount(10, 'data.hygiene_trend')
            ->json('data.hygiene_trend');

        // The two failing inspections were the oldest, so they fell off the front.
        $this->assertEquals(array_fill(0, 10, 5.0), array_column($trend, 'score'));
        $this->assertSame('2026-01-03', substr($trend[0]['inspected_at'], 0, 10));
        $this->assertSame('2026-01-12', substr($trend[9]['inspected_at'], 0, 10));
    }

    public function test_the_trend_only_holds_this_stalls_inspections(): void
    {
        $vendor = Vendor::factory()->create();
        $other = Vendor::factory()->create();
        $this->inspect($vendor, '2026-03-01');
        $this->inspect($other, '2026-03-02', ['water_source' => 'fail']);
        $this->owner($vendor);

        $this->getJson("/api/vendors/{$vendor->id}/analytics")->assertJsonCount(1, 'data.hygiene_trend');
    }

    // ---- engagement -------------------------------------------------------

    public function test_views_are_reported_as_null_because_nothing_tracks_them(): void
    {
        $vendor = Vendor::factory()->create();
        $this->owner($vendor);

        $engagement = $this->getJson("/api/vendors/{$vendor->id}/analytics")->json('data.engagement');

        $this->assertArrayHasKey('views', $engagement);
        $this->assertNull($engagement['views']);
    }

    public function test_likes_and_comments_are_totalled_across_the_owners_own_statuses(): void
    {
        $vendor = Vendor::factory()->create();
        $owner = $vendor->user;
        $fanA = User::factory()->create();
        $fanB = User::factory()->create();

        $first = $this->statusBy($owner, 'Fresh rotti', ['vendor_id' => $vendor->id]);
        $second = $this->statusBy($owner, 'Open late', ['vendor_id' => $vendor->id]);
        $this->like($first, $fanA);
        $this->like($first, $fanB);
        $this->like($second, $fanA);
        $this->comment($first, $fanA);
        $this->comment($second, $fanA);
        $this->comment($second, $fanB);

        $this->owner($vendor);

        $this->getJson("/api/vendors/{$vendor->id}/analytics")
            ->assertJsonPath('data.engagement.statuses', 2)
            ->assertJsonPath('data.engagement.likes', 3)
            ->assertJsonPath('data.engagement.comments', 3);
    }

    public function test_other_peoples_statuses_are_not_counted_even_when_they_tag_the_stall(): void
    {
        $vendor = Vendor::factory()->create();
        $fan = User::factory()->create();

        $mine = $this->statusBy($vendor->user, 'Ours', ['vendor_id' => $vendor->id]);
        $tagged = $this->statusBy($fan, 'At the stall today', ['vendor_id' => $vendor->id]);
        $rivals = $this->statusBy(Vendor::factory()->create()->user, 'Someone else');
        $this->like($mine, $fan);
        $this->like($tagged, $fan);
        $this->like($rivals, $fan);

        $this->owner($vendor);

        $this->getJson("/api/vendors/{$vendor->id}/analytics")
            ->assertJsonPath('data.engagement.statuses', 1)
            ->assertJsonPath('data.engagement.likes', 1);
    }

    public function test_hidden_statuses_and_hidden_comments_are_left_out_like_in_the_feed(): void
    {
        $vendor = Vendor::factory()->create();
        $fan = User::factory()->create();
        $suspended = User::factory()->create(['is_active' => false]);
        $moderator = User::factory()->create();

        $shown = $this->statusBy($vendor->user, 'Shown');
        $hidden = $this->statusBy($vendor->user, 'Hidden by a moderator');
        $hidden->hideBy($moderator, 'spam');
        $this->like($hidden, $fan);

        $this->comment($shown, $fan, 'Counted');
        $this->comment($shown, $suspended, 'Author suspended');
        $this->comment($shown, $fan, 'Hidden one');
        $shown->comments()->where('body', 'Hidden one')->first()->hideBy($moderator);

        $this->owner($vendor);

        $this->getJson("/api/vendors/{$vendor->id}/analytics")
            ->assertJsonPath('data.engagement.statuses', 1)
            ->assertJsonPath('data.engagement.likes', 0)
            ->assertJsonPath('data.engagement.comments', 1);
    }
}
