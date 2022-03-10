angular.module('inprotech.configuration.general.names.locality', [
    'inprotech.core',
    'inprotech.api',
    'inprotech.components'
]);

angular.module('inprotech.configuration.general.names.locality')
    .run(function (modalService) {
        modalService.register('LocalityMaintenance', 'LocalityMaintenanceController', 'condor/configuration/general/names/locality/locality.maintenance.html', {
            windowClass: 'centered picklist-window',
            backdropClass: 'centered',
            backdrop: 'static',
            size: 'lg'
        });
    });

angular.module('inprotech.configuration.general.names.locality').config(function ($stateProvider) {
    $stateProvider.state('locality', {
        url: '/configuration/general/names/locality',
        templateUrl: 'condor/configuration/general/names/locality/locality.html',
        controller: 'LocalityController',
        controllerAs: 'vm',
        resolve: {
            viewData: function (LocalityService) {
                return LocalityService.viewData();
            }
        },
        data: {
            pageTitle: 'Locality Maintenance'
        }
    });
});