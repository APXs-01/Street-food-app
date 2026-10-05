<x-admin-layout :title="'Inspection of '.$vendor->name">
    <div class="page-head">
        <div>
            <h1>Inspection of {{ $vendor->name }}</h1>
            <p class="lede">
                <span class="badge {{ $checklist->grade->tone() }}">{{ $checklist->grade->label() }}</span>
                {{ number_format($checklist->score, 1) }} out of 5
                @if ($isCurrent)
                    <span class="badge ok">Current rating</span>
                @else
                    <span class="badge">Superseded by a later inspection</span>
                @endif
            </p>
        </div>
        <div class="actions">
            <a class="btn secondary" href="{{ route('admin.inspections.index', ['vendor' => $vendor->id]) }}">All inspections of this stall</a>
            <a class="btn secondary" href="{{ route('admin.inspections.index') }}">Back to inspections</a>
        </div>
    </div>

    <div class="two-col">
        <div class="panel">
            <dl class="details">
                <dt>Stall</dt>
                <dd>
                    <a href="{{ route('admin.vendors.show', $vendor) }}">{{ $vendor->name }}</a>
                    <small>({{ $vendor->stall_code }})</small>
                    @unless ($vendor->user->is_active)
                        <span class="badge warn">Owner suspended</span>
                    @endunless
                </dd>

                <dt>Inspected</dt>
                <dd>{{ $checklist->inspected_at->format('j M Y, H:i') }}</dd>

                <dt>Submitted to the server</dt>
                <dd>{{ $inspection->submitted_at->format('j M Y, H:i:s') }} <small>(the source of truth)</small></dd>

                <dt>Inspector</dt>
                <dd>
                    <a href="{{ route('admin.users.show', $inspection->inspector) }}">{{ $inspection->inspector->name }}</a>
                    @unless ($inspection->inspector->is_active)
                        <span class="badge warn">Suspended</span>
                    @endunless
                </dd>

                <dt>Organisation</dt>
                <dd>{{ $inspection->organization ?? '—' }} <small>(as recorded at the time)</small></dd>

                <dt>Official ID</dt>
                <dd>{{ $inspection->inspector->inspectorProfile?->official_id ?? '—' }}</dd>

                <dt>Region</dt>
                <dd>{{ $inspection->inspector->inspectorProfile?->region ?? '—' }}</dd>
            </dl>
        </div>

        <div class="panel">
            <table>
                <thead><tr><th>Criterion</th><th>Result</th></tr></thead>
                <tbody>
                    @foreach (\App\Models\HygieneChecklist::CRITERIA as $criterion)
                        @php $result = $checklist->{$criterion}; @endphp
                        <tr>
                            <td>{{ Str::headline($criterion) }}</td>
                            <td><span class="badge {{ $result->tone() }}">{{ $result->label() }}</span></td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>

    <h2>Inspector's notes</h2>
    <div class="panel panel-pad">
        {{ $inspection->notes ?? 'No notes.' }}
    </div>

    <h2>Evidence photo</h2>
    <div class="panel panel-pad">
        <img class="cover" src="{{ \App\Support\Media::url($inspection->evidence_photo_path) }}" alt="Evidence photo for the inspection of {{ $vendor->name }}">

        <dl class="details" style="padding: 12px 0 0">
            <dt>Taken (device clock)</dt>
            <dd>{{ $inspection->evidence_capture_time?->format('j M Y, H:i:s') ?? 'Not reported by the device' }}</dd>

            <dt>Location</dt>
            <dd>
                @if ($inspection->evidence_latitude !== null)
                    {{ $inspection->evidence_latitude }}, {{ $inspection->evidence_longitude }}
                    @if ($evidenceDistance !== null)
                        @php
                            $away = $evidenceDistance >= 1000
                                ? number_format($evidenceDistance / 1000, 1).' km'
                                : number_format(round($evidenceDistance)).' m';
                        @endphp
                        <br><small>About {{ $away }} from the stall's listed location</small>
                    @endif
                @else
                    Not recorded
                @endif
            </dd>
        </dl>
    </div>
</x-admin-layout>
