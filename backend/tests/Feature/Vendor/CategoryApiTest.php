<?php

namespace Tests\Feature\Vendor;

use App\Models\User;
use Database\Seeders\CategorySeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CategoryApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_lists_the_categories_in_their_seeded_order(): void
    {
        $this->seed(CategorySeeder::class);
        Sanctum::actingAs(User::factory()->vendor()->create());

        $this->getJson('/api/categories')
            ->assertOk()
            ->assertExactJson(['data' => [
                ['slug' => 'kottu', 'name' => 'Kottu'],
                ['slug' => 'short-eats', 'name' => 'Short Eats'],
                ['slug' => 'fresh-juice', 'name' => 'Fresh Juice'],
                ['slug' => 'hoppers', 'name' => 'Hoppers'],
                ['slug' => 'rice-and-curry', 'name' => 'Rice & Curry'],
                ['slug' => 'bbq-seafood', 'name' => 'BBQ / Seafood'],
            ]]);
    }

    public function test_with_no_categories_it_is_an_empty_list(): void
    {
        Sanctum::actingAs(User::factory()->vendor()->create());

        $this->getJson('/api/categories')->assertOk()->assertExactJson(['data' => []]);
    }

    public function test_any_signed_in_role_can_read_it(): void
    {
        $this->seed(CategorySeeder::class);

        foreach ([User::factory()->create(), User::factory()->vendor()->create()] as $user) {
            Sanctum::actingAs($user);

            $this->getJson('/api/categories')->assertOk()->assertJsonCount(6, 'data');
        }
    }

    public function test_it_needs_a_token(): void
    {
        $this->getJson('/api/categories')->assertUnauthorized();
    }
}
