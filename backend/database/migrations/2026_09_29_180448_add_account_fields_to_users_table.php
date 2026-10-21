<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Sign-up accepts an email or a mobile number, so email is optional.
        Schema::table('users', function (Blueprint $table) {
            $table->string('email')->nullable()->change();
        });

        Schema::table('users', function (Blueprint $table) {
            $table->string('username', 30)->nullable()->unique()->after('name');
            $table->string('phone', 20)->nullable()->unique()->after('email');
            $table->string('role', 20)->default('consumer')->index()->after('password');
            $table->string('avatar_path')->nullable()->after('role');
            $table->string('bio', 160)->nullable()->after('avatar_path');
            $table->boolean('is_active')->default(true)->after('bio');
            $table->timestamp('last_login_at')->nullable()->after('is_active');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['username']);
            $table->dropUnique(['phone']);
            $table->dropIndex(['role']);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'username',
                'phone',
                'role',
                'avatar_path',
                'bio',
                'is_active',
                'last_login_at',
            ]);
        });
    }
};
