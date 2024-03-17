<?php

namespace App\Providers;

use App\Http\Middleware\CalculateResponseTimeMiddleware;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(CalculateResponseTimeMiddleware::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // So, if our app is served via a loadbalancer such as nginx-ingress with https enabled on
        // ingress itself, we also need a way to serve our assets as https, because technically our nginx web server
        // is not running https, it is just forwarding the request from loadbalancer to our app, ending https the moment
        // our request actually is recevied by nginx. Another way to fix this is to add
        // the load balancer ip to the App\Http\Middleware\TrustProxies middleware.
        // @see https://laravel.com/docs/10.x/requests#configuring-trusted-proxies
        // Adding ip to trused proxies is recommended way but we do it here.
        if ($this->app->environment('production')) {
            URL::forceScheme('https');
        }
    }
}
