<?php

namespace Database\Seeders;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Database\Seeder;

class AdminUserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        if (User::where('email', 'admin@streetbite.com')->exists()) {
            return;
        }

        User::createWithRole(UserRole::SuperAdmin, [
            'name' => 'Dileepa',
            'email' => 'admin@streetbite.com',
            'password' => 'ChangeMe123!',
        ]);
    }
}
