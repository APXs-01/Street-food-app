<?php

namespace Tests\Feature\Map;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NearbyAuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_the_map_endpoint_requires_a_token(): void
    {
        $this->getJson('/api/map/nearby?lat=6.9271&lng=79.8612')->assertUnauthorized();
    }
}
