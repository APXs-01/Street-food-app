<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Keeps every response under /admin out of browser and proxy caches, including
 * the login page, guest redirects and 403s that are produced before
 * SecureAdminSession runs. Registered on the web group.
 */
class AdminNoCache
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        return $request->is('admin', 'admin/*') ? static::apply($response) : $response;
    }

    public static function apply(Response $response): Response
    {
        $response->headers->set('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0, private');
        $response->headers->set('Pragma', 'no-cache');
        $response->headers->set('Expires', '0');

        return $response;
    }
}
