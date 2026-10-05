<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\DailyStatus;
use App\Models\StatusComment;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

/**
 * Moderation of daily statuses and their comments. Hiding is reversible and
 * takes effect at query time on the public API (hidden content is excluded from
 * feeds and counts and answers 404 by direct access). The panel sees everything,
 * including content by suspended accounts. There is no delete here: authors can
 * delete their own, and the daily purge removes old statuses.
 */
class CommunityModerationController extends Controller
{
    public function index(Request $request): View
    {
        $filters = $request->validate([
            'type' => ['nullable', Rule::in(['statuses', 'comments'])],
            'state' => ['nullable', Rule::in(['visible', 'hidden'])],
            'q' => ['nullable', 'string', 'max:100'],
        ]);

        $type = $filters['type'] ?? 'statuses';

        return view('admin.community.index', [
            'type' => $type,
            'filters' => $filters,
            'items' => $type === 'statuses' ? $this->statuses($filters) : $this->comments($filters),
            'hiddenCounts' => [
                'statuses' => DailyStatus::where('is_hidden', true)->count(),
                'comments' => StatusComment::where('is_hidden', true)->count(),
            ],
        ]);
    }

    public function hideStatus(Request $request, DailyStatus $status): RedirectResponse
    {
        return $this->hide($request, $status, 'status');
    }

    public function unhideStatus(Request $request, DailyStatus $status): RedirectResponse
    {
        return $this->unhide($request, $status, 'status');
    }

    public function hideComment(Request $request, StatusComment $comment): RedirectResponse
    {
        return $this->hide($request, $comment, 'comment');
    }

    public function unhideComment(Request $request, StatusComment $comment): RedirectResponse
    {
        return $this->unhide($request, $comment, 'comment');
    }

    /**
     * @param  array<string, mixed>  $filters
     */
    private function statuses(array $filters)
    {
        return DailyStatus::query()
            ->with(['user', 'vendor'])
            ->withCount(['likes', 'comments'])
            ->when($filters['q'] ?? null, function (Builder $query, string $term) {
                $like = '%'.addcslashes(trim($term), '%_\\').'%';

                $query->where(fn (Builder $match) => $match
                    ->where('body', 'like', $like)
                    ->orWhere('location_label', 'like', $like)
                    ->orWhereHas('user', fn (Builder $author) => $author->where('name', 'like', $like)->orWhere('email', 'like', $like)));
            })
            ->when($filters['state'] ?? null, fn (Builder $query, string $state) => $query->where('is_hidden', $state === 'hidden'))
            ->latest()
            ->orderByDesc('id')
            ->paginate(25)
            ->withQueryString();
    }

    /**
     * @param  array<string, mixed>  $filters
     */
    private function comments(array $filters)
    {
        return StatusComment::query()
            ->with(['user', 'status.user'])
            ->when($filters['q'] ?? null, function (Builder $query, string $term) {
                $like = '%'.addcslashes(trim($term), '%_\\').'%';

                $query->where(fn (Builder $match) => $match
                    ->where('body', 'like', $like)
                    ->orWhereHas('user', fn (Builder $author) => $author->where('name', 'like', $like)->orWhere('email', 'like', $like)));
            })
            ->when($filters['state'] ?? null, fn (Builder $query, string $state) => $query->where('is_hidden', $state === 'hidden'))
            ->latest()
            ->orderByDesc('id')
            ->paginate(25)
            ->withQueryString();
    }

    private function hide(Request $request, DailyStatus|StatusComment $item, string $kind): RedirectResponse
    {
        Gate::authorize('moderate-content');

        $data = $request->validate(['reason' => ['nullable', 'string', 'max:255']]);

        $item->hideBy($request->user(), $data['reason'] ?? null);

        Log::info("Admin hid a {$kind}.", ['admin_id' => $request->user()->id, "{$kind}_id" => $item->id]);

        return $this->backTo($kind)->with('status', ucfirst($kind).' hidden. It no longer shows to anyone but its author.');
    }

    private function unhide(Request $request, DailyStatus|StatusComment $item, string $kind): RedirectResponse
    {
        Gate::authorize('moderate-content');

        $item->unhideBy($request->user());

        Log::info("Admin unhid a {$kind}.", ['admin_id' => $request->user()->id, "{$kind}_id" => $item->id]);

        return $this->backTo($kind)->with('status', ucfirst($kind).' restored.');
    }

    private function backTo(string $kind): RedirectResponse
    {
        return redirect()->back(fallback: route('admin.community.index', ['type' => $kind === 'status' ? 'statuses' : 'comments']));
    }
}
