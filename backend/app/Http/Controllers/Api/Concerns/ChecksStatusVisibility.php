<?php

namespace App\Http\Controllers\Api\Concerns;

use App\Models\DailyStatus;
use Illuminate\Support\Facades\Gate;

trait ChecksStatusVisibility
{
    /**
     * A status the user may not see answers 404, not 403, so friends-only and
     * expired statuses do not reveal that they exist.
     */
    protected function ensureVisible(DailyStatus $status): void
    {
        abort_unless(Gate::allows('view', $status), 404);
    }
}
