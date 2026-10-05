<?php

namespace Tests\Feature\Admin;

use App\Enums\CheckResult;
use App\Models\HygieneChecklist;
use App\Models\InspectorSubmission;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\Concerns\SignsInAdmin;
use Tests\TestCase;

class HygieneBoardTest extends TestCase
{
    use RefreshDatabase;
    use SignsInAdmin;

    protected function setUp(): void
    {
        parent::setUp();

        // Noon in Colombo, so "days until due" has no midnight edge in these tests.
        $this->travelTo(Carbon::parse('2026-10-10 12:00', 'Asia/Colombo'));
    }

    /**
     * A stall whose snapshot says it is due at the given moment (null: never inspected).
     *
     * @param  array<string, mixed>  $attributes
     */
    private function stall(string $name, ?Carbon $due = null, array $attributes = []): Vendor
    {
        $snapshot = $due === null ? [] : [
            'hygiene_grade' => 'A',
            'hygiene_score' => 4.0,
            'water_source_verified' => true,
            'last_inspected_at' => $due->copy()->subDays(30),
            'reverification_due_at' => $due,
        ];

        return Vendor::factory()->create(['name' => $name] + $attributes + $snapshot);
    }

    private function inspect(Vendor $vendor, CheckResult|array $results): InspectorSubmission
    {
        $criteria = is_array($results) ? $results : array_fill_keys(HygieneChecklist::CRITERIA, $results);

        $checklist = $vendor->checklists()->create($criteria);
        $submission = $checklist->submission()->create([
            'inspector_id' => User::factory()->inspector()->create()->id,
            'evidence_photo_path' => 'inspections/evidence.jpg',
        ]);
        $vendor->applyChecklist($checklist);

        return $submission;
    }

    /**
     * @return array<int, string>
     */
    private function names(string $query = ''): array
    {
        return $this->get('/admin/hygiene'.$query)
            ->assertOk()
            ->viewData('stalls')
            ->pluck('name')
            ->all();
    }

    // ---- access ------------------------------------------------------------

    public function test_it_needs_an_admin_and_is_read_only(): void
    {
        $this->get('/admin/hygiene')->assertRedirect(route('admin.login'));
        $this->actingAs(User::factory()->create())->get('/admin/hygiene')->assertForbidden();

        $this->actingAsAdmin();

        $this->post('/admin/hygiene', [])->assertStatus(405);
        $this->get('/admin/hygiene/1')->assertNotFound();
        $this->delete('/admin/hygiene/1')->assertNotFound();
    }

    // ---- summary -----------------------------------------------------------

    public function test_the_summary_counts_add_up_to_every_stall(): void
    {
        $this->stall('Overdue', now()->subDays(10));
        $this->stall('Soon', now()->addDays(3));
        $this->stall('Later A', now()->addDays(20));
        $this->stall('Later B', now()->addDays(60));
        $this->stall('Never');

        $this->actingAsAdmin()
            ->get('/admin/hygiene')
            ->assertOk()
            ->assertViewHas('summary', [
                'total' => 5,
                'overdue' => 1,
                'due_soon' => 1,
                'current' => 2,
                'not_inspected' => 1,
            ]);
    }

    public function test_the_state_boundaries_are_exact_and_never_overlap(): void
    {
        $this->stall('Just overdue', now()->subSecond());
        $this->stall('Due right now', now());
        $this->stall('Last moment of soon', now()->addDays(7)->subSecond());
        $this->stall('First moment of current', now()->addDays(7));

        $this->actingAsAdmin();

        $this->assertSame(['Just overdue'], $this->names('?state=overdue'));
        $this->assertEqualsCanonicalizing(['Due right now', 'Last moment of soon'], $this->names('?state=due_soon'));
        $this->assertSame(['First moment of current'], $this->names('?state=current'));

        $this->get('/admin/hygiene')->assertViewHas('summary', fn (array $s) => $s['overdue'] + $s['due_soon'] + $s['current'] + $s['not_inspected'] === $s['total']);
    }

