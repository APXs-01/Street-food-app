<?php

namespace Tests\Feature\Admin;

use App\Enums\CheckResult;
use App\Models\Category;
use App\Models\DailyStatus;
use App\Models\HygieneChecklist;
use App\Models\Review;
use App\Models\User;
use App\Models\Vendor;
use App\Services\VendorDeletion;
use Database\Seeders\CategorySeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use RuntimeException;
use Tests\Concerns\SignsInAdmin;
use Tests\TestCase;

class VendorManagementTest extends TestCase
{
    use RefreshDatabase;
    use SignsInAdmin;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');
    }

    /**
     * A stall with something in every table that hangs off it, and a real file
     * on the fake disk for every image column.
     *
     * @return array<string, mixed>
     */
    private function richStall(string $label): array
    {
        $files = [];
        $keep = function (string $path) use (&$files): string {
            Storage::disk('public')->put($path, 'x');

            return $files[] = $path;
        };

        $owner = User::factory()->vendor()->create();
        $stall = Vendor::factory()->create([
            'user_id' => $owner->id,
            'name' => "{$label} Stall",
            'cover_photo_path' => $keep("vendors/covers/{$label}.jpg"),
        ]);

        $category = Category::create(['name' => "Kottu {$label}", 'slug' => "kottu-{$label}"]);
        $stall->categories()->attach($category);

        $followers = User::factory()->count(2)->create();
        $stall->followers()->attach($followers->pluck('id'));

        $menu = [
            $stall->menuItems()->create(['name' => 'Kottu', 'price' => 450, 'photo_path' => $keep("menu/{$label}-1.jpg")]),
            $stall->menuItems()->create(['name' => 'Hopper', 'price' => 120, 'photo_path' => $keep("menu/{$label}-2.jpg")]),
        ];

        $inspector = User::factory()->inspector()->create();
        $checklist = $stall->checklists()->create(array_fill_keys(HygieneChecklist::CRITERIA, CheckResult::Pass));
        $submission = $checklist->submission()->create([
            'inspector_id' => $inspector->id,
            'evidence_photo_path' => $keep("inspections/{$label}.jpg"),
        ]);
        $stall->applyChecklist($checklist);

        $reviews = [];
        foreach ([false, true] as $index => $hidden) {
            $review = Review::create([
                'vendor_id' => $stall->id,
                'user_id' => User::factory()->create()->id,
                'rating' => 4,
                'comment' => 'A review',
            ]);
            $review->photos()->create(['path' => $keep("reviews/{$label}-{$index}.jpg")]);

            if ($hidden) {
                $review->forceFill(['is_hidden' => true])->save();
            }

            $reviews[] = $review;
        }

        $fan = User::factory()->create();
        $ownStatus = DailyStatus::create([
            'user_id' => $owner->id,
            'vendor_id' => $stall->id,
            'body' => 'Fresh batch',
            'media_path' => $keep("statuses/{$label}.jpg"),
            'media_type' => 'image',
            'audience' => 'public',
        ]);
        $comment = $ownStatus->comments()->create(['user_id' => $fan->id, 'body' => 'Yum']);
        $like = $ownStatus->likes()->create(['user_id' => $fan->id]);

        $tagged = DailyStatus::create([
            'user_id' => User::factory()->create()->id,
            'vendor_id' => $stall->id,
            'body' => 'Loved it here',
            'audience' => 'public',
        ]);

        return compact('owner', 'stall', 'category', 'followers', 'menu', 'checklist', 'submission', 'reviews', 'ownStatus', 'comment', 'like', 'tagged', 'files');
    }

    // ---- access ------------------------------------------------------------

    public function test_it_needs_an_admin(): void
    {
        $stall = Vendor::factory()->create();

        $this->get('/admin/vendors')->assertRedirect(route('admin.login'));
        $this->get("/admin/vendors/{$stall->id}")->assertRedirect(route('admin.login'));
        $this->delete("/admin/vendors/{$stall->id}")->assertRedirect(route('admin.login'));

        $this->actingAs(User::factory()->create())->get('/admin/vendors')->assertForbidden();
        $this->actingAs(User::factory()->vendor()->create())
            ->delete("/admin/vendors/{$stall->id}", ['confirm_name' => $stall->name])
            ->assertForbidden();

        $this->assertModelExists($stall);
    }

    // ---- listing -----------------------------------------------------------

    public function test_it_lists_every_stall_including_hidden_ones(): void
    {
        $visible = Vendor::factory()->create(['name' => 'Alpha Stall']);
        $hidden = Vendor::factory()->create(['name' => 'Bravo Stall']);
        $hidden->user->forceFill(['is_active' => false])->save();

        $this->actingAsAdmin()
            ->get('/admin/vendors')
            ->assertOk()
            ->assertSee('Alpha Stall')
            ->assertSee('Bravo Stall')
            ->assertSee('Hidden')
            ->assertViewHas('vendors', fn ($vendors) => $vendors->total() === 2);
    }

    public function test_it_filters_by_public_or_hidden(): void
    {
        Vendor::factory()->create(['name' => 'Alpha Stall']);
        $hidden = Vendor::factory()->create(['name' => 'Bravo Stall']);
        $hidden->user->forceFill(['is_active' => false])->save();

        $this->actingAsAdmin()
            ->get('/admin/vendors?visibility=hidden')
            ->assertSee('Bravo Stall')
            ->assertDontSee('Alpha Stall');

        $this->get('/admin/vendors?visibility=public')
            ->assertSee('Alpha Stall')
            ->assertDontSee('Bravo Stall');
    }

    public function test_it_filters_by_hygiene_state(): void
    {
        Vendor::factory()->create(['name' => 'Untested Stall']);
        Vendor::factory()->create([
            'name' => 'Verified Stall',
            'hygiene_grade' => 'A',
            'hygiene_score' => 4.0,
            'last_inspected_at' => now()->subDays(5),
            'reverification_due_at' => now()->addDays(25),
        ]);
        Vendor::factory()->create([
            'name' => 'Overdue Stall',
            'hygiene_grade' => 'B',
            'hygiene_score' => 3.0,
            'last_inspected_at' => now()->subDays(40),
            'reverification_due_at' => now()->subDays(10),
        ]);

        $this->actingAsAdmin();

        $this->get('/admin/vendors?hygiene=not_inspected')->assertSee('Untested Stall')->assertDontSee('Verified Stall')->assertDontSee('Overdue Stall');
        $this->get('/admin/vendors?hygiene=verified')->assertSee('Verified Stall')->assertDontSee('Untested Stall')->assertDontSee('Overdue Stall');
        $this->get('/admin/vendors?hygiene=overdue')->assertSee('Overdue Stall')->assertDontSee('Untested Stall')->assertDontSee('Verified Stall');
    }

    public function test_it_searches_stall_and_owner_details(): void
    {
        $target = Vendor::factory()->create(['name' => 'Raju Kottu', 'address' => '14 Galle Road']);
        $target->forceFill(['stall_code' => 'VEND-0042'])->save();
        $target->user->forceFill(['name' => 'Raju Silva', 'email' => 'raju@example.com'])->save();
        Vendor::factory()->create(['name' => 'Someone Elses Stall']);

        $this->actingAsAdmin();

        foreach (['Raju Kottu', 'VEND-0042', 'Galle Road', 'Raju Silva', 'raju@example'] as $term) {
            $this->get('/admin/vendors?'.http_build_query(['q' => $term]))
                ->assertOk()
                ->assertSee('Raju Kottu')
                ->assertDontSee('Someone Elses Stall');
        }

        $this->get('/admin/vendors?q=zzzzzz')->assertSee('No stalls match.');
    }

    public function test_it_rejects_unknown_filters_and_paginates_with_them_kept(): void
    {
        $this->actingAsAdmin()->get('/admin/vendors?hygiene=nonsense&visibility=maybe')
            ->assertSessionHasErrors(['hygiene', 'visibility']);

        Vendor::factory()->count(30)->create();

        $this->get('/admin/vendors?hygiene=not_inspected')
            ->assertOk()
            ->assertViewHas('vendors', fn ($vendors) => $vendors->count() === 25 && $vendors->total() === 30)
            ->assertSee('hygiene=not_inspected&amp;page=2', false);
    }

    // ---- viewing -----------------------------------------------------------

    public function test_it_shows_a_stalls_details_hygiene_inspections_and_menu(): void
    {
        $data = $this->richStall('main');

        $this->actingAsAdmin()
            ->get("/admin/vendors/{$data['stall']->id}")
            ->assertOk()
            ->assertSee('main Stall')
            ->assertSee($data['owner']->name)
            ->assertSee('Kottu main')
            ->assertSee('Verified')
            ->assertSee('A+')
            ->assertSee('Hopper')
            ->assertSee('1 hidden by moderators')
            ->assertViewHas('impact', [
                'menu_items' => 2,
                'inspections' => 1,
                'reviews' => 2,
                'review_photos' => 2,
                'own_statuses' => 1,
                'followers' => 2,
                'customer_statuses_kept' => 1,
            ]);
    }

    public function test_the_panel_opens_a_stall_that_the_public_api_hides(): void
    {
        $stall = Vendor::factory()->create(['name' => 'Suspended Stall']);
        $stall->user->forceFill(['is_active' => false])->save();

        $this->actingAsAdmin()
            ->get("/admin/vendors/{$stall->id}")
            ->assertOk()
            ->assertSee('Suspended Stall')
            ->assertSee('Hidden: owner is suspended');

        // The very same stall is a 404 on the public API.
        Sanctum::actingAs(User::factory()->create());
        $this->getJson("/api/vendors/{$stall->id}")->assertNotFound();
    }

    public function test_a_missing_stall_is_a_404(): void
    {
        $this->actingAsAdmin()->get('/admin/vendors/999999')->assertNotFound();
    }

    // ---- deleting ----------------------------------------------------------

    public function test_deleting_a_stall_removes_everything_that_belongs_to_it_and_nothing_else(): void
    {
        $doomed = $this->richStall('doomed');
        $control = $this->richStall('control');

        $this->actingAsAdmin()
            ->delete("/admin/vendors/{$doomed['stall']->id}", ['confirm_name' => 'doomed Stall'])
            ->assertRedirect(route('admin.vendors.index'))
            ->assertSessionHas('status');

        $stallId = $doomed['stall']->id;

        // Rows that cascade through the foreign keys.
        $this->assertModelMissing($doomed['stall']);
        $this->assertDatabaseMissing('menu_items', ['vendor_id' => $stallId]);
        $this->assertDatabaseMissing('hygiene_checklists', ['vendor_id' => $stallId]);
        $this->assertModelMissing($doomed['submission']);
        $this->assertDatabaseMissing('reviews', ['vendor_id' => $stallId]);
        foreach ($doomed['reviews'] as $review) {
            $this->assertDatabaseMissing('review_photos', ['review_id' => $review->id]);
        }
        $this->assertDatabaseMissing('category_vendor', ['vendor_id' => $stallId]);
        $this->assertDatabaseMissing('vendor_follows', ['vendor_id' => $stallId]);

        // The stall's own statuses, deleted explicitly, with their comments and likes.
        $this->assertModelMissing($doomed['ownStatus']);
        $this->assertModelMissing($doomed['comment']);
        $this->assertModelMissing($doomed['like']);

        // Kept: the owner, the categories, the followers themselves, and a customer's status that only tagged it.
        $this->assertModelExists($doomed['owner']);
        $this->assertNull($doomed['owner']->fresh()->vendor);
        $this->assertModelExists($doomed['category']);
        foreach ($doomed['followers'] as $follower) {
            $this->assertModelExists($follower);
        }
        $this->assertModelExists($doomed['tagged']);
        $this->assertNull($doomed['tagged']->fresh()->vendor_id);

        // Every image of the stall is gone from the disk...
        foreach ($doomed['files'] as $path) {
            Storage::disk('public')->assertMissing($path);
        }

        // ...and the other stall is completely untouched.
        $this->assertModelExists($control['stall']);
        $this->assertSame(2, $control['stall']->menuItems()->count());
        $this->assertSame(1, $control['stall']->checklists()->count());
        $this->assertSame(2, $control['stall']->reviews()->count());
        $this->assertModelExists($control['ownStatus']);
        $this->assertModelExists($control['comment']);
        $this->assertSame(2, $control['stall']->followers()->count());
        $this->assertModelExists($control['tagged']);
        $this->assertSame($control['stall']->id, $control['tagged']->fresh()->vendor_id);
        foreach ($control['files'] as $path) {
            Storage::disk('public')->assertExists($path);
        }
    }

    public function test_the_stall_name_must_be_typed_to_confirm(): void
    {
        $data = $this->richStall('main');
        $url = "/admin/vendors/{$data['stall']->id}";

        $this->actingAsAdmin();

        $this->delete($url)->assertSessionHasErrors('confirm_name');
        $this->delete($url, ['confirm_name' => 'main stall'])->assertSessionHasErrors('confirm_name');
        $this->delete($url, ['confirm_name' => 'Something else'])->assertSessionHasErrors('confirm_name');

        $this->assertModelExists($data['stall']);
        $this->assertModelExists($data['ownStatus']);
        foreach ($data['files'] as $path) {
            Storage::disk('public')->assertExists($path);
        }

        // Surrounding whitespace is forgiven.
        $this->delete($url, ['confirm_name' => '  main Stall  '])->assertRedirect(route('admin.vendors.index'));
        $this->assertModelMissing($data['stall']);
    }

    public function test_a_failure_part_way_through_deletes_nothing(): void
    {
        $data = $this->richStall('main');

        // The stall's own statuses are deleted first; if the stall itself then fails to
        // delete, the transaction must roll the statuses back and keep every file.
        Vendor::deleting(fn () => throw new RuntimeException('boom'));

        $this->actingAsAdmin()
            ->delete("/admin/vendors/{$data['stall']->id}", ['confirm_name' => 'main Stall'])
            ->assertStatus(500);

        $this->assertModelExists($data['stall']);
        $this->assertModelExists($data['ownStatus']);
        $this->assertModelExists($data['comment']);
        $this->assertModelExists($data['submission']);
        foreach ($data['files'] as $path) {
            Storage::disk('public')->assertExists($path);
        }
    }

    public function test_a_stall_with_a_suspended_owner_can_be_deleted(): void
    {
        $stall = Vendor::factory()->create(['name' => 'Suspended Stall']);
        $stall->user->forceFill(['is_active' => false])->save();

        $this->actingAsAdmin()
            ->delete("/admin/vendors/{$stall->id}", ['confirm_name' => 'Suspended Stall'])
            ->assertRedirect(route('admin.vendors.index'));

        $this->assertModelMissing($stall);
    }

    public function test_deleting_a_missing_stall_is_a_404(): void
    {
        $this->actingAsAdmin()->delete('/admin/vendors/999999', ['confirm_name' => 'x'])->assertNotFound();
    }

    public function test_the_owner_can_set_up_a_new_stall_after_deletion(): void
    {
        $this->seed(CategorySeeder::class);
        $stall = Vendor::factory()->create();
        $owner = $stall->user;

        $impact = app(VendorDeletion::class)->delete($stall);

        $this->assertSame(0, $impact['menu_items']);
        $this->assertModelMissing($stall);

        Sanctum::actingAs($owner);
        $this->postJson('/api/vendors', [
            'name' => 'Fresh Start',
            'latitude' => 6.9271,
            'longitude' => 79.8612,
            'categories' => ['kottu'],
            'opens_at' => '17:00',
            'closes_at' => '01:30',
            'cover_photo' => UploadedFile::fake()->image('cover.jpg'),
        ])->assertCreated()->assertJsonPath('data.name', 'Fresh Start');
    }

    public function test_the_api_still_has_no_way_to_delete_a_stall(): void
    {
        $stall = Vendor::factory()->create();
        Sanctum::actingAs($stall->user);

        $this->deleteJson("/api/vendors/{$stall->id}")->assertStatus(405);
        $this->assertModelExists($stall);
    }
}
