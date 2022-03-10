angular.module('inprotech.configuration.general.names.namerelations', [
    'inprotech.core',
    'inprotech.api',
    'inprotech.components'
]);

angular.module('inprotech.configuration.general.names.namerelations')
    .run(function (modalService) {
        modalService.register('NameRelationMaintenance', 'NameRelationMaintenanceController', 'condor/configuration/general/names/namerelations/namerelation.maintenance.html', {
            windowClass: 'centered picklist-window',
            backdropClass: 'centered',
            backdrop: 'static',
            size: 'lg'
        });
    });

angular.module('inprotech.configuration.general.names.namerelations').config(function ($stateProvider) {
    $stateProvider.state('namerelations', {
        url: '/configuration/general/names/namerelations',
        templateUrl: 'condor/configuration/general/names/namerelations/namerelations.html',
        controller: 'NameRelationController',
        controllerAs: 'vm',
        data: {
            pageTitle: 'Name Relation Code Maintenance'
        }
    });
});