    public function test_the_due_soon_window_comes_from_config(): void
    {
        config(['streetbite.due_soon_days' => 14]);

        $this->stall('In ten days', now()->addDays(10));

        $this->actingAsAdmin()
            ->get('/admin/hygiene?state=due_soon')
            ->assertSee('In ten days')
            ->assertSee('Due in the next 14 days');
    }

    // ---- ordering and filters ---------------------------------------------

    public function test_the_default_order_is_most_urgent_first_and_never_inspected_last(): void
    {
        $this->stall('Never');
        $this->stall('Later', now()->addDays(40));
        $this->stall('Soon', now()->addDays(3));
        $this->stall('Overdue a little', now()->subDays(2));
        $this->stall('Overdue a lot', now()->subDays(20));

        $this->actingAsAdmin();

        $this->assertSame(
            ['Overdue a lot', 'Overdue a little', 'Soon', 'Later', 'Never'],
            $this->names(),
        );
    }

    public function test_it_can_sort_by_lowest_score_or_by_name(): void
    {
        $this->stall('Charlie', now()->addDays(20), ['hygiene_score' => 4.5, 'hygiene_grade' => 'A+']);
        $this->stall('Alpha', now()->addDays(20), ['hygiene_score' => 2.0, 'hygiene_grade' => 'needs_improvement']);
        $this->stall('Bravo', now()->addDays(20), ['hygiene_score' => 3.0, 'hygiene_grade' => 'B']);
        $this->stall('Delta');

        $this->actingAsAdmin();

        $this->assertSame(['Alpha', 'Bravo', 'Charlie', 'Delta'], $this->names('?sort=score'));
        $this->assertSame(['Alpha', 'Bravo', 'Charlie', 'Delta'], $this->names('?sort=name'));

        $this->stall('Aardvark', now()->addDays(20), ['hygiene_score' => 5.0, 'hygiene_grade' => 'A+']);
        $this->assertSame(['Aardvark', 'Alpha', 'Bravo', 'Charlie', 'Delta'], $this->names('?sort=name'));
    }

    public function test_it_filters_by_grade(): void
    {
        $this->stall('Spotless', now()->addDays(20), ['hygiene_grade' => 'A+', 'hygiene_score' => 5.0]);
        $this->stall('Middling', now()->addDays(20), ['hygiene_grade' => 'B', 'hygiene_score' => 3.0]);

        $this->actingAsAdmin();

        $this->assertSame(['Middling'], $this->names('?grade=B'));
        $this->assertSame(['Spotless'], $this->names('?'.http_build_query(['grade' => 'A+'])));
    }

    public function test_the_water_filter_only_looks_at_inspected_stalls_for_unverified(): void
    {
        $this->stall('Safe water', now()->addDays(20), ['water_source_verified' => true]);
        $this->stall('Unsafe water', now()->addDays(20), ['water_source_verified' => false]);
        $this->stall('Never inspected');

        $this->actingAsAdmin();

        $this->assertSame(['Safe water'], $this->names('?water=verified'));
        $this->assertSame(['Unsafe water'], $this->names('?water=unverified'));
    }

    public function test_it_searches_stall_code_and_owner(): void
    {
        $target = $this->stall('Raju Kottu', now()->addDays(20));
        $target->forceFill(['stall_code' => 'VEND-0042'])->save();
        $target->user->forceFill(['name' => 'Raju Silva', 'email' => 'raju@example.com'])->save();
        $this->stall('Someone Elses', now()->addDays(20));

        $this->actingAsAdmin();

        foreach (['Raju Kottu', 'VEND-0042', 'Raju Silva', 'raju@example'] as $term) {
            $this->assertSame(['Raju Kottu'], $this->names('?'.http_build_query(['q' => $term])));
        }
    }

    public function test_it_rejects_bad_filters(): void
    {
        $this->actingAsAdmin()
            ->get('/admin/hygiene?state=late&grade=Z&water=maybe&sort=random')
            ->assertSessionHasErrors(['state', 'grade', 'water', 'sort']);
    }

