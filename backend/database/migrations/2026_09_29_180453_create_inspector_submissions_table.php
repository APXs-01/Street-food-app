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
        Schema::create('inspector_submissions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('hygiene_checklist_id')->unique()->constrained()->cascadeOnDelete();
            $table->foreignId('inspector_id')->constrained('users')->restrictOnDelete();
            $table->text('notes')->nullable();

            // Evidence photo. submitted_at is the server timestamp (source of truth);
            // capture time and GPS are whatever the device reported.
            $table->string('evidence_photo_path');
            $table->timestamp('evidence_capture_time')->nullable();
            $table->decimal('evidence_latitude', 10, 7)->nullable();
            $table->decimal('evidence_longitude', 10, 7)->nullable();
            $table->timestamp('submitted_at');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('inspector_submissions');
    }
};
