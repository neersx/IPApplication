(function() {
    'use strict';

    angular.module('inprotech.configuration.general.dataitem', [
        'inprotech.core',
        'inprotech.api',
        'inprotech.components'
    ]);

    angular.module('inprotech.configuration.general.dataitem').config(function($stateProvider) {
        $stateProvider.state('dataitem', {
            url: '/configuration/general/dataitems',
            templateUrl: 'condor/configuration/general/dataitem/dataitem.html',
            controller: 'DataItemController',
            controllerAs: 'vm',
            resolve: {
                viewData: function(dataItemService) {
                    return dataItemService.viewData();
                }
            },
            data: {
                pageTitle: 'Data Item Maintenance'
            }
        });
    });

    angular.module('inprotech.configuration.general.dataitem')
        .run(function(modalService) {
            modalService.register('DataItemMaintenanceConfig', 'DataItemMaintenanceConfigController', 'condor/configuration/general/dataitem/dataitem.maintenance.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'xl'
            });
        });
})();