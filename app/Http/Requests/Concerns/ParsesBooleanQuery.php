<?php

namespace App\Http\Requests\Concerns;

/**
 * Query strings carry booleans as text. Call parseBooleans() from
 * prepareForValidation() so true/false/1/0 all satisfy the `boolean` rule;
 * anything unrecognised is left alone and fails validation as usual.
 */
trait ParsesBooleanQuery
{
    /**
     * @param  array<int, string>  $keys
     */
    protected function parseBooleans(array $keys): void
    {
        foreach ($keys as $key) {
            if (! $this->has($key)) {
                continue;
            }

            $parsed = filter_var($this->input($key), FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);

            if ($parsed !== null) {
                $this->merge([$key => $parsed]);
            }
        }
    }
}
