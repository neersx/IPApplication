angular.module('inprotech.configuration.search', [
    'inprotech.core',
    'inprotech.api',
    'inprotech.components',
    'angular-clipboard'
]);

angular.module('inprotech.configuration.search')
    .config(function ($stateProvider) {
        $stateProvider
            .state('configurations', {
                url: '/configuration/search',
                templateUrl: 'condor/configuration/search/index.html',
                controller: 'ConfigurationsController',
                controllerAs: 'vm',
                resolve: {
                    viewData: function ($http) {
                        return $http.get('api/configuration/search/view').then(function (response) {
                            return response.data;
                        });
                    }
                },
                data: {
                    pageTitle: 'configurations.pageTitle'
                }
            })
    })
    .run(function (modalService) {
        modalService.register('ConfigurationItemMaintenance', 'ConfigurationItemMaintenanceController', 'condor/configuration/search/configuration.item.maintenance.html', {
            windowClass: 'centered picklist-window',
            backdropClass: 'centered',
            backdrop: 'static',
            size: 'lg'
        });
    });