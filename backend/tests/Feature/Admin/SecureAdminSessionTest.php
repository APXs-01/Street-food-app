<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Tests\Concerns\SignsInAdmin;
use Tests\TestCase;

class SecureAdminSessionTest extends TestCase
{
    use RefreshDatabase;
    use SignsInAdmin;

    public function test_a_session_bound_to_this_client_is_accepted(): void
    {
        $this->actingAsAdmin()->get('/admin')->assertOk();
    }

    public function test_a_different_ip_address_ends_the_session(): void
    {
        $this->actingAsAdmin();

        $this->get('/admin')->assertOk();

        $this->withServerVariables(['REMOTE_ADDR' => '203.0.113.9'])
            ->get('/admin')
            ->assertRedirect(route('admin.login'))
            ->assertSessionHasErrors('email');

        $this->assertGuest();
    }

    public function test_a_different_user_agent_ends_the_session(): void
    {
        $this->actingAsAdmin();

        $this->withHeader('User-Agent', 'SomeoneElsesBrowser/9.9')
            ->get('/admin')
            ->assertRedirect(route('admin.login'));

        $this->assertGuest();
    }

    public function test_the_session_stays_dead_after_a_mismatch_even_for_the_original_client(): void
    {
        $this->actingAsAdmin();

        $this->withServerVariables(['REMOTE_ADDR' => '203.0.113.9'])->get('/admin')->assertRedirect(route('admin.login'));

        $this->withServerVariables(['REMOTE_ADDR' => '127.0.0.1'])
            ->withHeader('User-Agent', self::ADMIN_USER_AGENT)
            ->get('/admin')
            ->assertRedirect(route('admin.login'));
    }

    public function test_a_session_that_was_never_bound_is_rejected(): void
    {
        // Authenticated, but not through the admin login, so no fingerprint was stored.
        $this->actingAs($this->makeAdmin())
            ->withHeader('User-Agent', self::ADMIN_USER_AGENT)
            ->get('/admin')
            ->assertRedirect(route('admin.login'));

        $this->assertGuest();
    }

    public function test_a_signed_in_non_admin_is_forbidden(): void
    {
        $this->actingAs(User::factory()->create())->get('/admin')->assertForbidden();
    }

    public function test_an_api_token_does_not_open_the_admin_panel(): void
    {
        $admin = $this->makeAdmin();
        $token = $admin->createToken('test')->plainTextToken;

        $this->withToken($token)->get('/admin')->assertRedirect(route('admin.login'));
    }

    public function test_the_dashboard_is_uncacheable(): void
    {
        $this->assertNotCacheable($this->actingAsAdmin()->get('/admin'));
    }

    public function test_responses_produced_before_the_session_check_are_uncacheable_too(): void
    {
        // The login page, a guest redirect and a 403 never reach SecureAdminSession.
        $this->assertNotCacheable($this->get('/admin/login'));
        $this->assertNotCacheable($this->get('/admin'));
    }

    public function test_a_forbidden_response_is_uncacheable(): void
    {
        $this->assertNotCacheable($this->actingAs(User::factory()->create())->get('/admin'));
    }

    public function test_the_mismatch_redirect_is_uncacheable_too(): void
    {
        $this->actingAsAdmin();

        $this->assertNotCacheable(
            $this->withServerVariables(['REMOTE_ADDR' => '203.0.113.9'])->get('/admin'),
        );
    }

    public function test_pages_outside_the_admin_are_not_affected(): void
    {
        $cacheControl = (string) $this->get('/')->headers->get('Cache-Control');

        $this->assertStringNotContainsString('no-store', $cacheControl);
    }

    public function test_every_admin_route_except_login_is_behind_the_full_middleware_stack(): void
    {
        $guarded = 0;

        foreach (Route::getRoutes() as $route) {
            if (! str_starts_with($route->uri(), 'admin') || $route->uri() === 'admin/login') {
                continue;
            }

            $guarded++;

            foreach (['auth', 'admin', 'secure.admin'] as $middleware) {
                $this->assertContains($middleware, $route->gatherMiddleware(), "{$route->uri()} is missing {$middleware}");
            }
        }

        $this->assertGreaterThan(10, $guarded);
    }
}
