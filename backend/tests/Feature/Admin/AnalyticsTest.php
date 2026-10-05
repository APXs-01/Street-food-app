<?php

namespace Tests\Feature\Admin;

use App\Models\Review;
use App\Models\ReviewReport;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\Concerns\SignsInAdmin;
use Tests\TestCase;

class AnalyticsTest extends TestCase
{
    use RefreshDatabase;
    use SignsInAdmin;

    protected function setUp(): void
    {
        parent::setUp();

        $this->travelTo(Carbon::parse('2026-10-10 12:00', 'Asia/Colombo'));
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function stall(string $name, ?Carbon $due = null, array $attributes = []): Vendor
    {
        $snapshot = $due === null ? [] : [
            'hygiene_grade' => 'A',
            'hygiene_score' => 4.0,
            'last_inspected_at' => $due->copy()->subDays(30),
            'reverification_due_at' => $due,
        ];

        return Vendor::factory()->create(['name' => $name] + $attributes + $snapshot);
    }

    private function review(?Vendor $vendor, int $rating, ?User $author = null, string $comment = 'A review'): Review
    {
        return Review::create([
            'vendor_id' => ($vendor ?? Vendor::factory()->create())->id,
            'user_id' => ($author ?? User::factory()->create())->id,
            'rating' => $rating,
            'comment' => $comment,
        ]);
    }

    private function reports(Review $review, int $count): void
    {
        foreach (range(1, $count) as $i) {
            ReviewReport::create([
                'review_id' => $review->id,
                'reporter_id' => User::factory()->create()->id,
                'reason' => 'spam',
            ]);
        }
    }

    // ---- access ------------------------------------------------------------

    public function test_it_needs_an_admin_and_is_read_only(): void
    {
        $this->get('/admin/analytics')->assertRedirect(route('admin.login'));
        $this->actingAs(User::factory()->create())->get('/admin/analytics')->assertForbidden();

        $this->actingAsAdmin();

        $this->get('/admin/analytics')->assertOk()->assertSee('Analytics');
        $this->post('/admin/analytics', [])->assertStatus(405);
    }

    // ---- people and stalls ---------------------------------------------------

    public function test_accounts_are_split_into_active_and_suspended_by_role(): void
    {
        User::factory()->count(2)->create();
        User::factory()->create(['is_active' => false]);

        Vendor::factory()->create();
        Vendor::factory()->create()->user->forceFill(['is_active' => false])->save();

        User::factory()->inspector()->create();
        User::factory()->inspector()->create(['is_active' => false]);

        // Administrators are not counted anywhere.
        $this->actingAsAdmin()
            ->get('/admin/analytics')
            ->assertOk()
            ->assertViewHas('people', [
                'customers' => ['total' => 3, 'active' => 2, 'suspended' => 1],
                'vendors' => ['total' => 2, 'active' => 1, 'suspended' => 1],
                'inspectors' => ['total' => 2, 'active' => 1, 'suspended' => 1],
            ]);
    }

    public function test_a_role_with_no_suspended_accounts_shows_zero(): void
    {
        User::factory()->count(2)->create();

        $this->actingAsAdmin()
            ->get('/admin/analytics')
            ->assertViewHas('people', fn (array $people) => $people['customers'] === ['total' => 2, 'active' => 2, 'suspended' => 0]
                && $people['vendors'] === ['total' => 0, 'active' => 0, 'suspended' => 0]);
    }

    public function test_stalls_are_split_into_public_and_hidden(): void
    {
        $this->stall('One');
        $this->stall('Two');
        $this->stall('Three')->user->forceFill(['is_active' => false])->save();

        $this->actingAsAdmin()
            ->get('/admin/analytics')
            ->assertViewHas('stalls', ['listed' => 3, 'public' => 2, 'hidden' => 1]);
    }

    // ---- re-verification -----------------------------------------------------

    public function test_the_overdue_figures_use_the_shared_hygiene_scopes_and_add_up(): void
    {
        foreach (range(1, 12) as $days) {
            $this->stall("Overdue {$days}", now()->subDays($days));
        }
        $this->stall('Soon', now()->addDays(3));
        $this->stall('Later', now()->addDays(40));
        $this->stall('Never');

        $this->actingAsAdmin()
            ->get('/admin/analytics')
            ->assertOk()
            ->assertViewHas('hygiene', function (array $hygiene) {
                return $hygiene['overdue'] === 12
                    && $hygiene['overdue'] === Vendor::hygieneOverdue()->count()
                    && $hygiene['due_soon'] === 1
                    && $hygiene['current'] === 1
                    && $hygiene['not_inspected'] === 1
                    && $hygiene['overdue'] + $hygiene['due_soon'] + $hygiene['current'] + $hygiene['not_inspected'] === Vendor::count();
            });
    }

    public function test_it_lists_the_ten_longest_overdue_stalls_longest_first(): void
    {
        foreach (range(1, 12) as $days) {
            $this->stall("Overdue {$days}", now()->subDays($days));
        }

        $response = $this->actingAsAdmin()
            ->get('/admin/analytics')
            ->assertOk()
            ->assertSee('Showing 10 of 12')
            ->assertSee('12 days')
            ->assertSee(route('admin.hygiene.index', ['state' => 'overdue']), false);

        $names = $response->viewData('hygiene')['most_overdue']->pluck('name')->all();

        $this->assertCount(10, $names);
        $this->assertSame('Overdue 12', $names[0]);
        $this->assertSame('Overdue 3', $names[9]);
    }

    public function test_it_says_when_nothing_is_overdue(): void
    {
        $this->stall('Fine', now()->addDays(20));

        $this->actingAsAdmin()->get('/admin/analytics')->assertOk()->assertSee('Nothing is overdue.');
    }

    public function test_the_overdue_count_matches_the_dashboard(): void
    {
        $this->stall('Late', now()->subDays(4));
        $this->stall('Later', now()->subDays(9));
        $this->stall('Fine', now()->addDays(20));

        $this->actingAsAdmin();

        $analytics = $this->get('/admin/analytics')->viewData('hygiene')['overdue'];
        $dashboard = $this->get('/admin')->viewData('stats')['overdue'];

        $this->assertSame(2, $analytics);
        $this->assertSame($dashboard, $analytics);
    }

    // ---- most reported reviews ---------------------------------------------

    public function test_it_lists_the_ten_most_reported_reviews_most_reported_first(): void
    {
        $five = $this->review(null, 1, null, 'Reported five times');
        $three = $this->review(null, 1, null, 'Reported three times');
        $this->reports($five, 5);
        $this->reports($three, 3);

        foreach (range(1, 12) as $i) {
            $this->reports($this->review(null, 2, null, "Reported once {$i}"), 1);
        }

        $this->review(null, 5, null, 'Never reported');

        $response = $this->actingAsAdmin()
            ->get('/admin/analytics')
            ->assertOk()
            ->assertSee('Showing 10 of 14 reported reviews')
            ->assertSee('Reported five times')
            ->assertSee('Reported three times')
            ->assertDontSee('Never reported')
            ->assertSee(route('admin.reviews.show', $five), false)
            ->assertSee(route('admin.reviews.index', ['scope' => 'flagged']), false);

        $top = $response->viewData('reported')['top'];

        $this->assertCount(10, $top);
        $this->assertSame($five->id, $top[0]->id);
        $this->assertSame(5, $top[0]->reports_count);
        $this->assertSame($three->id, $top[1]->id);
        $this->assertSame(14, $response->viewData('reported')['total']);
    }

    public function test_reported_reviews_show_whether_they_are_hidden_or_by_a_suspended_author(): void
    {
        $hidden = $this->review(null, 1, null, 'A hidden one');
        $hidden->hideBy($this->makeAdmin());
        $bySuspended = $this->review(null, 1, null, 'From a suspended author');
        $bySuspended->user->forceFill(['is_active' => false])->save();
        $this->reports($hidden, 2);
        $this->reports($bySuspended, 1);

        $this->actingAsAdmin()
            ->get('/admin/analytics')
            ->assertSee('A hidden one')
            ->assertSee('From a suspended author')
            ->assertSee('Hidden')
            ->assertSee('Suspended');
    }

    public function test_it_says_when_nothing_is_reported(): void
    {
        $this->review(null, 4);

        $this->actingAsAdmin()->get('/admin/analytics')->assertSee('No review has been reported.');
    }

    // ---- average rating ------------------------------------------------------

    public function test_the_average_rating_is_the_mean_of_visible_reviews_with_their_count(): void
    {
        $stall = Vendor::factory()->create();
        $this->review($stall, 5);
        $this->review($stall, 4);
        $this->review($stall, 3);

        // Left out: hidden by a moderator, and written by a suspended account.
        $this->review($stall, 1)->hideBy($this->makeAdmin());
        $suspendedAuthor = User::factory()->create();
        $this->review($stall, 1, $suspendedAuthor);
        $suspendedAuthor->forceFill(['is_active' => false])->save();

        $this->actingAsAdmin()
            ->get('/admin/analytics')
            ->assertOk()
            ->assertViewHas('rating', ['average' => 4.0, 'count' => 3, 'excluded' => 2])
            ->assertSee('4.0')
            ->assertSee('from 3 reviews')
            ->assertSee('2 left out');
    }

    public function test_the_average_is_the_mean_of_reviews_not_of_stall_averages(): void
    {
        // One stall with ten 5-star reviews, another with a single 1-star review.
        $busy = Vendor::factory()->create();
        foreach (range(1, 10) as $i) {
            $this->review($busy, 5);
        }
        $this->review(Vendor::factory()->create(), 1);

        // The mean of the two stall averages would be 3.0; the mean of reviews is 51/11.
        $this->actingAsAdmin()
            ->get('/admin/analytics')
            ->assertViewHas('rating', ['average' => 4.6, 'count' => 11, 'excluded' => 0]);
    }

    public function test_the_figure_is_rounded_to_one_decimal_place(): void
    {
        $stall = Vendor::factory()->create();
        $this->review($stall, 5);
        $this->review($stall, 4);
        $this->review($stall, 4);

        $this->actingAsAdmin()->get('/admin/analytics')->assertViewHas('rating', fn (array $r) => $r['average'] === 4.3);
    }

    public function test_a_single_review_is_worded_in_the_singular(): void
    {
        $this->review(null, 5);

        $this->actingAsAdmin()
            ->get('/admin/analytics')
            ->assertSee('from 1 review')
            ->assertDontSee('1 reviews')
            ->assertSee('none are left out');
    }

    public function test_with_no_reviews_there_is_no_average(): void
    {
        $this->actingAsAdmin()
            ->get('/admin/analytics')
            ->assertViewHas('rating', ['average' => null, 'count' => 0, 'excluded' => 0])
            ->assertSee('No reviews yet');
    }

    public function test_moderation_and_suspension_move_the_figure_and_reversing_them_restores_it(): void
    {
        $stall = Vendor::factory()->create();
        $this->review($stall, 5);
        $doomed = $this->review($stall, 1);

        $this->actingAsAdmin();

        $this->get('/admin/analytics')->assertViewHas('rating', ['average' => 3.0, 'count' => 2, 'excluded' => 0]);

        $doomed->hideBy($this->makeAdmin());
        $this->get('/admin/analytics')->assertViewHas('rating', ['average' => 5.0, 'count' => 1, 'excluded' => 1]);

        $doomed->unhideBy($this->makeAdmin());
        $doomed->user->forceFill(['is_active' => false])->save();
        $this->get('/admin/analytics')->assertViewHas('rating', ['average' => 5.0, 'count' => 1, 'excluded' => 1]);

        $doomed->user->forceFill(['is_active' => true])->save();
        $this->get('/admin/analytics')->assertViewHas('rating', ['average' => 3.0, 'count' => 2, 'excluded' => 0]);
    }

    public function test_it_agrees_with_the_definition_the_public_api_uses(): void
    {
        $stall = Vendor::factory()->create();
        foreach ([5, 4, 4, 2] as $rating) {
            $this->review($stall, $rating);
        }
        $this->review($stall, 1)->hideBy($this->makeAdmin());

        $expected = round((float) Review::visible()->avg('rating'), 1);

        $this->actingAsAdmin()
            ->get('/admin/analytics')
            ->assertViewHas('rating', fn (array $r) => $r['average'] === $expected && $r['count'] === Review::visible()->count());
    }
}
