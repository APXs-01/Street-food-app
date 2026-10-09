<?php

namespace App\Services;

use App\Support\Media;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;
use Intervention\Image\Drivers\Gd\Driver as GdDriver;
use Intervention\Image\Format;
use Intervention\Image\ImageManager;

/**
 * Resizes uploaded photos and writes them to the media disk. Everything is
 * re-encoded as JPEG, which also strips EXIF data such as embedded GPS.
 */
class ImageStorage
{
    private ImageManager $images;

    public function __construct()
    {
        $this->images = ImageManager::usingDriver(GdDriver::class);
    }

    /**
     * Store the photo under the directory and return its path on the media disk.
     */
    public function store(UploadedFile $file, string $directory, int $maxSide = 1280, int $quality = 80): string
    {
        $encoded = $this->images
            ->decodeSplFileInfo($file)
            ->orient()
            ->scaleDown($maxSide, $maxSide)
            ->encodeUsingFormat(Format::JPEG, quality: $quality);

        $path = trim($directory, '/').'/'.Str::uuid().'.jpg';

        Media::disk()->put($path, $encoded->toString());

        return $path;
    }

    /**
     * Store a short video as uploaded. It is not transcoded (that needs ffmpeg)
     * and its length cannot be checked here, so the app enforces the duration
     * and the request enforces the size cap.
     */
    public function storeVideo(UploadedFile $file, string $directory): string
    {
        return Media::disk()->putFile(trim($directory, '/'), $file);
    }

    public function delete(?string $path): void
    {
        if ($path !== null) {
            Media::disk()->delete($path);
        }
    }
}