    public function test_it_is_paginated_with_the_filters_kept(): void
    {
        foreach (range(1, 30) as $i) {
            $this->stall("Untested {$i}");
        }

        $this->actingAsAdmin()
            ->get('/admin/hygiene?state=not_inspected')
            ->assertViewHas('stalls', fn ($page) => $page->count() === 25 && $page->total() === 30)
            ->assertSee('state=not_inspected&amp;page=2', false);
    }

    // ---- what each row says ------------------------------------------------

    public function test_rows_say_how_far_overdue_or_how_soon_each_stall_is_due(): void
    {
        $this->stall('Long overdue', now()->subDays(10));
        $this->stall('Overdue today', now()->subHours(2));
        $this->stall('Due today', now()->addHours(3));
        $this->stall('Due soon', now()->addDays(3));
        $this->stall('Due tomorrow', now()->addDay());
        $this->stall('Much later', now()->addDays(25));
        $this->stall('Never');

        $this->actingAsAdmin()
            ->get('/admin/hygiene')
            ->assertOk()
            ->assertSee('10 days overdue')
            ->assertSee('Overdue since today')
            ->assertSee('Due today')
            ->assertSee('Due in 3 days')
            ->assertSee('Due in 1 day')
            ->assertSee('In 25 days')
            ->assertSee('Never');
    }

    public function test_rows_show_the_grade_water_status_and_failed_criteria_of_the_latest_inspection(): void
    {
        $stall = $this->stall('Raju Kottu');
        $this->inspect($stall, [
            'water_source' => CheckResult::Fail,
            'utensil_glove_hygiene' => CheckResult::Pass,
            'waste_disposal' => CheckResult::Fail,
            'food_covering' => CheckResult::Pass,
            'overall_cleanliness' => CheckResult::Pass,
        ]);

        $this->actingAsAdmin()
            ->get('/admin/hygiene')
            ->assertOk()
            ->assertSee('Failed: Water Source, Waste Disposal')
            ->assertSee('Not verified')
            ->assertSee('3.0/5');
    }

    public function test_only_the_latest_inspection_counts_and_the_row_links_to_it(): void
    {
        $stall = $this->stall('Raju Kottu');

        $this->travelTo(now()->subDays(20));
        $older = $this->inspect($stall, CheckResult::Fail);
        $this->travelTo(now()->addDays(20));
        $newer = $this->inspect($stall, CheckResult::Pass);

        $this->actingAsAdmin()
            ->get('/admin/hygiene')
            ->assertOk()
            ->assertSee('A+')
            ->assertDontSee('Failed:')
            ->assertSee(route('admin.inspections.show', $newer), false)
            ->assertDontSee(route('admin.inspections.show', $older), false)
            ->assertSee(route('admin.inspections.index', ['vendor' => $stall->id]), false);
    }

    public function test_a_stall_with_a_suspended_owner_is_listed_and_labelled(): void
    {
        $stall = $this->stall('Hidden Stall', now()->subDays(3));
        $stall->user->forceFill(['is_active' => false])->save();

        $this->actingAsAdmin()
            ->get('/admin/hygiene?state=overdue')
            ->assertOk()
            ->assertSee('Hidden Stall')
            ->assertSee('Owner suspended');
    }

    public function test_the_dashboard_overdue_card_opens_the_overdue_list(): void
    {
        $this->stall('Overdue', now()->subDays(5));

        $this->actingAsAdmin()
            ->get('/admin')
            ->assertOk()
            ->assertSee(route('admin.hygiene.index', ['state' => 'overdue']), false);
    }

    public function test_the_daily_alert_command_agrees_with_the_overdue_list(): void
    {
        $this->makeAdmin();
        $overdue = $this->stall('Overdue', now()->subDays(5));
        $this->stall('Fine', now()->addDays(20));

        $this->artisan('hygiene:flag-overdue')
            ->expectsOutputToContain('1 overdue stall(s)')
            ->assertSuccessful();

        $this->actingAsAdmin();
        $this->assertSame([$overdue->name], $this->names('?state=overdue'));
    }
}
