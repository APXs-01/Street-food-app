<?php

namespace Database\Factories;

use App\Models\User;
use App\Models\Vendor;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Vendor>
 */
class VendorFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory()->vendor(),
            'name' => fake()->unique()->company(),
            'description' => fake()->sentence(),
            'address' => fake()->streetAddress(),
            'latitude' => fake()->randomFloat(7, 6.90, 6.95),
            'longitude' => fake()->randomFloat(7, 79.84, 79.87),
            'opens_at' => '17:00',
            'closes_at' => '01:30',
        ];
    }
}
