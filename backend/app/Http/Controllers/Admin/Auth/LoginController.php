<?php

namespace App\Http\Controllers\Admin\Auth;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Middleware\SecureAdminSession;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class LoginController extends Controller
{
    public function create(): View
    {
        return view('admin.login');
    }

    /**
     * Only an active super-admin can sign in here. Every other outcome (wrong
     * password, wrong role, suspended account, unknown email) gives the same
     * message, so the form does not reveal which accounts exist. There is no
     * "remember me": a long-lived cookie would outlive the session binding.
     */
    public function store(Request $request): RedirectResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
        ]);

        $signedIn = Auth::guard('web')->attempt([
            ...$credentials,
            'role' => UserRole::SuperAdmin->value,
            'is_active' => true,
        ]);

        if (! $signedIn) {
            throw ValidationException::withMessages(['email' => trans('auth.failed')]);
        }

        // Fixation defence: a new session id for the authenticated session, then
        // tie it to this client (see SecureAdminSession).
        $request->session()->regenerate();
        SecureAdminSession::bind($request);

        $request->user()->forceFill(['last_login_at' => now()])->save();

        return redirect()->intended(route('admin.dashboard'));
    }

    public function destroy(Request $request): RedirectResponse
    {
        Auth::guard('web')->logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login')->with('status', 'You have been signed out.');
    }
}
