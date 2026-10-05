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
        // A status can carry a photo or a short video, so the column is no longer
        // photo-specific. media_type is null for text-only statuses.
        Schema::table('daily_statuses', function (Blueprint $table) {
            $table->renameColumn('photo_path', 'media_path');
        });

        Schema::table('daily_statuses', function (Blueprint $table) {
            $table->string('media_type', 10)->nullable()->after('media_path');

            // The daily purge scans by age.
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('daily_statuses', function (Blueprint $table) {
            $table->dropIndex(['created_at']);
            $table->dropColumn('media_type');
        });

        Schema::table('daily_statuses', function (Blueprint $table) {
            $table->renameColumn('media_path', 'photo_path');
        });
    }
};
