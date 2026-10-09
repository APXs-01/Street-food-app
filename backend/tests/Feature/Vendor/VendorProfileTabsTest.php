<?php

namespace Tests\Feature\Vendor;

use App\Enums\CheckResult;
use App\Models\Review;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class VendorProfileTabsTest extends TestCase
{
    use RefreshDatabase;

    private function inspect(Vendor $vendor): void
    {
        $inspector = User::factory()->inspector()->create();
        $inspector->inspectorProfile()->create([
            'organization' => 'Colombo Municipal Health Council',
            'official_id' => 'PHI-001',
        ]);

        $checklist = $vendor->checklists()->create([
            'water_source' => CheckResult::Pass,
            'utensil_glove_hygiene' => CheckResult::Pass,
            'waste_disposal' => CheckResult::Pass,
            'food_covering' => CheckResult::Partial,
            'overall_cleanliness' => CheckResult::Fail,
        ]);

        $checklist->submission()->create([
            'inspector_id' => $inspector->id,
            'notes' => 'Keep the food covered during rush hour.',
            'evidence_photo_path' => 'inspections/evidence.jpg',
        ]);

        $vendor->applyChecklist($checklist);
    }

    public function test_an_uninspected_stall_shows_not_inspected_with_no_breakdown(): void
    {
        $vendor = Vendor::factory()->create();
        Sanctum::actingAs(User::factory()->create());

        $this->getJson("/api/vendors/{$vendor->id}/hygiene")
            ->assertOk()
            ->assertJsonPath('data.status', 'not_inspected')
            ->assertJsonPath('data.grade', null)
            ->assertJsonPath('data.inspection', null);
    }

    public function test_the_breakdown_shows_each_criterion_from_the_latest_inspection(): void
    {
        $vendor = Vendor::factory()->create();
        $this->inspect($vendor);
        Sanctum::actingAs(User::factory()->create());

        $response = $this->getJson("/api/vendors/{$vendor->id}/hygiene")
            ->assertOk()
            ->assertJsonPath('data.status', 'verified')
            ->assertJsonPath('data.grade', 'A')
            ->assertJsonPath('data.water_source_verified', true)
            ->assertJsonPath('data.inspection.organization', 'Colombo Municipal Health Council')
            ->assertJsonPath('data.inspection.notes', 'Keep the food covered during rush hour.')
            ->assertJsonCount(5, 'data.inspection.criteria')
            ->assertJsonPath('data.inspection.criteria.0', ['key' => 'water_source', 'result' => 'pass'])
            ->assertJsonPath('data.inspection.criteria.3', ['key' => 'food_covering', 'result' => 'partial'])
            ->assertJsonPath('data.inspection.criteria.4', ['key' => 'overall_cleanliness', 'result' => 'fail']);

        $this->assertEquals(3.5, $response->json('data.score'));
    }

    public function test_an_overdue_rating_stays_visible_as_reverification_pending(): void
    {
        $vendor = Vendor::factory()->create();
        $this->inspect($vendor);
        Sanctum::actingAs(User::factory()->create());

        $this->travelTo(now()->addDays(31));

        $this->getJson("/api/vendors/{$vendor->id}/hygiene")
            ->assertOk()
            ->assertJsonPath('data.status', 'reverification_pending')
            ->assertJsonPath('data.grade', 'A');
    }

    public function test_the_reviews_tab_uses_the_snapshot_and_hides_moderated_and_anonymous_details(): void
    {
        $vendor = Vendor::factory()->create();

        $anonymous = User::factory()->create(['name' => 'Secret Sally']);
        $named = User::factory()->create(['name' => 'Visible Vic']);
        $hiddenAuthor = User::factory()->create(['name' => 'Hidden Hank']);

        Review::create([
            'vendor_id' => $vendor->id,
            'user_id' => $anonymous->id,
            'rating' => 5,
            'comment' => 'Spotless counter.',
            'is_anonymous' => true,
        ]);

        $withPhoto = Review::create([
            'vendor_id' => $vendor->id,
            'user_id' => $named->id,
            'rating' => 3,
            'comment' => 'Average.',
        ]);
        $withPhoto->photos()->create(['path' => 'reviews/one.jpg']);

        $hidden = Review::create([
            'vendor_id' => $vendor->id,
            'user_id' => $hiddenAuthor->id,
            'rating' => 1,
            'comment' => 'Removed by a moderator.',
        ]);
        $hidden->forceFill(['is_hidden' => true])->save();

        $vendor->refreshRatingSnapshot();
        Sanctum::actingAs(User::factory()->create());

        $response = $this->getJson("/api/vendors/{$vendor->id}/reviews")
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('summary.count', 2)
            ->assertJsonPath('photos.total', 1)
            ->assertSee('Visible Vic')
            ->assertDontSee('Secret Sally')
            ->assertDontSee('Hidden Hank');

        $this->assertEquals(4.0, $response->json('summary.average'));
        $this->assertEquals([5 => 1, 4 => 0, 3 => 1, 2 => 0, 1 => 0], $response->json('summary.distribution'));

        $this->getJson("/api/vendors/{$vendor->id}/reviews?with_photos=1")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.comment', 'Average.');
    }

    public function test_with_photos_accepts_true_false_1_and_0_and_rejects_anything_else(): void
    {
        $vendor = Vendor::factory()->create();

        $withPhoto = Review::create([
            'vendor_id' => $vendor->id,
            'user_id' => User::factory()->create()->id,
            'rating' => 4,
            'comment' => 'Has a photo.',
        ]);
        $withPhoto->photos()->create(['path' => 'reviews/a.jpg']);

        Review::create([
            'vendor_id' => $vendor->id,
            'user_id' => User::factory()->create()->id,
            'rating' => 5,
            'comment' => 'No photo.',
        ]);

        Sanctum::actingAs(User::factory()->create());

        foreach (['true', '1'] as $value) {
            $this->getJson("/api/vendors/{$vendor->id}/reviews?with_photos={$value}")
                ->assertOk()
                ->assertJsonCount(1, 'data');
        }

        foreach (['false', '0'] as $value) {
            $this->getJson("/api/vendors/{$vendor->id}/reviews?with_photos={$value}")
                ->assertOk()
                ->assertJsonCount(2, 'data');
        }

        $this->getJson("/api/vendors/{$vendor->id}/reviews?with_photos=maybe")
            ->assertUnprocessable()
            ->assertJsonValidationErrors('with_photos');
    }
}
