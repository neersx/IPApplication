(function() {
    'use strict';
    angular.module('inprotech.dashboard', [
        'inprotech.core'
    ]);

    angular.module('inprotech.dashboard').config(function($stateProvider) {
        if (window.INPRO_DEBUG) {
            $stateProvider.state('dashboard', {
                url: '/dashboard',
                templateUrl: 'condor/dashboard/dashboard.html',
                controller: 'DashboardController',
                controllerAs: 'vm',
                resolve: {
                    appContext: 'appContext'
                }
            });
        }
    });
})();
