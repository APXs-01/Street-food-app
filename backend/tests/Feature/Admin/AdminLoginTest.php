<?php

namespace Tests\Feature\Admin;

use App\Http\Middleware\SecureAdminSession;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\SignsInAdmin;
use Tests\TestCase;

class AdminLoginTest extends TestCase
{
    use RefreshDatabase;
    use SignsInAdmin;

    /**
     * @return array<string, string>
     */
    private function credentials(string $password = 'correct-horse-battery'): array
    {
        return ['email' => 'admin@streetbite.test', 'password' => $password];
    }

    private function adminWithPassword(): User
    {
        return $this->makeAdmin(['email' => 'admin@streetbite.test', 'password' => 'correct-horse-battery']);
    }

    public function test_guests_are_sent_to_the_login_page(): void
    {
        $this->get('/admin')->assertRedirect(route('admin.login'));
    }

    public function test_the_login_page_renders(): void
    {
        $this->get('/admin/login')
            ->assertOk()
            ->assertSee('Sign in')
            ->assertSee('name="email"', false);
    }

    public function test_a_super_admin_can_sign_in_and_reach_the_dashboard(): void
    {
        $admin = $this->adminWithPassword();

        $this->withHeader('User-Agent', self::ADMIN_USER_AGENT)
            ->post('/admin/login', $this->credentials())
            ->assertRedirect(route('admin.dashboard'));

        $this->assertAuthenticatedAs($admin);
        $this->assertNotNull($admin->fresh()->last_login_at);

        $this->get('/admin')->assertOk()->assertSee('Dashboard');
    }

    public function test_signing_in_replaces_the_session_id(): void
    {
        $this->adminWithPassword();
        $cookieName = config('session.cookie');

        $visit = $this->get('/admin/login');
        $idBefore = $visit->getCookie($cookieName)->getValue();

        // Send the pre-login cookie back, so the id can only change through a regeneration.
        $encrypted = $visit->getCookie($cookieName, false)->getValue();
        $idAfter = $this->withUnencryptedCookie($cookieName, $encrypted)
            ->post('/admin/login', $this->credentials())
            ->getCookie($cookieName)
            ->getValue();

        $this->assertNotSame($idBefore, $idAfter);
    }

    public function test_the_session_is_bound_to_the_client_on_login(): void
    {
        $this->adminWithPassword();

        $this->withHeader('User-Agent', self::ADMIN_USER_AGENT)->post('/admin/login', $this->credentials());

        $this->assertSame(
            SecureAdminSession::fingerprintFor('127.0.0.1', self::ADMIN_USER_AGENT),
            session(SecureAdminSession::SESSION_KEY),
        );
    }

    public function test_a_wrong_password_is_rejected_with_the_generic_message(): void
    {
        $this->adminWithPassword();

        $this->post('/admin/login', $this->credentials('not-the-password'))
            ->assertRedirect()
            ->assertSessionHasErrors(['email' => trans('auth.failed')]);

        $this->assertGuest();
    }

    public function test_only_super_admins_can_sign_in_and_others_get_the_same_message(): void
    {
        foreach ([User::factory(), User::factory()->vendor(), User::factory()->inspector()] as $index => $factory) {
            $factory->create(['email' => "user{$index}@streetbite.test", 'password' => 'correct-horse-battery']);

            $this->post('/admin/login', ['email' => "user{$index}@streetbite.test", 'password' => 'correct-horse-battery'])
                ->assertSessionHasErrors(['email' => trans('auth.failed')]);

            $this->assertGuest();
        }
    }

    public function test_a_suspended_admin_cannot_sign_in(): void
    {
        $this->makeAdmin(['email' => 'admin@streetbite.test', 'password' => 'correct-horse-battery', 'is_active' => false]);

        $this->post('/admin/login', $this->credentials())
            ->assertSessionHasErrors(['email' => trans('auth.failed')]);

        $this->assertGuest();
    }

    public function test_repeated_failures_are_rate_limited(): void
    {
        $this->adminWithPassword();

        foreach (range(1, 5) as $attempt) {
            $this->post('/admin/login', $this->credentials('wrong'))->assertSessionHasErrors('email');
        }

        // Even the right password is refused once the limit is hit.
        $this->post('/admin/login', $this->credentials())->assertStatus(429);
        $this->assertGuest();
    }

    public function test_signing_out_ends_the_session(): void
    {
        $this->actingAsAdmin()
            ->post('/admin/logout')
            ->assertRedirect(route('admin.login'));

        $this->assertGuest();
        $this->get('/admin')->assertRedirect(route('admin.login'));
    }

    public function test_a_signed_in_admin_is_sent_past_the_login_page(): void
    {
        $this->actingAsAdmin()->get('/admin/login')->assertRedirect(route('admin.dashboard'));
    }
}
