<x-admin-layout title="Inspections">
    <div class="page-head">
        <div>
            <h1>Inspections</h1>
            <p class="lede">
                {{ number_format($inspections->total()) }} {{ Str::plural('inspection', $inspections->total()) }}
                across every stall. This is a read-only audit trail: inspections are never edited or deleted here.
            </p>
        </div>
    </div>

    <form class="toolbar" method="GET" action="{{ route('admin.inspections.index') }}">
        <input type="text" name="q" value="{{ $filters['q'] ?? '' }}" placeholder="Search stall, inspector, organisation or official ID" aria-label="Search inspections">

        <select name="grade" aria-label="Grade">
            <option value="">Any grade</option>
            @foreach ($grades as $grade)
                <option value="{{ $grade->value }}" @selected(($filters['grade'] ?? null) === $grade->value)>{{ $grade->label() }}</option>
            @endforeach
        </select>

        <label class="inline" for="from">From</label>
        <input id="from" type="date" name="from" value="{{ $filters['from'] ?? '' }}">
        <label class="inline" for="to">To</label>
        <input id="to" type="date" name="to" value="{{ $filters['to'] ?? '' }}">

        <label class="inline">
            <input type="checkbox" name="failures" value="1" @checked($filters['failures'] ?? false)>
            Has a failed criterion
        </label>

        @if (! empty($filters['vendor']))
            <input type="hidden" name="vendor" value="{{ $filters['vendor'] }}">
        @endif
        @if (! empty($filters['inspector']))
            <input type="hidden" name="inspector" value="{{ $filters['inspector'] }}">
        @endif

        <button type="submit">Filter</button>

        @if (array_filter($filters))
            <a class="btn secondary" href="{{ route('admin.inspections.index') }}">Reset</a>
        @endif
    </form>

    @if (! empty($filters['vendor']) || ! empty($filters['inspector']))
        <p class="muted">
            Showing
            @if (! empty($filters['vendor'])) one stall's inspections @endif
            @if (! empty($filters['inspector'])) one inspector's inspections @endif
            &middot; <a href="{{ route('admin.inspections.index') }}">show all</a>
        </p>
    @endif

    <div class="panel table-wrap">
        <table>
            <thead>
                <tr>
                    <th>Inspected</th>
                    <th>Stall</th>
                    <th>Result</th>
                    <th>Inspector</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                @forelse ($inspections as $inspection)
                    @php
                        $checklist = $inspection->checklist;
                        $failed = count($checklist->failedCriteria());
                    @endphp
                    <tr>
                        <td>{{ $checklist->inspected_at->format('j M Y') }}<br><small>{{ $checklist->inspected_at->format('H:i') }}</small></td>
                        <td>
                            <a href="{{ route('admin.vendors.show', $checklist->vendor) }}">{{ $checklist->vendor->name }}</a>
                            <br><small>{{ $checklist->vendor->stall_code }}</small>
                        </td>
                        <td>
                            <span class="badge {{ $checklist->grade->tone() }}">{{ $checklist->grade->label() }}</span>
                            <small>{{ number_format($checklist->score, 1) }}/5</small>
                            @if ($failed > 0)
                                <br><small>{{ $failed }} {{ Str::plural('criterion', $failed) }} failed</small>
                            @endif
                        </td>
                        <td>
                            <a href="{{ route('admin.users.show', $inspection->inspector) }}">{{ $inspection->inspector->name }}</a>
                            <br><small>{{ $inspection->organization ?? $inspection->inspector->inspectorProfile?->organization ?? '—' }}</small>
                        </td>
                        <td class="actions">
                            <a class="btn secondary" href="{{ route('admin.inspections.show', $inspection) }}">View</a>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="5" class="empty">No inspections match.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    {{ $inspections->links('admin.pagination') }}
</x-admin-layout>
