<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Spatie\Prometheus\Facades\Prometheus;
use Symfony\Component\HttpFoundation\Response;

class CalculateResponseTimeMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $responseTime = microtime(true) - LARAVEL_START;
        Prometheus::addGauge('response_time')
            ->value(function () use ($responseTime) {
                return $responseTime;
            });

        return $next($request);
    }
}
