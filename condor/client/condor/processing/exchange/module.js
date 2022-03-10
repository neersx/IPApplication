(function() {
    'use strict';

    angular.module('inprotech.processing.exchange', [
        'inprotech.core',
        'inprotech.api',
        'inprotech.components'
    ]);

    angular.module('inprotech.processing.exchange').config(function($stateProvider) {
        $stateProvider.state('exchangeRequests', {
                url: '/exchange-requests',
                templateUrl: 'condor/processing/exchange/requests.html',
                controller: 'ExchangeRequestsController',
                controllerAs: 'vm',
                data: {
                    pageTitle: 'Exchange Integration'
                }
            })
            .state('exchangeSettings', {
                url: '/exchange-configuration',
                templateUrl: 'condor/processing/exchange/configuration/view.html',
                controller: 'ExchangeConfigurationController',
                controllerAs: 'vm',
                data: {
                    pageTitle: 'Configuration'
                },
                resolve: {
                    viewData: function($http) {
                        return $http.get('api/exchange/configuration/view').then(function(response) {
                            return response.data;
                        });
                    }
                }
            });
    });
})();
