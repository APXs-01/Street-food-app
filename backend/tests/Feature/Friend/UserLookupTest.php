<?php

namespace Tests\Feature\Friend;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class UserLookupTest extends TestCase
{
    use RefreshDatabase;

    public function test_an_exact_username_finds_one_customer_and_reveals_only_public_details(): void
    {
        $maya = User::factory()->create([
            'name' => 'Maya Chen',
            'username' => 'maya_bites',
            'email' => 'maya@example.com',
            'phone' => '+94771234567',
        ]);

        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/users/lookup?username=maya_bites')
            ->assertOk()
            ->assertJsonPath('data.id', $maya->id)
            ->assertJsonPath('data.name', 'Maya Chen')
            ->assertJsonPath('data.username', 'maya_bites')
            ->assertJsonMissingPath('data.email')
            ->assertJsonMissingPath('data.phone')
            ->assertDontSee('maya@example.com');

        $this->getJson('/api/users/lookup?username=@maya_bites')->assertOk()->assertJsonPath('data.id', $maya->id);
    }

    public function test_partial_matches_and_other_lookups_find_nothing(): void
    {
        User::factory()->create(['name' => 'Maya Chen', 'username' => 'maya_bites', 'phone' => '+94771234567']);

        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/users/lookup?username=maya')->assertNotFound();
        $this->getJson('/api/users/lookup?username=maya_bit')->assertNotFound();
        $this->getJson('/api/users/lookup?username=%25')->assertNotFound();
        $this->getJson('/api/users/lookup?username=Maya%20Chen')->assertNotFound();
        $this->getJson('/api/users/lookup?username=%2B94771234567')->assertNotFound();
        $this->getJson('/api/users/lookup?username=nobody')->assertNotFound();
    }

    public function test_only_active_customers_can_be_found(): void
    {
        User::factory()->vendor()->create(['username' => 'a_vendor']);
        User::factory()->inspector()->create(['username' => 'an_inspector']);
        User::factory()->create(['username' => 'suspended_one', 'is_active' => false]);

        Sanctum::actingAs(User::factory()->create());

        foreach (['a_vendor', 'an_inspector', 'suspended_one'] as $username) {
            $this->getJson("/api/users/lookup?username={$username}")->assertNotFound();
        }
    }

    public function test_only_customers_can_look_people_up_and_a_username_is_required(): void
    {
        User::factory()->create(['username' => 'maya_bites']);

        Sanctum::actingAs(User::factory()->vendor()->create());
        $this->getJson('/api/users/lookup?username=maya_bites')->assertForbidden();

        Sanctum::actingAs(User::factory()->create());
        $this->getJson('/api/users/lookup')->assertUnprocessable()->assertJsonValidationErrors('username');
    }

    public function test_it_needs_a_token(): void
    {
        $this->getJson('/api/users/lookup?username=maya_bites')->assertUnauthorized();
    }

    public function test_lookups_are_rate_limited_per_user(): void
    {
        Sanctum::actingAs(User::factory()->create());

        foreach (range(1, 30) as $attempt) {
            $this->getJson('/api/users/lookup?username=nobody')->assertNotFound();
        }

        $this->getJson('/api/users/lookup?username=nobody')->assertStatus(429);
    }
}
