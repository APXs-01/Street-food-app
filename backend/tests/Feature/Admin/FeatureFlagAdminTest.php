<?php

namespace Tests\Feature\Admin;

use App\Models\FeatureFlag;
use App\Models\User;
use App\Services\FeatureFlags;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\SignsInAdmin;
use Tests\TestCase;

class FeatureFlagAdminTest extends TestCase
{
    use RefreshDatabase;
    use SignsInAdmin;

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function flag(string $key = 'friends', bool $enabled = true, array $attributes = []): FeatureFlag
    {
        return FeatureFlag::create($attributes + ['key' => $key, 'label' => ucfirst($key), 'enabled' => $enabled]);
    }

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function payload(array $overrides = []): array
    {
        return array_merge(['key' => 'vendor_analytics', 'label' => 'Vendor analytics', 'enabled' => '1'], $overrides);
    }

    // ---- access ------------------------------------------------------------

    public function test_it_needs_an_admin(): void
    {
        $flag = $this->flag();

        $this->get('/admin/features')->assertRedirect(route('admin.login'));
        $this->get('/admin/features/create')->assertRedirect(route('admin.login'));
        $this->post('/admin/features', $this->payload())->assertRedirect(route('admin.login'));

        $this->actingAs(User::factory()->create());
        $this->get('/admin/features')->assertForbidden();
        $this->post('/admin/features', $this->payload())->assertForbidden();
        $this->put("/admin/features/{$flag->id}", ['label' => 'Hacked'])->assertForbidden();
        $this->patch("/admin/features/{$flag->id}/toggle")->assertForbidden();
        $this->delete("/admin/features/{$flag->id}")->assertForbidden();

        $this->assertDatabaseCount('feature_flags', 1);
        $this->assertTrue($flag->fresh()->enabled);
        $this->assertSame('Friends', $flag->fresh()->label);
    }

    public function test_there_is_no_show_page(): void
    {
        $flag = $this->flag();

        // The URL exists for updating and deleting, but not for viewing.
        $this->actingAsAdmin()->get("/admin/features/{$flag->id}")->assertStatus(405);
    }

    // ---- listing -----------------------------------------------------------

    public function test_it_lists_the_flags_and_previews_what_the_app_receives(): void
    {
        $this->flag('daily_status', true, ['label' => 'Daily status', 'description' => 'Consumer and vendor stories']);
        $this->flag('friends', false, ['label' => 'Friends']);

        $this->actingAsAdmin()
            ->get('/admin/features')
            ->assertOk()
            ->assertSee('daily_status')
            ->assertSee('Daily status')
            ->assertSee('Consumer and vendor stories')
            ->assertSee('"daily_status": true')
            ->assertSee('"friends": false')
            ->assertSee('Turn off')
            ->assertSee('Turn on');
    }

    public function test_an_empty_list_says_so_and_previews_an_empty_object(): void
    {
        $this->actingAsAdmin()
            ->get('/admin/features')
            ->assertOk()
            ->assertSee('No flags yet.')
            ->assertSee('"data": {}');
    }

    public function test_the_add_form_renders(): void
    {
        $this->actingAsAdmin()
            ->get('/admin/features/create')
            ->assertOk()
            ->assertSee('Add feature flag')
            ->assertSee('name="key"', false);
    }

    // ---- creating ----------------------------------------------------------

    public function test_it_creates_a_flag_with_a_cleaned_up_key(): void
    {
        $this->actingAsAdmin()
            ->post('/admin/features', $this->payload([
                'key' => '  Vendor_Analytics ',
                'description' => 'Analytics tab on the vendor dashboard',
            ]))
            ->assertRedirect(route('admin.features.index'))
            ->assertSessionHas('status');

        $flag = FeatureFlag::sole();

        $this->assertSame('vendor_analytics', $flag->key);
        $this->assertSame('Vendor analytics', $flag->label);
        $this->assertSame('Analytics tab on the vendor dashboard', $flag->description);
        $this->assertTrue($flag->enabled);
    }

    public function test_keys_can_be_grouped_with_dots(): void
    {
        $this->actingAsAdmin();

        foreach (['consumer.daily_status', 'consumer.friends', 'vendor.analytics', 'inspector.checklist', 'ab'] as $key) {
            $this->post('/admin/features', $this->payload(['key' => $key]))->assertSessionHasNoErrors();
        }

        $this->assertSame(
            ['ab', 'consumer.daily_status', 'consumer.friends', 'inspector.checklist', 'vendor.analytics'],
            FeatureFlag::orderBy('key')->pluck('key')->all(),
        );
    }

    public function test_a_new_flag_is_off_unless_the_box_is_ticked(): void
    {
        $this->actingAsAdmin();

        $this->post('/admin/features', $this->payload(['key' => 'unticked', 'enabled' => '0']))->assertSessionHasNoErrors();
        $this->post('/admin/features', $this->payload(['key' => 'absent', 'enabled' => null]))->assertSessionHasNoErrors();

        $this->assertFalse(FeatureFlag::where('key', 'unticked')->sole()->enabled);
        $this->assertFalse(FeatureFlag::where('key', 'absent')->sole()->enabled);
    }

    public function test_it_rejects_bad_keys_and_duplicates(): void
    {
        $this->flag('friends');
        $this->actingAsAdmin();

        foreach (['1abc', 'has space', 'a', 'dash-ed', 'bang!', str_repeat('a', 65), '_leading', 'a..b', '.lead', 'trail.', 'consumer.1st', 'consumer._x'] as $key) {
            $this->post('/admin/features', $this->payload(['key' => $key]))
                ->assertSessionHasErrors('key');
        }

        // Duplicates, including a differently cased one.
        $this->post('/admin/features', $this->payload(['key' => 'friends']))->assertSessionHasErrors('key');
        $this->post('/admin/features', $this->payload(['key' => 'FRIENDS']))->assertSessionHasErrors('key');

        $this->assertDatabaseCount('feature_flags', 1);
    }

