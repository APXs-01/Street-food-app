<x-admin-layout title="Hygiene">
    <div class="page-head">
        <div>
            <h1>Hygiene</h1>
            <p class="lede">
                Where every stall stands right now, and what is coming due. Ratings come only from inspections.
                For what happened in a visit, open the inspection.
            </p>
        </div>
    </div>

    <div class="grid" style="margin-bottom: 20px">
        <a @class(['card', 'attention' => $summary['overdue'] > 0]) href="{{ route('admin.hygiene.index', ['state' => 'overdue']) }}">
            <div class="label">Overdue</div>
            <div class="value">{{ number_format($summary['overdue']) }}</div>
            <div class="sub">re-verification date has passed</div>
        </a>
        <a class="card" href="{{ route('admin.hygiene.index', ['state' => 'due_soon']) }}">
            <div class="label">Due in the next {{ $soonDays }} {{ Str::plural('day', $soonDays) }}</div>
            <div class="value">{{ number_format($summary['due_soon']) }}</div>
        </a>
        <a class="card" href="{{ route('admin.hygiene.index', ['state' => 'current']) }}">
            <div class="label">Current</div>
            <div class="value">{{ number_format($summary['current']) }}</div>
            <div class="sub">due later than that</div>
        </a>
        <a class="card" href="{{ route('admin.hygiene.index', ['state' => 'not_inspected']) }}">
            <div class="label">Never inspected</div>
            <div class="value">{{ number_format($summary['not_inspected']) }}</div>
            <div class="sub">of {{ number_format($summary['total']) }} {{ Str::plural('stall', $summary['total']) }}</div>
        </a>
    </div>

    <form class="toolbar" method="GET" action="{{ route('admin.hygiene.index') }}">
        <input type="text" name="q" value="{{ $filters['q'] ?? '' }}" placeholder="Search stall, code or owner" aria-label="Search stalls">

        <select name="state" aria-label="State">
            <option value="">Any state</option>
            <option value="overdue" @selected(($filters['state'] ?? null) === 'overdue')>Overdue</option>
            <option value="due_soon" @selected(($filters['state'] ?? null) === 'due_soon')>Due soon</option>
            <option value="current" @selected(($filters['state'] ?? null) === 'current')>Current</option>
            <option value="not_inspected" @selected(($filters['state'] ?? null) === 'not_inspected')>Never inspected</option>
        </select>

        <select name="grade" aria-label="Grade">
            <option value="">Any grade</option>
            @foreach ($grades as $grade)
                <option value="{{ $grade->value }}" @selected(($filters['grade'] ?? null) === $grade->value)>{{ $grade->label() }}</option>
            @endforeach
        </select>

        <select name="water" aria-label="Water source">
            <option value="">Any water source</option>
            <option value="verified" @selected(($filters['water'] ?? null) === 'verified')>Safe water verified</option>
            <option value="unverified" @selected(($filters['water'] ?? null) === 'unverified')>Inspected, water not verified</option>
        </select>

        <select name="sort" aria-label="Sort by">
            <option value="due" @selected($sort === 'due')>Most urgent first</option>
            <option value="score" @selected($sort === 'score')>Lowest score first</option>
            <option value="name" @selected($sort === 'name')>Name</option>
        </select>

        <button type="submit">Apply</button>

        @if (array_filter($filters))
            <a class="btn secondary" href="{{ route('admin.hygiene.index') }}">Reset</a>
        @endif
    </form>

    <div class="panel table-wrap">
        <table>
            <thead>
                <tr>
                    <th>Stall</th>
                    <th>Current rating</th>
                    <th>Safe water</th>
                    <th>Last inspected</th>
                    <th>Re-verification</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                @forelse ($stalls as $stall)
                    @php
                        $checklist = $stall->latestChecklist;
                        $due = $stall->reverification_due_at;
                        $days = $due ? (int) now()->startOfDay()->diffInDays($due->copy()->startOfDay(), false) : null;
                        $failed = $checklist ? array_map(fn ($criterion) => Str::headline($criterion), $checklist->failedCriteria()) : [];
                    @endphp
                    <tr>
                        <td>
                            <a href="{{ route('admin.vendors.show', $stall) }}">{{ $stall->name }}</a>
                            <br><small>{{ $stall->stall_code }} &middot; {{ $stall->user->name }}</small>
                            @unless ($stall->user->is_active) <br><span class="badge warn">Owner suspended</span> @endunless
                        </td>
                        <td>
                            @if ($stall->hygiene_grade)
                                <span class="badge {{ $stall->hygiene_grade->tone() }}">{{ $stall->hygiene_grade->label() }}</span>
                                <small>{{ number_format($stall->hygiene_score, 1) }}/5</small>
                                @if ($failed)
                                    <br><small>Failed: {{ implode(', ', $failed) }}</small>
                                @endif
                            @else
                                <span class="badge">Not inspected</span>
                            @endif
                        </td>
                        <td>
                            @if ($stall->last_inspected_at)
                                @if ($stall->water_source_verified)
                                    <span class="badge ok">Verified</span>
                                @else
                                    <span class="badge warn">Not verified</span>
                                @endif
                            @else
                                <small>—</small>
                            @endif
                        </td>
                        <td>
                            @if ($stall->last_inspected_at)
                                {{ $stall->last_inspected_at->format('j M Y') }}
                                <br><small>{{ $stall->last_inspected_at->diffForHumans() }}</small>
                            @else
                                <small>Never</small>
                            @endif
                        </td>
                        <td>
                            @if ($due)
                                {{ $due->format('j M Y') }}<br>
                                @if ($due->isPast())
                                    <span class="badge danger">{{ $days === 0 ? 'Overdue since today' : abs($days).' '.Str::plural('day', abs($days)).' overdue' }}</span>
                                @elseif ($due->lt(now()->addDays($soonDays)))
                                    <span class="badge warn">{{ $days === 0 ? 'Due today' : 'Due in '.$days.' '.Str::plural('day', $days) }}</span>
                                @else
                                    <span class="badge ok">In {{ $days }} {{ Str::plural('day', $days) }}</span>
                                @endif
                            @else
                                <small>—</small>
                            @endif
                        </td>
                        <td class="actions">
                            @if ($checklist?->submission)
                                <a href="{{ route('admin.inspections.show', $checklist->submission) }}">Latest inspection</a><br>
                            @endif
                            <a href="{{ route('admin.inspections.index', ['vendor' => $stall->id]) }}">History</a>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="empty">No stalls match.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    {{ $stalls->links('admin.pagination') }}
</x-admin-layout>
