<?php

namespace Tests\Feature\Status;

use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesSocialFixtures;
use Tests\TestCase;

class VendorFollowTest extends TestCase
{
    use CreatesSocialFixtures;
    use RefreshDatabase;

    public function test_following_and_unfollowing_a_stall_is_idempotent(): void
    {
        $vendor = Vendor::factory()->create();
        $me = User::factory()->create();
        Sanctum::actingAs($me);

        $this->postJson("/api/vendors/{$vendor->id}/follow")->assertOk()->assertJsonPath('following', true);
        $this->postJson("/api/vendors/{$vendor->id}/follow")->assertOk()->assertJsonPath('following', true);
        $this->assertSame(1, $me->followedVendors()->count());

        $this->deleteJson("/api/vendors/{$vendor->id}/follow")->assertOk()->assertJsonPath('following', false);
        $this->deleteJson("/api/vendors/{$vendor->id}/follow")->assertOk();
        $this->assertSame(0, $me->followedVendors()->count());
    }

    public function test_only_customers_follow_stalls(): void
    {
        $vendor = Vendor::factory()->create();

        foreach ([Vendor::factory()->create()->user, User::factory()->inspector()->create()] as $user) {
            Sanctum::actingAs($user);
            $this->postJson("/api/vendors/{$vendor->id}/follow")->assertForbidden();
        }
    }

    public function test_the_stall_view_says_whether_the_viewer_follows_it(): void
    {
        $vendor = Vendor::factory()->create();
        $me = User::factory()->create();
        Sanctum::actingAs($me);

        $this->getJson("/api/vendors/{$vendor->id}")->assertJsonPath('data.followed_by_me', false);

        $me->followedVendors()->attach($vendor);

        $this->getJson("/api/vendors/{$vendor->id}")->assertJsonPath('data.followed_by_me', true);
    }

    public function test_following_a_stall_brings_its_statuses_into_the_feed(): void
    {
        $vendor = Vendor::factory()->create();
        $this->statusBy($vendor->user, 'Fresh batch', ['vendor_id' => $vendor->id]);

        $me = User::factory()->create();
        Sanctum::actingAs($me);

        $this->getJson('/api/statuses')->assertJsonCount(0, 'data');

        $this->postJson("/api/vendors/{$vendor->id}/follow")->assertOk();

        $this->getJson('/api/statuses')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.caption', 'Fresh batch')
            ->assertJsonPath('data.0.vendor.id', $vendor->id);

        $this->deleteJson("/api/vendors/{$vendor->id}/follow")->assertOk();

        $this->getJson('/api/statuses')->assertJsonCount(0, 'data');
    }
}
