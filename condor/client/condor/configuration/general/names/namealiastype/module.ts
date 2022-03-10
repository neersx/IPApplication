angular.module('inprotech.configuration.general.names.namealiastype', [
    'inprotech.core',
    'inprotech.api',
    'inprotech.components'
]);

angular.module('inprotech.configuration.general.names.namealiastype')
    .run((modalService) => {
        modalService.register('NameAliasTypeMaintenance', 'NameAliasTypeMaintenanceController', 'condor/configuration/general/names/namealiastype/namealiastype.maintenance.html', {
            windowClass: 'centered picklist-window',
            backdropClass: 'centered',
            backdrop: 'static',
            size: 'lg'
        });
    });

angular.module('inprotech.configuration.general.names.namealiastype').config(($stateProvider) => {
    $stateProvider.state('namealiastype', {
        url: '/configuration/general/names/namealiastype',
        templateUrl: 'condor/configuration/general/names/namealiastype/namealiastype.html',
        controller: 'NameAliasTypeController',
        controllerAs: 'vm',
        resolve: {
            viewData: (NameAliasTypeService) => {
                return NameAliasTypeService.viewData();
            }
        },
        data: {
            pageTitle: 'Name Alias Type Maintenance'
        }
    });
});