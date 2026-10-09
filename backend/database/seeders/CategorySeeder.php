<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $categories = [
            'kottu' => 'Kottu',
            'short-eats' => 'Short Eats',
            'fresh-juice' => 'Fresh Juice',
            'hoppers' => 'Hoppers',
            'rice-and-curry' => 'Rice & Curry',
            'bbq-seafood' => 'BBQ / Seafood',
        ];

        foreach ($categories as $slug => $name) {
            Category::updateOrCreate(['slug' => $slug], ['name' => $name]);
        }
    }
}
