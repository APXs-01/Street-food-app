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
        Schema::create('vendors', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('stall_code', 20)->nullable()->unique();
            $table->string('name', 120);
            $table->text('description')->nullable();
            $table->string('address')->nullable();
            $table->string('landmark')->nullable();
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->string('cover_photo_path')->nullable();

            // Schedule and live status. open_days null means every day.
            $table->time('opens_at');
            $table->time('closes_at');
            $table->json('open_days')->nullable();
            $table->boolean('is_open')->default(false);
            $table->timestamp('status_updated_at')->nullable();

            // Hygiene snapshot of the latest inspection (inspector-driven only).
            $table->decimal('hygiene_score', 3, 2)->nullable();
            $table->string('hygiene_grade', 20)->nullable();
            $table->boolean('water_source_verified')->default(false);
            $table->timestamp('last_inspected_at')->nullable();
            $table->timestamp('reverification_due_at')->nullable();

            // Star rating snapshot (review-driven, separate from hygiene).
            $table->decimal('rating_average', 3, 2)->nullable();
            $table->unsignedInteger('reviews_count')->default(0);

            $table->timestamps();

            $table->index(['latitude', 'longitude']);
            $table->index('hygiene_score');
            $table->index('is_open');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vendors');
    }
};
