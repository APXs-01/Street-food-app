<?php

namespace App\Support;

use Illuminate\Support\Facades\Storage;

/**
 * Single entry point to the media disk so the disk is a config decision.
 */
final class Media
{
    /**
     * @return \Illuminate\Filesystem\FilesystemAdapter
     */
    public static function disk()
    {
        return Storage::disk(config('filesystems.media_disk'));
    }

    public static function url(?string $path): ?string
    {
        return $path === null ? null : static::disk()->url($path);
    }
}
