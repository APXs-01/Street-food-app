<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\SignsInAdmin;
use Tests\TestCase;

class UserManagementTest extends TestCase
{
    use RefreshDatabase;
    use SignsInAdmin;

    public function test_it_needs_an_admin(): void
    {
        $user = User::factory()->create();

        $this->get('/admin/users')->assertRedirect(route('admin.login'));
        $this->get("/admin/users/{$user->id}")->assertRedirect(route('admin.login'));
        $this->get('/admin/users/create')->assertRedirect(route('admin.login'));

        $this->actingAs(User::factory()->create())->get('/admin/users')->assertForbidden();
    }

    // ---- listing, search and filters ------------------------------------

    public function test_it_lists_every_account_with_role_and_status(): void
    {
        User::factory()->create(['name' => 'Maya Chen']);
        User::factory()->vendor()->create(['name' => 'Raju Silva']);
        User::factory()->inspector()->create(['name' => 'Adshaja Perera']);
        User::factory()->create(['name' => 'Suspended Sam', 'is_active' => false]);

        $this->actingAsAdmin()
            ->get('/admin/users')
            ->assertOk()
            ->assertSee('Maya Chen')
            ->assertSee('Raju Silva')
            ->assertSee('Adshaja Perera')
            ->assertSee('Suspended')
            ->assertViewHas('users', fn ($users) => $users->total() === 5);
    }

    public function test_it_filters_by_role(): void
    {
        User::factory()->create(['name' => 'Maya Chen']);
        User::factory()->vendor()->create(['name' => 'Raju Silva']);

        $this->actingAsAdmin()
            ->get('/admin/users?role=vendor')
            ->assertOk()
            ->assertSee('Raju Silva')
            ->assertDontSee('Maya Chen')
            ->assertViewHas('users', fn ($users) => $users->total() === 1);
    }

    public function test_it_filters_by_active_or_suspended(): void
    {
        User::factory()->create(['name' => 'Active Amy']);
        User::factory()->create(['name' => 'Suspended Sam', 'is_active' => false]);

        $this->actingAsAdmin()
            ->get('/admin/users?status=suspended')
            ->assertSee('Suspended Sam')
            ->assertDontSee('Active Amy');

        $this->get('/admin/users?status=active')
            ->assertSee('Active Amy')
            ->assertDontSee('Suspended Sam');
    }

    public function test_it_searches_name_email_username_and_phone(): void
    {
        User::factory()->create([
            'name' => 'Maya Chen',
            'email' => 'maya@example.com',
            'username' => 'maya_bites',
            'phone' => '+94771234567',
        ]);
        User::factory()->create(['name' => 'Someone Else', 'email' => 'other@example.com']);

        $this->actingAsAdmin();

        foreach (['Chen', 'maya@example', 'maya_bites', '+94771234567', '0771234567', '077 123 4567'] as $term) {
            $this->get('/admin/users?'.http_build_query(['q' => $term]))
                ->assertOk()
                ->assertSee('Maya Chen')
                ->assertDontSee('Someone Else');
        }
    }

    public function test_search_and_filters_combine(): void
    {
        User::factory()->create(['name' => 'Kaveen Customer']);
        User::factory()->vendor()->create(['name' => 'Kaveen Vendor']);

        $this->actingAsAdmin()
            ->get('/admin/users?q=Kaveen&role=vendor')
            ->assertSee('Kaveen Vendor')
            ->assertDontSee('Kaveen Customer');
    }

    public function test_it_says_when_nothing_matches(): void
    {
        $this->actingAsAdmin()->get('/admin/users?q=zzzzzz')->assertOk()->assertSee('No users match.');
    }

    public function test_it_rejects_unknown_filter_values(): void
    {
        $this->actingAsAdmin()
            ->get('/admin/users?role=nonsense&status=maybe')
            ->assertSessionHasErrors(['role', 'status']);
    }

    public function test_it_is_paginated_and_keeps_the_filters_in_the_page_links(): void
    {
        User::factory()->count(30)->create();

        $this->actingAsAdmin()
            ->get('/admin/users?role=consumer')
            ->assertOk()
            ->assertViewHas('users', fn ($users) => $users->count() === 25 && $users->total() === 30)
            ->assertSee('role=consumer&amp;page=2', false);

        $this->get('/admin/users?role=consumer&page=2')
            ->assertViewHas('users', fn ($users) => $users->count() === 5);
    }

