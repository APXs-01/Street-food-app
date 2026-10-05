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
        // Snapshot of the inspecting organisation at submission time, so history
        // stays accurate if the inspector's profile changes later.
        Schema::table('inspector_submissions', function (Blueprint $table) {
            $table->string('organization', 120)->nullable()->after('notes');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('inspector_submissions', function (Blueprint $table) {
            $table->dropColumn('organization');
        });
    }
};
