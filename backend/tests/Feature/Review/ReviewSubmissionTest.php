<?php

namespace Tests\Feature\Review;

use App\Enums\UserRole;
use App\Models\Review;
use App\Models\ReviewPhoto;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReviewSubmissionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');
    }

    private function consumer(): User
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        return $user;
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function submit(Vendor $vendor, array $data)
    {
        return $this->postJson("/api/vendors/{$vendor->id}/reviews", $data);
    }

    /**
     * One entry of the photos array.
     *
     * @param  array<string, mixed>  $details
     * @return array<string, mixed>
     */
    private function photo(array $details = []): array
    {
        return ['file' => UploadedFile::fake()->image('photo.jpg', 640, 480)] + $details;
    }

    private function storedFiles(): int
    {
        return count(Storage::disk('public')->allFiles());
    }

    public function test_a_customer_can_review_a_stall_and_the_star_rating_updates(): void
    {
        $vendor = Vendor::factory()->create();
        $author = $this->consumer();

        $this->submit($vendor, ['rating' => 4, 'comment' => 'Tasty and clean.'])
            ->assertCreated()
            ->assertJsonPath('data.rating', 4)
            ->assertJsonPath('data.comment', 'Tasty and clean.')
            ->assertJsonPath('data.author.name', $author->name)
            ->assertJsonPath('data.is_hidden', false);

        $vendor->refresh();

        $this->assertSame(1, $vendor->reviews_count);
        $this->assertEquals(4.0, $vendor->rating_average);
    }

    public function test_the_star_rating_is_the_average_of_visible_reviews(): void
    {
        $vendor = Vendor::factory()->create();

        $this->consumer();
        $this->submit($vendor, ['rating' => 5])->assertCreated();

        $this->consumer();
        $this->submit($vendor, ['rating' => 2])->assertCreated();

        $this->assertEquals(3.5, $vendor->fresh()->rating_average);
    }

    public function test_the_comment_is_optional(): void
    {
        $vendor = Vendor::factory()->create();
        $this->consumer();

        $this->submit($vendor, ['rating' => 5])
            ->assertCreated()
            ->assertJsonPath('data.comment', null);
    }

    public function test_a_second_submission_updates_the_existing_review(): void
    {
        $vendor = Vendor::factory()->create();
        $this->consumer();

        $first = $this->submit($vendor, ['rating' => 4, 'comment' => 'Tasty and clean.'])->assertCreated();

        // Only the rating is resubmitted: the comment is kept.
        $this->submit($vendor, ['rating' => 2])
            ->assertOk()
            ->assertJsonPath('data.id', $first->json('data.id'))
            ->assertJsonPath('data.rating', 2)
            ->assertJsonPath('data.comment', 'Tasty and clean.')
            ->assertJsonPath('message', 'Your existing review for this stall was updated.');

        $this->assertDatabaseCount('reviews', 1);
        $this->assertEquals(2.0, $vendor->fresh()->rating_average);
    }

    public function test_the_rating_must_be_between_one_and_five(): void
    {
        $vendor = Vendor::factory()->create();
        $this->consumer();

        foreach ([0, 6, 'abc', null] as $rating) {
            $this->submit($vendor, ['rating' => $rating])
                ->assertUnprocessable()
                ->assertJsonValidationErrors('rating');
        }

        $this->submit($vendor, [])->assertUnprocessable()->assertJsonValidationErrors('rating');
    }

    public function test_only_active_customers_can_review(): void
    {
        $vendor = Vendor::factory()->create();

        foreach ([User::factory()->vendor()->create(), User::factory()->inspector()->create(), User::factory()->create(['is_active' => false])] as $user) {
            Sanctum::actingAs($user);
            $this->submit($vendor, ['rating' => 5])->assertForbidden();
        }

        $this->assertDatabaseCount('reviews', 0);
    }

    public function test_photos_are_stored_with_their_own_device_capture_details(): void
    {
        $this->travelTo(Carbon::parse('2026-10-05 20:00', 'Asia/Colombo'));

        $vendor = Vendor::factory()->create();
        $this->consumer();

        $capturedAt = now()->subMinutes(5);

        $this->submit($vendor, [
            'rating' => 5,
            'photos' => [
                $this->photo(['capture_time' => $capturedAt->toIso8601String(), 'latitude' => 6.9271, 'longitude' => 79.8612]),
                $this->photo(),
            ],
        ])
            ->assertCreated()
            ->assertJsonCount(2, 'data.photos');

        $this->assertDatabaseCount('review_photos', 2);

        $withDetails = ReviewPhoto::whereNotNull('capture_time')->firstOrFail();
        $without = ReviewPhoto::whereNull('capture_time')->firstOrFail();

        Storage::disk('public')->assertExists($withDetails->path);
        Storage::disk('public')->assertExists($without->path);
        $this->assertTrue($withDetails->capture_time->equalTo($capturedAt));
        $this->assertEquals(6.9271, $withDetails->latitude);
        // The server upload time is the source of truth.
        $this->assertTrue($withDetails->created_at->equalTo(now()));
    }

    public function test_at_most_three_photos_can_be_sent(): void
    {
        $vendor = Vendor::factory()->create();
        $this->consumer();

        $this->submit($vendor, ['rating' => 5, 'photos' => [$this->photo(), $this->photo(), $this->photo()]])
            ->assertCreated()
            ->assertJsonCount(3, 'data.photos');

        $another = Vendor::factory()->create();

        $this->submit($another, ['rating' => 5, 'photos' => [$this->photo(), $this->photo(), $this->photo(), $this->photo()]])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('photos');
    }

    public function test_one_stale_photo_rejects_the_whole_submission_and_names_it(): void
    {
        $this->travelTo(Carbon::parse('2026-10-05 20:00', 'Asia/Colombo'));

        $vendor = Vendor::factory()->create();
        $this->consumer();

        $response = $this->submit($vendor, [
            'rating' => 5,
            'photos' => [
                $this->photo(['capture_time' => now()->subMinutes(2)->toIso8601String()]),
                $this->photo(['capture_time' => now()->subMinutes(11)->toIso8601String()]),
            ],
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('photos.1.capture_time')
            ->assertJsonMissingValidationErrors('photos.0.capture_time');

        $this->assertStringContainsString('Photo 2', $response->json('errors')['photos.1.capture_time'][0]);

        // Nothing was saved, not even the fresh photo or the rating.
        $this->assertDatabaseCount('reviews', 0);
        $this->assertDatabaseCount('review_photos', 0);
        $this->assertSame(0, $this->storedFiles());
    }

    public function test_every_stale_photo_is_reported(): void
    {
        $this->travelTo(Carbon::parse('2026-10-05 20:00', 'Asia/Colombo'));

        $vendor = Vendor::factory()->create();
        $this->consumer();

        $stale = now()->subMinutes(30)->toIso8601String();

        $this->submit($vendor, [
            'rating' => 5,
            'photos' => [$this->photo(['capture_time' => $stale]), $this->photo(['capture_time' => $stale])],
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['photos.0.capture_time', 'photos.1.capture_time']);
    }

    public function test_a_photo_taken_exactly_ten_minutes_ago_is_still_accepted(): void
    {
        $this->travelTo(Carbon::parse('2026-10-05 20:00', 'Asia/Colombo'));

        $vendor = Vendor::factory()->create();
        $this->consumer();

        $this->submit($vendor, [
            'rating' => 5,
            'photos' => [$this->photo(['capture_time' => now()->subMinutes(10)->toIso8601String()])],
        ])->assertCreated();
    }

    public function test_new_photos_are_added_to_the_existing_ones_up_to_the_limit(): void
    {
        $vendor = Vendor::factory()->create();
        $this->consumer();

        $this->submit($vendor, ['rating' => 5, 'photos' => [$this->photo(), $this->photo()]])->assertCreated();

        // Two more would make four: rejected, and nothing changes.
        $this->submit($vendor, ['rating' => 4, 'photos' => [$this->photo(), $this->photo()]])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('photos');

        $this->assertDatabaseCount('review_photos', 2);
        $this->assertSame(2, $this->storedFiles());
        $this->assertSame(5, Review::firstOrFail()->rating);

        // One more makes three.
        $this->submit($vendor, ['rating' => 4, 'photos' => [$this->photo()]])
            ->assertOk()
            ->assertJsonCount(3, 'data.photos');
    }

    public function test_photos_can_be_removed_by_id_or_all_at_once(): void
    {
        $vendor = Vendor::factory()->create();
        $this->consumer();

        $review = $this->submit($vendor, ['rating' => 5, 'photos' => [$this->photo(), $this->photo(), $this->photo()]])
            ->assertCreated();
        $reviewId = $review->json('data.id');

        $victim = ReviewPhoto::firstOrFail();

        // Remove one and add one in the same edit: still within the limit.
        $this->patchJson("/api/reviews/{$reviewId}", [
            'remove_photo_ids' => [$victim->id],
            'photos' => [$this->photo()],
        ])->assertOk()->assertJsonCount(3, 'data.photos');

        $this->assertDatabaseMissing('review_photos', ['id' => $victim->id]);
        Storage::disk('public')->assertMissing($victim->path);

        $this->patchJson("/api/reviews/{$reviewId}", ['remove_photos' => true])
            ->assertOk()
            ->assertJsonCount(0, 'data.photos');

        $this->assertDatabaseCount('review_photos', 0);
        $this->assertSame(0, $this->storedFiles());
    }

    public function test_photos_from_another_review_cannot_be_removed(): void
    {
        $vendor = Vendor::factory()->create();

        $this->consumer();
        $this->submit($vendor, ['rating' => 5, 'photos' => [$this->photo()]])->assertCreated();
        $othersPhoto = ReviewPhoto::firstOrFail();

        $this->consumer();
        $mine = $this->submit($vendor, ['rating' => 4])->assertCreated()->json('data.id');

        $this->patchJson("/api/reviews/{$mine}", ['remove_photo_ids' => [$othersPhoto->id]])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('remove_photo_ids');

        $this->assertDatabaseHas('review_photos', ['id' => $othersPhoto->id]);
    }

    public function test_observations_are_validated_against_the_configured_options(): void
    {
        $vendor = Vendor::factory()->create();
        $this->consumer();

        $this->submit($vendor, ['rating' => 5, 'observations' => ['clean_area', 'gloves_worn']])
            ->assertCreated()
            ->assertJsonPath('data.observations', ['clean_area', 'gloves_worn']);

        $this->submit($vendor, ['rating' => 5, 'observations' => ['contaminated']])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('observations.0');

        $this->submit($vendor, ['rating' => 5, 'observations' => ['clean_area', 'clean_area']])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('observations.0');
    }

    public function test_only_the_author_can_edit_or_delete_a_review(): void
    {
        $vendor = Vendor::factory()->create();
        $author = $this->consumer();
        $id = $this->submit($vendor, ['rating' => 4, 'comment' => 'Original.'])->json('data.id');

        Sanctum::actingAs(User::factory()->create());
        $this->patchJson("/api/reviews/{$id}", ['comment' => 'Hijacked'])->assertForbidden();
        $this->deleteJson("/api/reviews/{$id}")->assertForbidden();

        Sanctum::actingAs($author);
        $this->patchJson("/api/reviews/{$id}", ['comment' => 'Edited.'])
            ->assertOk()
            ->assertJsonPath('data.comment', 'Edited.')
            ->assertJsonPath('data.rating', 4);
    }

    public function test_deleting_a_review_removes_its_photos_and_recalculates_the_rating(): void
    {
        $vendor = Vendor::factory()->create();
        $this->consumer();

        $id = $this->submit($vendor, ['rating' => 5, 'photos' => [$this->photo(), $this->photo()]])->json('data.id');
        $this->assertSame(2, $this->storedFiles());

        $this->deleteJson("/api/reviews/{$id}")->assertNoContent();

        $this->assertDatabaseCount('reviews', 0);
        $this->assertDatabaseCount('review_photos', 0);
        $this->assertSame(0, $this->storedFiles());

        $vendor->refresh();
        $this->assertSame(0, $vendor->reviews_count);
        $this->assertNull($vendor->rating_average);
    }

    public function test_the_customer_can_fetch_their_own_review(): void
    {
        $vendor = Vendor::factory()->create();
        $this->consumer();

        $this->getJson("/api/vendors/{$vendor->id}/reviews/mine")->assertNotFound();

        $this->submit($vendor, ['rating' => 3, 'comment' => 'Fine.'])->assertCreated();

        $this->getJson("/api/vendors/{$vendor->id}/reviews/mine")
            ->assertOk()
            ->assertJsonPath('data.comment', 'Fine.');

        // Someone else's review is never returned.
        Sanctum::actingAs(User::factory()->create());
        $this->getJson("/api/vendors/{$vendor->id}/reviews/mine")->assertNotFound();
    }

    public function test_editing_a_hidden_review_does_not_unhide_it(): void
    {
        $vendor = Vendor::factory()->create();
        $author = $this->consumer();
        $moderator = User::factory()->withRole(UserRole::SuperAdmin)->create();

        $review = Review::create([
            'vendor_id' => $vendor->id,
            'user_id' => $author->id,
            'rating' => 5,
            'comment' => 'Flagged by a moderator.',
        ]);
        $review->forceFill([
            'is_hidden' => true,
            'hidden_reason' => 'spam',
            'moderated_by' => $moderator->id,
            'moderated_at' => now(),
        ])->save();
        $vendor->refreshRatingSnapshot();

        $this->assertSame(0, $vendor->fresh()->reviews_count);

        // The author edits, and even tries to clear the moderation fields.
        $this->patchJson("/api/reviews/{$review->id}", [
            'rating' => 2,
            'comment' => 'Edited.',
            'is_hidden' => false,
            'hidden_reason' => null,
            'moderated_by' => null,
        ])
            ->assertOk()
            ->assertJsonPath('data.rating', 2)
            ->assertJsonPath('data.is_hidden', true);

        // Resubmitting through the create endpoint is also an edit.
        $this->submit($vendor, ['rating' => 3])->assertOk()->assertJsonPath('data.is_hidden', true);

        $review->refresh();

        $this->assertTrue($review->is_hidden);
        $this->assertSame('spam', $review->hidden_reason);
        $this->assertSame($moderator->id, $review->moderated_by);
        $this->assertNotNull($review->moderated_at);
        $this->assertSame(3, $review->rating);

        // It stays out of the stall's rating.
        $vendor->refresh();
        $this->assertSame(0, $vendor->reviews_count);
        $this->assertNull($vendor->rating_average);
    }
}
