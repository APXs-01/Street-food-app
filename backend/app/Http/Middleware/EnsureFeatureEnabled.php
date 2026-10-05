<?php

namespace App\Http\Middleware;

use App\Services\FeatureFlags;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * A live kill-switch (alias `feature`, used as feature:consumer.friends). When an
 * administrator turns the flag off, the route answers 403 with a plain message,
 * not 404: a 404 would look like a routing bug rather than a deliberate block.
 *
 * A flag nobody has created yet counts as ON, so wiring a route to a flag that
 * is not defined never blocks anything by accident. Only an explicitly disabled
 * flag blocks. It runs after authentication, so a signed-out caller still gets 401.
 */
class EnsureFeatureEnabled
{
    public function __construct(private FeatureFlags $flags)
    {
    }

    public function handle(Request $request, Closure $next, string $key): Response
    {
        if (! $this->flags->isEnabled($key, default: true)) {
            return response()->json(['message' => 'This feature is currently unavailable.'], 403);
        }

        return $next($request);
    }
}
