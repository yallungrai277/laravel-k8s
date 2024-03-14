<?php

namespace App\Providers;

use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // So, if our app is served via a loadbalancer such as nginx-ingress with https enabled on
        // ingress itself, we also need a way to serve our assets as https, because technically our nginx web server
        // is not running https, it is just forwarding the request from loadbalancer to our app, ending https the moment
        // our request actually is recevied by nginx.
        if ($this->app->environment('production')) {
            URL::forceScheme('https');
        }
    }
}
