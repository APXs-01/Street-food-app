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
        Schema::create('hygiene_checklists', function (Blueprint $table) {
            $table->id();
            $table->foreignId('vendor_id')->constrained()->cascadeOnDelete();

            // Each criterion is pass, partial or fail.
            $table->string('water_source', 10);
            $table->string('utensil_glove_hygiene', 10);
            $table->string('waste_disposal', 10);
            $table->string('food_covering', 10);
            $table->string('overall_cleanliness', 10);

            $table->decimal('score', 3, 2);
            $table->string('grade', 20);
            $table->timestamp('inspected_at');
            $table->timestamps();

            $table->index(['vendor_id', 'inspected_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('hygiene_checklists');
    }
};