    // ---- detail ----------------------------------------------------------

    public function test_a_customer_page_shows_their_details_and_activity(): void
    {
        $customer = User::factory()->create(['name' => 'Maya Chen', 'email' => 'maya@example.com', 'username' => 'maya_bites']);
        $customer->createToken('phone');
        $customer->createToken('tablet');

        $this->actingAsAdmin()
            ->get("/admin/users/{$customer->id}")
            ->assertOk()
            ->assertSee('Maya Chen')
            ->assertSee('maya@example.com')
            ->assertSee('Active API sessions')
            ->assertViewHas('user', fn (User $user) => $user->tokens_count === 2);
    }

    public function test_a_vendor_page_links_to_their_stall(): void
    {
        $stall = Vendor::factory()->create(['name' => 'Raju Kottu']);

        $this->actingAsAdmin()
            ->get("/admin/users/{$stall->user_id}")
            ->assertOk()
            ->assertSee('Raju Kottu')
            ->assertSee(route('admin.vendors.show', $stall), false);
    }

    public function test_an_inspector_page_shows_their_profile(): void
    {
        $inspector = User::factory()->inspector()->create();
        $inspector->inspectorProfile()->create([
            'organization' => 'Colombo Municipal Health Council',
            'official_id' => 'PHI-0042',
            'region' => 'Colombo',
        ]);

        $this->actingAsAdmin()
            ->get("/admin/users/{$inspector->id}")
            ->assertOk()
            ->assertSee('Colombo Municipal Health Council')
            ->assertSee('PHI-0042');
    }

    // ---- suspend and reactivate -------------------------------------------

    public function test_suspending_a_user_revokes_all_their_tokens_and_only_theirs(): void
    {
        $user = User::factory()->create(['name' => 'Maya Chen']);
        $user->createToken('phone');
        $user->createToken('tablet');

        $bystander = User::factory()->create();
        $bystander->createToken('phone');

        $this->actingAsAdmin()
            ->from('/admin/users')
            ->patch("/admin/users/{$user->id}/deactivate")
            ->assertRedirect('/admin/users')
            ->assertSessionHas('status');

        $this->assertFalse($user->fresh()->is_active);
        $this->assertSame(0, $user->tokens()->count());
        $this->assertSame(1, $bystander->tokens()->count());
    }

    public function test_every_non_admin_role_can_be_suspended(): void
    {
        $this->actingAsAdmin();

        foreach ([User::factory(), User::factory()->vendor(), User::factory()->inspector()] as $factory) {
            $user = $factory->create();
            $user->createToken('phone');

            $this->patch("/admin/users/{$user->id}/deactivate")->assertRedirect();

            $this->assertFalse($user->fresh()->is_active);
            $this->assertSame(0, $user->tokens()->count());
        }
    }

    public function test_a_suspended_user_cannot_sign_in_and_can_after_reactivation(): void
    {
        $user = User::factory()->create(['email' => 'maya@example.com', 'password' => 'password123']);
        $user->createToken('phone');

        $this->actingAsAdmin();
        $this->patch("/admin/users/{$user->id}/deactivate")->assertRedirect();

        $login = ['login' => 'maya@example.com', 'password' => 'password123'];

        $this->postJson('/api/consumer/login', $login)
            ->assertForbidden()
            ->assertJsonPath('message', 'This account has been suspended.');

        $this->patch("/admin/users/{$user->id}/reactivate")->assertRedirect();

        // The old tokens are gone for good; signing in issues a new one.
        $this->assertTrue($user->fresh()->is_active);
        $this->assertSame(0, $user->tokens()->count());

        $this->postJson('/api/consumer/login', $login)->assertOk();
        $this->assertSame(1, $user->tokens()->count());
    }

    public function test_suspending_or_reactivating_twice_is_harmless(): void
    {
        $user = User::factory()->create(['name' => 'Maya Chen']);
        $this->actingAsAdmin();

        $this->patch("/admin/users/{$user->id}/reactivate")
            ->assertSessionHas('status', 'Maya Chen is already active.');

        $this->patch("/admin/users/{$user->id}/deactivate")->assertRedirect();
        $this->patch("/admin/users/{$user->id}/deactivate")
            ->assertSessionHas('status', 'Maya Chen is already suspended.');

        $this->assertFalse($user->fresh()->is_active);
    }

