<?php

namespace Tests\Feature\Vendor;

use App\Models\MenuItem;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MenuItemApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');
    }

    public function test_a_vendor_can_add_a_menu_item_with_a_photo(): void
    {
        $vendor = Vendor::factory()->create();
        Sanctum::actingAs($vendor->user);

        $response = $this->postJson('/api/menu-items', [
            'name' => 'Egg Hopper',
            'price' => 120,
            'fresh_today' => true,
            'photo' => UploadedFile::fake()->image('hopper.jpg', 600, 600),
        ])
            ->assertCreated()
            ->assertJsonPath('data.name', 'Egg Hopper')
            ->assertJsonPath('data.is_available', true)
            ->assertJsonPath('data.is_fresh_today', true);

        $this->assertEquals(120, $response->json('data.price'));

        $item = $vendor->menuItems()->firstOrFail();
        Storage::disk('public')->assertExists($item->photo_path);
    }

    public function test_only_a_vendor_with_a_stall_can_add_items(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $this->postJson('/api/menu-items', ['name' => 'Tea', 'price' => 50])->assertForbidden();

        Sanctum::actingAs(User::factory()->vendor()->create());
        $this->postJson('/api/menu-items', ['name' => 'Tea', 'price' => 50])->assertForbidden();
    }

    public function test_the_fresh_and_sold_out_switches_work_through_update(): void
    {
        $vendor = Vendor::factory()->create();
        $item = $vendor->menuItems()->create(['name' => 'Kottu', 'price' => 450]);
        Sanctum::actingAs($vendor->user);

        $this->patchJson("/api/menu-items/{$item->id}", ['fresh_today' => true])
            ->assertOk()
            ->assertJsonPath('data.is_fresh_today', true);

        $this->patchJson("/api/menu-items/{$item->id}", ['fresh_today' => false, 'is_available' => false])
            ->assertOk()
            ->assertJsonPath('data.is_fresh_today', false)
            ->assertJsonPath('data.is_available', false);
    }

    public function test_another_vendor_cannot_change_or_delete_an_item(): void
    {
        $item = Vendor::factory()->create()->menuItems()->create(['name' => 'Kottu', 'price' => 450]);
        Sanctum::actingAs(Vendor::factory()->create()->user);

        $this->patchJson("/api/menu-items/{$item->id}", ['name' => 'Stolen'])->assertForbidden();
        $this->deleteJson("/api/menu-items/{$item->id}")->assertForbidden();

        $this->assertDatabaseHas('menu_items', ['id' => $item->id, 'name' => 'Kottu']);
    }

    public function test_deleting_an_item_removes_its_photo(): void
    {
        $vendor = Vendor::factory()->create();
        Sanctum::actingAs($vendor->user);

        $created = $this->postJson('/api/menu-items', [
            'name' => 'Juice',
            'price' => 250,
            'photo' => UploadedFile::fake()->image('juice.jpg'),
        ])->assertCreated();

        $item = MenuItem::findOrFail($created->json('data.id'));
        $path = $item->photo_path;

        $this->deleteJson("/api/menu-items/{$item->id}")->assertNoContent();

        $this->assertModelMissing($item);
        Storage::disk('public')->assertMissing($path);
    }

    public function test_the_menu_list_needs_a_vendor_unless_the_user_owns_a_stall(): void
    {
        $vendor = Vendor::factory()->create();
        $vendor->menuItems()->create(['name' => 'Kottu', 'price' => 450]);

        Sanctum::actingAs(User::factory()->create());
        $this->getJson('/api/menu-items')->assertUnprocessable()->assertJsonValidationErrors('vendor_id');
        $this->getJson("/api/menu-items?vendor_id={$vendor->id}")->assertOk()->assertJsonCount(1, 'data');

        Sanctum::actingAs($vendor->user);
        $this->getJson('/api/menu-items')->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_fresh_today_follows_the_colombo_calendar_day(): void
    {
        $this->assertSame('Asia/Colombo', config('app.timezone'));

        $this->travelTo(Carbon::parse('2026-10-02 06:00', 'Asia/Colombo'));

        $item = new MenuItem;

        // 00:30 Colombo is still the previous day in UTC, which is the bug this guards.
        $item->fresh_marked_at = Carbon::parse('2026-10-02 00:30', 'Asia/Colombo');
        $this->assertTrue($item->is_fresh_today);

        $item->fresh_marked_at = Carbon::parse('2026-10-01 23:30', 'Asia/Colombo');
        $this->assertFalse($item->is_fresh_today);
    }
}
