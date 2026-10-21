<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Statuses and comments get the same moderation columns as reviews.
     *
     * @var array<int, string>
     */
    private array $tables = ['daily_statuses', 'status_comments'];

    /**
     * Run the migrations.
     */
    public function up(): void
    {
        foreach ($this->tables as $table) {
            Schema::table($table, function (Blueprint $table) {
                $table->boolean('is_hidden')->default(false);
                $table->string('hidden_reason')->nullable();
                $table->foreignId('moderated_by')->nullable()->constrained('users')->nullOnDelete();
                $table->timestamp('moderated_at')->nullable();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        foreach ($this->tables as $table) {
            Schema::table($table, function (Blueprint $table) {
                $table->dropConstrainedForeignId('moderated_by');
                $table->dropColumn(['is_hidden', 'hidden_reason', 'moderated_at']);
            });
        }
    }
};
