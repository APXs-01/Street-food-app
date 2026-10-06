<?php

namespace Tests\Feature\Inspection;

use App\Enums\CheckResult;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class InspectionHistoryTest extends TestCase
{
    use RefreshDatabase;

    private function record(Vendor $vendor, User $inspector, CheckResult $result): void
    {
        $checklist = $vendor->checklists()->create([
            'water_source' => $result,
            'utensil_glove_hygiene' => $result,
            'waste_disposal' => $result,
            'food_covering' => $result,
            'overall_cleanliness' => $result,
        ]);

        $checklist->submission()->create([
            'inspector_id' => $inspector->id,
            'evidence_photo_path' => 'inspections/evidence.jpg',
            'notes' => "Inspected by {$inspector->name}",
        ]);
    }

    public function test_an_inspector_sees_the_audit_trail_newest_first_for_that_stall_only(): void
    {
        $vendor = Vendor::factory()->create();
        $first = User::factory()->inspector()->create(['name' => 'First Inspector']);
        $second = User::factory()->inspector()->create(['name' => 'Second Inspector']);

        $this->record($vendor, $first, CheckResult::Pass);
        $this->travelTo(now()->addDay());
        $this->record($vendor, $second, CheckResult::Fail);
        $this->record(Vendor::factory()->create(), $first, CheckResult::Pass);

        Sanctum::actingAs($first);

        $this->getJson("/api/vendors/{$vendor->id}/inspections")
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('meta.total', 2)
            ->assertJsonPath('data.0.inspector.name', 'Second Inspector')
            ->assertJsonPath('data.0.grade', 'needs_improvement')
            ->assertJsonPath('data.1.inspector.name', 'First Inspector')
            ->assertJsonPath('data.1.grade', 'A+');
    }

    public function test_the_trail_is_paginated(): void
    {
        $vendor = Vendor::factory()->create();
        $inspector = User::factory()->inspector()->create();

        foreach (range(1, 3) as $day) {
            $this->travelTo(now()->addDay());
            $this->record($vendor, $inspector, CheckResult::Pass);
        }

        Sanctum::actingAs($inspector);

        $this->getJson("/api/vendors/{$vendor->id}/inspections?per_page=2&page=2")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('meta.total', 3)
            ->assertJsonPath('meta.last_page', 2);
    }

    public function test_consumers_and_other_vendors_cannot_read_the_audit_trail(): void
    {
        $vendor = Vendor::factory()->create();

        Sanctum::actingAs(User::factory()->create());
        $this->getJson("/api/vendors/{$vendor->id}/inspections")->assertForbidden();

        Sanctum::actingAs(Vendor::factory()->create()->user);
        $this->getJson("/api/vendors/{$vendor->id}/inspections")->assertForbidden();
    }

    public function test_a_vendor_reads_their_own_trail_without_inspector_identity_or_gps(): void
    {
        $vendor = Vendor::factory()->create();
        $inspector = User::factory()->inspector()->create(['name' => 'Private Inspector']);

        $checklist = $vendor->checklists()->create([
            'water_source' => CheckResult::Pass,
            'utensil_glove_hygiene' => CheckResult::Partial,
            'waste_disposal' => CheckResult::Fail,
            'food_covering' => CheckResult::Pass,
            'overall_cleanliness' => CheckResult::Pass,
        ]);
        $checklist->submission()->create([
            'inspector_id' => $inspector->id,
            'organization' => 'Colombo Municipal Health Council',
            'notes' => 'Waste bin uncovered.',
            'evidence_photo_path' => 'inspections/evidence.jpg',
            'evidence_latitude' => 6.9271,
            'evidence_longitude' => 79.8612,
        ]);

        Sanctum::actingAs($vendor->user);

        $this->getJson("/api/vendors/{$vendor->id}/inspections")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.grade', 'A')
            ->assertJsonPath('data.0.notes', 'Waste bin uncovered.')
            ->assertJsonPath('data.0.organization', 'Colombo Municipal Health Council')
            ->assertJsonPath('data.0.criteria.2', ['key' => 'waste_disposal', 'result' => 'fail'])
            ->assertJsonMissingPath('data.0.inspector')
            ->assertJsonMissingPath('data.0.evidence.latitude')
            ->assertJsonMissingPath('data.0.evidence.longitude')
            ->assertDontSee('Private Inspector');

        // Staff still see both.
        Sanctum::actingAs($inspector);

        $this->getJson("/api/vendors/{$vendor->id}/inspections")
            ->assertOk()
            ->assertJsonPath('data.0.inspector.name', 'Private Inspector')
            ->assertJsonPath('data.0.evidence.latitude', 6.9271);
    }
}
