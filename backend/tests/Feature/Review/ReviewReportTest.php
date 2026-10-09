<?php

namespace Tests\Feature\Review;

use App\Models\Review;
use App\Models\ReviewReport;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReviewReportTest extends TestCase
{
    use RefreshDatabase;

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function review(?Vendor $vendor = null, array $attributes = []): Review
    {
        $vendor ??= Vendor::factory()->create();

        return Review::create($attributes + [
            'vendor_id' => $vendor->id,
            'user_id' => User::factory()->create()->id,
            'rating' => 1,
            'comment' => 'Awful',
        ]);
    }

    public function test_a_customer_can_report_a_review(): void
    {
        $review = $this->review();
        $reporter = User::factory()->create();
        Sanctum::actingAs($reporter);

        $this->postJson("/api/reviews/{$review->id}/report", ['reason' => 'spam', 'details' => 'Looks like an advert'])
            ->assertCreated()
            ->assertJsonPath('message', 'Thank you. A moderator will look at this review.');

        $report = ReviewReport::sole();

        $this->assertSame($review->id, $report->review_id);
        $this->assertSame($reporter->id, $report->reporter_id);
        $this->assertSame('spam', $report->reason);
        $this->assertSame('Looks like an advert', $report->details);
    }

    public function test_reporting_twice_is_harmless_and_the_first_report_stands(): void
    {
        $review = $this->review();
        Sanctum::actingAs(User::factory()->create());

        $this->postJson("/api/reviews/{$review->id}/report", ['reason' => 'spam'])->assertCreated();
        $this->postJson("/api/reviews/{$review->id}/report", ['reason' => 'offensive_language'])->assertOk();

        $this->assertDatabaseCount('review_reports', 1);
        $this->assertSame('spam', ReviewReport::sole()->reason);
    }

    public function test_the_stall_owner_can_report_a_review_of_their_stall(): void
    {
        $stall = Vendor::factory()->create();
        $review = $this->review($stall);
        Sanctum::actingAs($stall->user);

        $this->postJson("/api/reviews/{$review->id}/report", ['reason' => 'unfair_or_fake'])->assertCreated();
    }

    public function test_nobody_reports_their_own_review(): void
    {
        $review = $this->review();
        Sanctum::actingAs($review->user);

        $this->postJson("/api/reviews/{$review->id}/report", ['reason' => 'spam'])->assertForbidden();

        $this->assertDatabaseCount('review_reports', 0);
    }

    public function test_inspectors_and_suspended_accounts_cannot_report(): void
    {
        $review = $this->review();

        foreach ([User::factory()->inspector()->create(), User::factory()->create(['is_active' => false])] as $user) {
            Sanctum::actingAs($user);
            $this->postJson("/api/reviews/{$review->id}/report", ['reason' => 'spam'])->assertForbidden();
        }

        $this->assertDatabaseCount('review_reports', 0);
    }

    public function test_the_reason_must_come_from_the_list_and_details_are_capped(): void
    {
        $review = $this->review();
        Sanctum::actingAs(User::factory()->create());

        $this->postJson("/api/reviews/{$review->id}/report", [])
            ->assertUnprocessable()->assertJsonValidationErrors('reason');
        $this->postJson("/api/reviews/{$review->id}/report", ['reason' => 'because'])
            ->assertUnprocessable()->assertJsonValidationErrors('reason');
        $this->postJson("/api/reviews/{$review->id}/report", ['reason' => 'other', 'details' => str_repeat('a', 301)])
            ->assertUnprocessable()->assertJsonValidationErrors('details');

        $this->assertDatabaseCount('review_reports', 0);
    }

    public function test_a_review_the_public_cannot_see_cannot_be_reported(): void
    {
        $hidden = $this->review();
        $hidden->hideBy(User::factory()->create(), 'spam');

        $suspendedAuthor = $this->review();
        $suspendedAuthor->user->forceFill(['is_active' => false])->save();

        Sanctum::actingAs(User::factory()->create());

        $this->postJson("/api/reviews/{$hidden->id}/report", ['reason' => 'spam'])->assertNotFound();
        $this->postJson("/api/reviews/{$suspendedAuthor->id}/report", ['reason' => 'spam'])->assertNotFound();
        $this->postJson('/api/reviews/999999/report', ['reason' => 'spam'])->assertNotFound();

        $this->assertDatabaseCount('review_reports', 0);
    }

    public function test_it_needs_a_token(): void
    {
        $review = $this->review();

        $this->postJson("/api/reviews/{$review->id}/report", ['reason' => 'spam'])->assertUnauthorized();
    }

    public function test_a_report_does_not_change_what_the_public_sees_or_who_reported(): void
    {
        $stall = Vendor::factory()->create();
        $review = $this->review($stall);
        $reporter = User::factory()->create(['name' => 'Reporting Rita']);

        Sanctum::actingAs($reporter);
        $this->postJson("/api/reviews/{$review->id}/report", ['reason' => 'spam', 'details' => 'Suspicious'])->assertCreated();

        $this->getJson("/api/vendors/{$stall->id}/reviews")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertDontSee('Reporting Rita')
            ->assertDontSee('Suspicious');
    }

    public function test_one_account_cannot_flood_the_moderators(): void
    {
        $stall = Vendor::factory()->create();
        Sanctum::actingAs(User::factory()->create());

        foreach (range(1, 20) as $i) {
            $review = $this->review($stall);
            $this->postJson("/api/reviews/{$review->id}/report", ['reason' => 'spam'])->assertCreated();
        }

        $review = $this->review($stall);
        $this->postJson("/api/reviews/{$review->id}/report", ['reason' => 'spam'])->assertStatus(429);
    }
}