    public function test_it_needs_a_label_and_caps_the_lengths(): void
    {
        $this->actingAsAdmin();

        $this->post('/admin/features', $this->payload(['label' => '']))->assertSessionHasErrors('label');
        $this->post('/admin/features', $this->payload(['label' => str_repeat('a', 121)]))->assertSessionHasErrors('label');
        $this->post('/admin/features', $this->payload(['description' => str_repeat('a', 256)]))->assertSessionHasErrors('description');

        $this->assertDatabaseCount('feature_flags', 0);
    }

    // ---- editing -----------------------------------------------------------

    public function test_the_edit_form_shows_the_key_but_does_not_let_it_be_edited(): void
    {
        $flag = $this->flag('friends');

        $this->actingAsAdmin()
            ->get("/admin/features/{$flag->id}/edit")
            ->assertOk()
            ->assertSee('friends')
            ->assertSee('The key cannot be changed')
            ->assertDontSee('name="key"', false);
    }

    public function test_it_updates_the_label_description_and_state(): void
    {
        $flag = $this->flag('friends', false);

        $this->actingAsAdmin()
            ->put("/admin/features/{$flag->id}", ['label' => 'Friend network', 'description' => 'Adds friends', 'enabled' => '1'])
            ->assertRedirect(route('admin.features.index'))
            ->assertSessionHas('status');

        $flag->refresh();

        $this->assertSame('Friend network', $flag->label);
        $this->assertSame('Adds friends', $flag->description);
        $this->assertTrue($flag->enabled);
    }

    public function test_the_key_can_never_be_changed_even_if_one_is_sent(): void
    {
        $flag = $this->flag('friends');

        $this->actingAsAdmin()
            ->put("/admin/features/{$flag->id}", ['key' => 'renamed', 'label' => 'Friends', 'enabled' => '1'])
            ->assertSessionHasNoErrors();

        $this->assertSame('friends', $flag->fresh()->key);
        $this->assertDatabaseMissing('feature_flags', ['key' => 'renamed']);
    }

    public function test_an_unticked_box_turns_the_flag_off_and_a_label_is_required(): void
    {
        $flag = $this->flag('friends', true);

        $this->actingAsAdmin();

        $this->put("/admin/features/{$flag->id}", ['label' => ''])->assertSessionHasErrors('label');
        $this->assertTrue($flag->fresh()->enabled);

        $this->put("/admin/features/{$flag->id}", ['label' => 'Friends', 'enabled' => '0'])->assertSessionHasNoErrors();
        $this->assertFalse($flag->fresh()->enabled);
    }

    public function test_it_can_toggle_a_flag_both_ways(): void
    {
        $flag = $this->flag('friends', false);

        $this->actingAsAdmin();

        $this->patch("/admin/features/{$flag->id}/toggle")->assertSessionHas('status', '"friends" is now on.');
        $this->assertTrue($flag->fresh()->enabled);

        $this->patch("/admin/features/{$flag->id}/toggle")->assertSessionHas('status', '"friends" is now off.');
        $this->assertFalse($flag->fresh()->enabled);
    }

    public function test_it_deletes_a_flag(): void
    {
        $flag = $this->flag('friends');

        $this->actingAsAdmin()
            ->delete("/admin/features/{$flag->id}")
            ->assertRedirect(route('admin.features.index'))
            ->assertSessionHas('status');

        $this->assertModelMissing($flag);
    }

    public function test_a_missing_flag_is_a_404(): void
    {
        $this->actingAsAdmin();

        $this->get('/admin/features/999999/edit')->assertNotFound();
        $this->put('/admin/features/999999', ['label' => 'x'])->assertNotFound();
        $this->patch('/admin/features/999999/toggle')->assertNotFound();
        $this->delete('/admin/features/999999')->assertNotFound();
    }

    // ---- the effect on what the app reads -----------------------------------

    public function test_the_cached_flags_follow_every_admin_change(): void
    {
        $flags = app(FeatureFlags::class);
        $flag = $this->flag('friends', false);

        // Warm the cache, then change the flag through the panel.
        $this->assertSame(['friends' => false], $flags->all());

        $this->actingAsAdmin();
        $this->patch("/admin/features/{$flag->id}/toggle");
        $this->assertSame(['friends' => true], $flags->all());

        $this->put("/admin/features/{$flag->id}", ['label' => 'Friends', 'enabled' => '0']);
        $this->assertSame(['friends' => false], $flags->all());

        $this->post('/admin/features', $this->payload(['key' => 'vendor_analytics']));
        $this->assertSame(['friends' => false, 'vendor_analytics' => true], $flags->all());

        $this->delete("/admin/features/{$flag->id}");
        $this->assertSame(['vendor_analytics' => true], $flags->all());
    }

    public function test_the_api_serves_what_the_admin_just_set(): void
    {
        $this->actingAsAdmin()->post('/admin/features', $this->payload(['key' => 'vendor_analytics', 'enabled' => '1']));

        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/features')->assertExactJson(['data' => ['vendor_analytics' => true]]);
    }

    public function test_the_api_serves_a_flag_the_admin_just_switched_off(): void
    {
        $flag = $this->flag('friends', true);

        $this->actingAsAdmin()->patch("/admin/features/{$flag->id}/toggle");

        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/features')->assertExactJson(['data' => ['friends' => false]]);
    }
}