    public function test_administrator_accounts_cannot_be_suspended_including_your_own(): void
    {
        $admin = $this->makeAdmin();
        $otherAdmin = $this->makeAdmin();
        $admin->createToken('cli');

        $this->actingAsAdmin($admin);

        $this->patch("/admin/users/{$otherAdmin->id}/deactivate")->assertForbidden();
        $this->patch("/admin/users/{$admin->id}/deactivate")->assertForbidden();

        $this->assertTrue($admin->fresh()->is_active);
        $this->assertTrue($otherAdmin->fresh()->is_active);
        $this->assertSame(1, $admin->tokens()->count());
    }

    public function test_a_non_admin_cannot_suspend_anyone(): void
    {
        $victim = User::factory()->create();

        $this->actingAs(User::factory()->create())
            ->patch("/admin/users/{$victim->id}/deactivate")
            ->assertForbidden();

        $this->assertTrue($victim->fresh()->is_active);
    }

    // ---- the model-level guarantee ----------------------------------------

    public function test_a_token_stops_working_the_moment_the_account_is_suspended(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('phone')->plainTextToken;

        // Any path that flips the flag revokes: no admin panel involved here.
        $user->forceFill(['is_active' => false])->save();

        $this->assertSame(0, $user->tokens()->count());
        $this->withToken($token)->getJson('/api/user')->assertUnauthorized();
    }

    public function test_other_changes_keep_the_tokens(): void
    {
        $user = User::factory()->create();
        $user->createToken('phone');

        $user->update(['name' => 'A New Name']);
        $user->forceFill(['last_login_at' => now()])->save();

        $this->assertSame(1, $user->tokens()->count());
    }

    // ---- creating inspectors ---------------------------------------------

    public function test_the_add_inspector_form_renders(): void
    {
        $this->actingAsAdmin()
            ->get('/admin/users/create')
            ->assertOk()
            ->assertSee('Add inspector')
            ->assertSee('Official ID');
    }

    public function test_an_admin_can_create_an_inspector_who_can_then_sign_in(): void
    {
        $this->actingAsAdmin()
            ->post('/admin/users', [
                'name' => 'Adshaja Perera',
                'email' => 'Adshaja@Health.Example',
                'phone' => '077 111 2222',
                'password' => 'inspector-pass-1',
                'password_confirmation' => 'inspector-pass-1',
                'organization' => 'Colombo Municipal Health Council',
                'official_id' => 'PHI-0042',
                'region' => 'Colombo',
            ])
            ->assertRedirect()
            ->assertSessionHas('status');

        $inspector = User::where('email', 'adshaja@health.example')->firstOrFail();

        $this->assertSame('inspector', $inspector->role->value);
        $this->assertTrue($inspector->hasRole('inspector'));
        $this->assertSame('+94771112222', $inspector->phone);
        $this->assertSame('PHI-0042', $inspector->inspectorProfile->official_id);
        $this->assertSame('Colombo Municipal Health Council', $inspector->inspectorProfile->organization);

        $this->postJson('/api/inspector/login', ['login' => 'adshaja@health.example', 'password' => 'inspector-pass-1'])
            ->assertOk()
            ->assertJsonPath('user.role', 'inspector');
    }

    public function test_creating_an_inspector_validates_the_form(): void
    {
        User::factory()->create(['email' => 'taken@example.com']);
        User::factory()->inspector()->create()->inspectorProfile()->create([
            'organization' => 'Somewhere',
            'official_id' => 'PHI-0001',
        ]);

        $this->actingAsAdmin();

        $this->post('/admin/users', [])
            ->assertSessionHasErrors(['name', 'email', 'password', 'organization', 'official_id']);

        $this->post('/admin/users', [
            'name' => 'Dup Inspector',
            'email' => 'taken@example.com',
            'phone' => 'not a number',
            'password' => 'inspector-pass-1',
            'password_confirmation' => 'different-pass',
            'organization' => 'Somewhere',
            'official_id' => 'PHI-0001',
        ])->assertSessionHasErrors(['email', 'phone', 'password', 'official_id']);

        $this->assertDatabaseCount('inspector_profiles', 1);
    }

    public function test_a_non_admin_cannot_create_an_inspector(): void
    {
        $this->actingAs(User::factory()->create())
            ->post('/admin/users', ['name' => 'Sneaky'])
            ->assertForbidden();

        $this->assertDatabaseMissing('users', ['name' => 'Sneaky']);
    }
}
