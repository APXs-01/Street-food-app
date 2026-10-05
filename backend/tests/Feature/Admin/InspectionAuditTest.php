<?php

namespace Tests\Feature\Admin;

use App\Enums\CheckResult;
use App\Models\HygieneChecklist;
use App\Models\InspectorSubmission;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\SignsInAdmin;
use Tests\TestCase;

class InspectionAuditTest extends TestCase
{
    use RefreshDatabase;
    use SignsInAdmin;

    /**
     * @param  CheckResult|array<string, CheckResult>  $results  one result for every criterion, or a full map
     * @param  array<string, mixed>  $submission  extra submission attributes
     */
    private function inspect(Vendor $vendor, User $inspector, CheckResult|array $results = CheckResult::Pass, array $submission = []): InspectorSubmission
    {
        $criteria = is_array($results) ? $results : array_fill_keys(HygieneChecklist::CRITERIA, $results);

        $checklist = $vendor->checklists()->create($criteria);
        $recorded = $checklist->submission()->create($submission + [
            'inspector_id' => $inspector->id,
            'evidence_photo_path' => 'inspections/evidence.jpg',
        ]);
        $vendor->applyChecklist($checklist);

        return $recorded;
    }

    private function inspector(string $name = 'Adshaja Perera', string $organization = 'Colombo Municipal Health Council', string $officialId = 'PHI-0042'): User
    {
        $inspector = User::factory()->inspector()->create(['name' => $name]);
        $inspector->inspectorProfile()->create([
            'organization' => $organization,
            'official_id' => $officialId,
            'region' => 'Colombo',
        ]);

        return $inspector;
    }

    // ---- access ------------------------------------------------------------

    public function test_it_needs_an_admin(): void
    {
        $inspection = $this->inspect(Vendor::factory()->create(), $this->inspector());

        $this->get('/admin/inspections')->assertRedirect(route('admin.login'));
        $this->get("/admin/inspections/{$inspection->id}")->assertRedirect(route('admin.login'));

        $this->actingAs(User::factory()->inspector()->create())->get('/admin/inspections')->assertForbidden();
    }

    public function test_it_is_read_only(): void
    {
        $inspection = $this->inspect(Vendor::factory()->create(), $this->inspector());

        $this->actingAsAdmin();

        $this->post('/admin/inspections', [])->assertStatus(405);
        $this->put("/admin/inspections/{$inspection->id}", [])->assertStatus(405);
        $this->patch("/admin/inspections/{$inspection->id}", [])->assertStatus(405);
        $this->delete("/admin/inspections/{$inspection->id}")->assertStatus(405);
        $this->get('/admin/inspections/create')->assertNotFound();
        $this->get("/admin/inspections/{$inspection->id}/edit")->assertNotFound();

        $this->assertModelExists($inspection);
        $this->assertDatabaseCount('inspector_submissions', 1);
    }

    // ---- listing -----------------------------------------------------------

    public function test_it_lists_every_inspection_across_all_stalls_newest_first(): void
    {
        $inspector = $this->inspector();
        $stallA = Vendor::factory()->create(['name' => 'Alpha Stall']);
        $stallB = Vendor::factory()->create(['name' => 'Bravo Stall']);
        $stallB->user->forceFill(['is_active' => false])->save();

        $this->travelTo(now()->subDays(2));
        $first = $this->inspect($stallA, $inspector);
        $this->travelTo(now()->addDay());
        $second = $this->inspect($stallB, $inspector);
        $this->travelBack();
        $third = $this->inspect($stallA, $inspector, CheckResult::Fail);

        $this->actingAsAdmin()
            ->get('/admin/inspections')
            ->assertOk()
            ->assertSee('Alpha Stall')
            ->assertSee('Bravo Stall')
            ->assertSee('Adshaja Perera')
            ->assertSee('Colombo Municipal Health Council')
            ->assertSee('5 criteria failed')
            ->assertViewHas('inspections', fn ($page) => $page->total() === 3
                && $page->pluck('id')->all() === [$third->id, $second->id, $first->id]);
    }

    public function test_it_filters_by_grade(): void
    {
        $inspector = $this->inspector();
        $this->inspect(Vendor::factory()->create(['name' => 'Spotless Stall']), $inspector, CheckResult::Pass);
        $this->inspect(Vendor::factory()->create(['name' => 'Filthy Stall']), $inspector, CheckResult::Fail);

        $this->actingAsAdmin();

        $this->get('/admin/inspections?grade=needs_improvement')->assertSee('Filthy Stall')->assertDontSee('Spotless Stall');
        $this->get('/admin/inspections?'.http_build_query(['grade' => 'A+']))->assertSee('Spotless Stall')->assertDontSee('Filthy Stall');
    }

