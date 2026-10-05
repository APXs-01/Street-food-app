<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

/**
 * Hardens the admin session (alias `secure.admin`):
 *
 * - Fixation: the login controller regenerates the session id and then calls
 *   bind(), which ties the session to the client's IP address and User-Agent.
 * - Binding: every admin request must present the same IP and User-Agent. A
 *   mismatch, or a session that was never bound, is logged out and the session
 *   destroyed. A stolen session cookie is therefore useless from another
 *   network or browser.
 * - Caching: every response carries no-store headers.
 *
 * The fingerprint is an HMAC under the app key, so the session store never
 * holds the raw IP or User-Agent and a stored value cannot be forged without
 * the key. Behind a reverse proxy, configure trusted proxies so ip() is the
 * real client address, otherwise the binding only sees the proxy.
 */
class SecureAdminSession
{
    public const SESSION_KEY = 'admin_session_fingerprint';

    public static function fingerprintFor(string $ip, string $userAgent): string
    {
        return hash_hmac('sha256', $ip.'|'.$userAgent, (string) config('app.key'));
    }

    /**
     * Bind the current session to this client. Call it right after logging in
     * and regenerating the session id.
     */
    public static function bind(Request $request): void
    {
        $request->session()->put(self::SESSION_KEY, self::fingerprintFor((string) $request->ip(), (string) $request->userAgent()));
    }

    public function handle(Request $request, Closure $next): Response
    {
        $expected = $request->session()->get(self::SESSION_KEY);
        $actual = self::fingerprintFor((string) $request->ip(), (string) $request->userAgent());

        if (! is_string($expected) || ! hash_equals($expected, $actual)) {
            return AdminNoCache::apply($this->endSession($request, bound: is_string($expected)));
        }

        return AdminNoCache::apply($next($request));
    }

    private function endSession(Request $request, bool $bound): Response
    {
        Log::warning('Admin session ended: client fingerprint did not match.', [
            'user_id' => Auth::guard('web')->id(),
            'ip' => $request->ip(),
            'was_bound' => $bound,
        ]);

        Auth::guard('web')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()
            ->route('admin.login')
            ->withErrors(['email' => 'Your session ended because your network or browser changed. Please sign in again.']);
    }
}
