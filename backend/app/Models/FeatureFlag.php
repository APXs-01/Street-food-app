<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

// key is fillable so a flag can be created, but nothing ever passes it on update:
// it is fixed for the life of the flag.
#[Fillable(['key', 'label', 'description', 'enabled'])]
class FeatureFlag extends Model
{
    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'enabled' => 'boolean',
        ];
    }
}