    public function test_it_filters_by_stall_and_by_inspector(): void
    {
        $one = $this->inspector('Inspector One', 'Org One', 'PHI-1');
        $two = $this->inspector('Inspector Two', 'Org Two', 'PHI-2');
        $stallA = Vendor::factory()->create(['name' => 'Alpha Stall']);
        $stallB = Vendor::factory()->create(['name' => 'Bravo Stall']);

        $this->inspect($stallA, $one);
        $this->inspect($stallB, $two);

        $this->actingAsAdmin();

        $this->get("/admin/inspections?vendor={$stallA->id}")->assertSee('Alpha Stall')->assertDontSee('Bravo Stall');
        $this->get("/admin/inspections?inspector={$two->id}")->assertSee('Bravo Stall')->assertDontSee('Alpha Stall');
        $this->get("/admin/inspections?vendor={$stallA->id}&inspector={$two->id}")->assertSee('No inspections match.');
    }

    public function test_it_filters_by_date_range(): void
    {
        $inspector = $this->inspector();

        $this->travelTo(now()->subDays(10));
        $this->inspect(Vendor::factory()->create(['name' => 'Old Stall']), $inspector);
        $this->travelTo(now()->addDays(7));
        $this->inspect(Vendor::factory()->create(['name' => 'Middle Stall']), $inspector);
        $this->travelBack();
        $this->inspect(Vendor::factory()->create(['name' => 'Recent Stall']), $inspector);

        $this->actingAsAdmin();

        $from = now()->subDays(5)->toDateString();
        $to = now()->subDays(1)->toDateString();

        $this->get("/admin/inspections?from={$from}&to={$to}")
            ->assertSee('Middle Stall')
            ->assertDontSee('Old Stall')
            ->assertDontSee('Recent Stall');

        $this->get("/admin/inspections?from={$from}")->assertSee('Middle Stall')->assertSee('Recent Stall')->assertDontSee('Old Stall');
    }

    public function test_it_can_show_only_inspections_with_a_failed_criterion(): void
    {
        $inspector = $this->inspector();
        $this->inspect(Vendor::factory()->create(['name' => 'Clean Stall']), $inspector, CheckResult::Pass);
        $this->inspect(Vendor::factory()->create(['name' => 'Partial Stall']), $inspector, CheckResult::Partial);
        $this->inspect(Vendor::factory()->create(['name' => 'Failing Stall']), $inspector, [
            ...array_fill_keys(HygieneChecklist::CRITERIA, CheckResult::Pass),
            'waste_disposal' => CheckResult::Fail,
        ]);

        $this->actingAsAdmin()
            ->get('/admin/inspections?failures=1')
            ->assertSee('Failing Stall')
            ->assertSee('1 criterion failed')
            ->assertDontSee('Clean Stall')
            ->assertDontSee('Partial Stall');
    }

    public function test_it_searches_stalls_and_inspectors(): void
    {
        $kandy = $this->inspector('Nimal Fernando', 'Kandy Health Office', 'PHI-7777');
        $colombo = $this->inspector('Someone Else', 'Colombo Council', 'PHI-1111');

        $target = Vendor::factory()->create(['name' => 'Raju Kottu']);
        $target->forceFill(['stall_code' => 'VEND-0042'])->save();
        $this->inspect($target, $kandy, CheckResult::Pass, ['organization' => 'Kandy Health Office']);
        $this->inspect(Vendor::factory()->create(['name' => 'Unrelated Stall']), $colombo);

        $this->actingAsAdmin();

        foreach (['Raju Kottu', 'VEND-0042', 'Nimal', 'Kandy Health', 'PHI-7777'] as $term) {
            $this->get('/admin/inspections?'.http_build_query(['q' => $term]))
                ->assertOk()
                ->assertSee('Raju Kottu')
                ->assertDontSee('Unrelated Stall');
        }

        $this->get('/admin/inspections?q=zzzzzz')->assertSee('No inspections match.');
    }

    public function test_it_rejects_bad_filters(): void
    {
        $this->actingAsAdmin()
            ->get('/admin/inspections?grade=Z&from=not-a-date&vendor=abc')
            ->assertSessionHasErrors(['grade', 'from', 'vendor']);

        $this->get('/admin/inspections?from=2026-10-10&to=2026-10-01')->assertSessionHasErrors('to');
    }

    public function test_it_is_paginated_with_the_filters_kept(): void
    {
        $inspector = $this->inspector();
        $stall = Vendor::factory()->create();

        foreach (range(1, 30) as $day) {
            $this->travelTo(now()->addMinutes($day));
            $this->inspect($stall, $inspector);
        }

        $this->actingAsAdmin()
            ->get('/admin/inspections?'.http_build_query(['grade' => 'A+']))
            ->assertOk()
            ->assertViewHas('inspections', fn ($page) => $page->count() === 25 && $page->total() === 30)
            ->assertSee('grade=A%2B&amp;page=2', false);
    }

