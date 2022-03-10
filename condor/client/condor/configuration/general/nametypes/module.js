(function() {
    'use strict';

    angular.module('inprotech.configuration.general.nametypes', [
        'inprotech.core',
        'inprotech.api',
        'inprotech.components'
    ]);

    angular.module('inprotech.configuration.general.nametypes')
        .run(function(modalService) {
            modalService.register('NameTypeMaintenance', 'NameTypeMaintenanceController', 'condor/configuration/general/nametypes/nametypes.maintenance.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        });

    angular.module('inprotech.configuration.general.nametypes').config(function($stateProvider) {
        $stateProvider.state('nametypes', {
            url: '/configuration/general/nametypes',
            templateUrl: 'condor/configuration/general/nametypes/nametypes.html',
            controller: 'NameTypesController',
            controllerAs: 'vm',
            resolve: {
                viewData: function(nameTypesService) {
                    return nameTypesService.viewData();
                }
            },
            data: {
                pageTitle: 'Name Type Maintenance'
            }
        });
    });

    angular.module('inprotech.configuration.general.nametypes')
        .run(function(modalService) {
            modalService.register('NameTypesOrder', 'NameTypesOrderController', 'condor/configuration/general/nametypes/nametypes.order.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        });
})();