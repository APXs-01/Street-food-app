<?php

namespace Tests\Feature\Inspection;

use App\Enums\HygieneGrade;
use App\Models\InspectorSubmission;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class InspectionSubmissionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');
    }

    /**
     * Pass, pass, partial, pass, fail scores 3.5, which is grade A.
     *
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function payload(Vendor $vendor, array $overrides = []): array
    {
        return array_merge([
            'vendor_id' => $vendor->id,
            'water_source' => 'pass',
            'utensil_glove_hygiene' => 'pass',
            'waste_disposal' => 'partial',
            'food_covering' => 'pass',
            'overall_cleanliness' => 'fail',
            'evidence_photo' => UploadedFile::fake()->image('evidence.jpg', 800, 600),
            'notes' => 'Bin needs a lid.',
        ], $overrides);
    }

    private function inspector(?string $organization = 'Colombo Municipal Health Council'): User
    {
        $inspector = User::factory()->inspector()->create();

        if ($organization !== null) {
            $inspector->inspectorProfile()->create(['organization' => $organization, 'official_id' => 'PHI-'.$inspector->id]);
        }

        return $inspector;
    }

    public function test_an_inspector_submits_an_inspection_and_the_stall_snapshot_updates(): void
    {
        $vendor = Vendor::factory()->create();
        $inspector = $this->inspector();
        Sanctum::actingAs($inspector);

        $response = $this->postJson('/api/inspections', $this->payload($vendor))
            ->assertCreated()
            ->assertJsonPath('data.grade', 'A')
            ->assertJsonPath('data.organization', 'Colombo Municipal Health Council')
            ->assertJsonPath('data.inspector.id', $inspector->id)
            ->assertJsonCount(5, 'data.criteria')
            ->assertJsonPath('vendor_hygiene.status', 'verified')
            ->assertJsonPath('vendor_hygiene.grade', 'A');

        $this->assertEquals(3.5, $response->json('data.score'));

        $this->assertDatabaseCount('hygiene_checklists', 1);
        $this->assertDatabaseCount('inspector_submissions', 1);

        $vendor->refresh();

        $this->assertSame(HygieneGrade::A, $vendor->hygiene_grade);
        $this->assertEquals(3.5, $vendor->hygiene_score);
        $this->assertTrue($vendor->water_source_verified);
        $this->assertNotNull($vendor->last_inspected_at);
        $this->assertTrue($vendor->reverification_due_at->equalTo(
            $vendor->last_inspected_at->copy()->addDays(config('streetbite.reverification_days')),
        ));

        Storage::disk('public')->assertExists(InspectorSubmission::firstOrFail()->evidence_photo_path);
    }

    public function test_an_explicit_organisation_overrides_the_profile_and_none_is_allowed(): void
    {
        $vendor = Vendor::factory()->create();

        Sanctum::actingAs($this->inspector());
        $this->postJson('/api/inspections', $this->payload($vendor, ['organization' => 'Kandy Health Office']))
            ->assertCreated()
            ->assertJsonPath('data.organization', 'Kandy Health Office');

        Sanctum::actingAs($this->inspector(null));
        $this->postJson('/api/inspections', $this->payload($vendor))
            ->assertCreated()
            ->assertJsonPath('data.organization', null);
    }

    public function test_the_latest_inspection_replaces_the_previous_snapshot(): void
    {
        $vendor = Vendor::factory()->create();
        Sanctum::actingAs($this->inspector());

        $allPass = ['water_source' => 'pass', 'utensil_glove_hygiene' => 'pass', 'waste_disposal' => 'pass', 'food_covering' => 'pass', 'overall_cleanliness' => 'pass'];
        $allFail = ['water_source' => 'fail', 'utensil_glove_hygiene' => 'fail', 'waste_disposal' => 'fail', 'food_covering' => 'fail', 'overall_cleanliness' => 'fail'];

        $this->postJson('/api/inspections', $this->payload($vendor, $allPass))->assertCreated();
        $this->assertSame(HygieneGrade::APlus, $vendor->fresh()->hygiene_grade);

        $this->travelTo(now()->addHour());
        $this->postJson('/api/inspections', $this->payload($vendor, $allFail))->assertCreated();

        $vendor->refresh();

        $this->assertSame(HygieneGrade::NeedsImprovement, $vendor->hygiene_grade);
        $this->assertEquals(0, $vendor->hygiene_score);
        $this->assertFalse($vendor->water_source_verified);

        $this->getJson("/api/vendors/{$vendor->id}/hygiene")
            ->assertJsonPath('data.grade', 'needs_improvement')
            ->assertJsonPath('data.inspection.criteria.0.result', 'fail');
    }

    public function test_the_score_is_always_derived_on_the_server(): void
    {
        $vendor = Vendor::factory()->create();
        Sanctum::actingAs($this->inspector());

        $allFail = ['water_source' => 'fail', 'utensil_glove_hygiene' => 'fail', 'waste_disposal' => 'fail', 'food_covering' => 'fail', 'overall_cleanliness' => 'fail'];

        $this->postJson('/api/inspections', $this->payload($vendor, $allFail + ['score' => 5, 'grade' => 'A+']))
            ->assertCreated()
            ->assertJsonPath('data.grade', 'needs_improvement');

        $this->assertEquals(0, $vendor->fresh()->hygiene_score);
    }

    public function test_only_active_inspectors_can_submit(): void
    {
        $vendor = Vendor::factory()->create();

        foreach ([User::factory()->create(), User::factory()->vendor()->create()] as $user) {
            Sanctum::actingAs($user);
            $this->postJson('/api/inspections', $this->payload($vendor))->assertForbidden();
        }

        $suspended = User::factory()->inspector()->create(['is_active' => false]);
        Sanctum::actingAs($suspended);
        $this->postJson('/api/inspections', $this->payload($vendor))->assertForbidden();

        $this->assertDatabaseCount('hygiene_checklists', 0);
        $this->assertEmpty(Storage::disk('public')->allFiles());
    }

    public function test_the_criteria_and_evidence_photo_are_required(): void
    {
        Sanctum::actingAs($this->inspector());

        $this->postJson('/api/inspections', [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'vendor_id', 'water_source', 'utensil_glove_hygiene', 'waste_disposal',
                'food_covering', 'overall_cleanliness', 'evidence_photo',
            ]);
    }

    public function test_results_must_be_pass_partial_or_fail(): void
    {
        $vendor = Vendor::factory()->create();
        Sanctum::actingAs($this->inspector());

        $this->postJson('/api/inspections', $this->payload($vendor, ['water_source' => 'maybe']))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('water_source');
    }

    public function test_gps_needs_both_coordinates(): void
    {
        $vendor = Vendor::factory()->create();
        Sanctum::actingAs($this->inspector());

        $this->postJson('/api/inspections', $this->payload($vendor, ['evidence_longitude' => 79.86]))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('evidence_latitude');
    }
}