    // ---- detail ------------------------------------------------------------

    public function test_it_shows_the_full_record_of_one_inspection(): void
    {
        $inspector = $this->inspector();
        $stall = Vendor::factory()->create(['name' => 'Raju Kottu', 'latitude' => 6.9271, 'longitude' => 79.8621]);
        $stall->forceFill(['stall_code' => 'VEND-0042'])->save();

        $inspection = $this->inspect($stall, $inspector, [
            'water_source' => CheckResult::Pass,
            'utensil_glove_hygiene' => CheckResult::Pass,
            'waste_disposal' => CheckResult::Fail,
            'food_covering' => CheckResult::Partial,
            'overall_cleanliness' => CheckResult::Pass,
        ], [
            'notes' => 'The bin has no lid.',
            'organization' => 'Colombo Municipal Health Council',
            'evidence_photo_path' => 'inspections/raju.jpg',
            'evidence_capture_time' => now()->subMinutes(3),
            'evidence_latitude' => 6.9271,
            'evidence_longitude' => 79.8612,
        ]);

        $this->actingAsAdmin()
            ->get("/admin/inspections/{$inspection->id}")
            ->assertOk()
            ->assertSee('Inspection of Raju Kottu')
            ->assertSee('VEND-0042')
            ->assertSee('Adshaja Perera')
            ->assertSee('PHI-0042')
            ->assertSee('Colombo Municipal Health Council')
            ->assertSee('Water Source')
            ->assertSee('Waste Disposal')
            ->assertSee('Fail')
            ->assertSee('Partial')
            ->assertSee('The bin has no lid.')
            ->assertSee('Current rating')
            ->assertSee('About 99 m')
            ->assertSee('inspections/raju.jpg', false)
            ->assertSee(route('admin.vendors.show', $stall), false)
            ->assertSee(route('admin.users.show', $inspector), false);
    }

    public function test_an_older_inspection_is_marked_as_superseded(): void
    {
        $inspector = $this->inspector();
        $stall = Vendor::factory()->create();

        $this->travelTo(now()->subDays(20));
        $older = $this->inspect($stall, $inspector, CheckResult::Fail);
        $this->travelBack();
        $newer = $this->inspect($stall, $inspector, CheckResult::Pass);

        $this->actingAsAdmin();

        $this->get("/admin/inspections/{$older->id}")->assertSee('Superseded by a later inspection')->assertDontSee('Current rating');
        $this->get("/admin/inspections/{$newer->id}")->assertSee('Current rating')->assertDontSee('Superseded');
    }

    public function test_missing_gps_and_capture_time_are_said_plainly(): void
    {
        $inspection = $this->inspect(Vendor::factory()->create(), $this->inspector());

        $this->actingAsAdmin()
            ->get("/admin/inspections/{$inspection->id}")
            ->assertOk()
            ->assertSee('Not recorded')
            ->assertSee('Not reported by the device');
    }

    public function test_a_far_away_evidence_photo_is_reported_in_kilometres(): void
    {
        $stall = Vendor::factory()->create(['latitude' => 6.9271, 'longitude' => 79.8612]);
        $inspection = $this->inspect($stall, $this->inspector(), CheckResult::Pass, [
            'evidence_latitude' => 6.9406,
            'evidence_longitude' => 79.8612,
        ]);

        $this->actingAsAdmin()
            ->get("/admin/inspections/{$inspection->id}")
            ->assertSee('About 1.5 km');
    }

    public function test_suspended_people_are_labelled_but_their_records_stay_visible(): void
    {
        $inspector = $this->inspector();
        $stall = Vendor::factory()->create();
        $inspection = $this->inspect($stall, $inspector);

        $inspector->forceFill(['is_active' => false])->save();
        $stall->user->forceFill(['is_active' => false])->save();

        $this->actingAsAdmin()
            ->get("/admin/inspections/{$inspection->id}")
            ->assertOk()
            ->assertSee('Owner suspended')
            ->assertSee('Suspended');
    }

    public function test_a_missing_inspection_is_a_404(): void
    {
        $this->actingAsAdmin()->get('/admin/inspections/999999')->assertNotFound();
    }

    // ---- links from other pages ---------------------------------------------

    public function test_stall_and_inspector_pages_link_to_their_inspections(): void
    {
        $inspector = $this->inspector();
        $stall = Vendor::factory()->create();
        $this->inspect($stall, $inspector);

        $this->actingAsAdmin();

        $this->get("/admin/vendors/{$stall->id}")
            ->assertSee(route('admin.inspections.index', ['vendor' => $stall->id]), false);

        $this->get("/admin/users/{$inspector->id}")
            ->assertSee(route('admin.inspections.index', ['inspector' => $inspector->id]), false);
    }
}
