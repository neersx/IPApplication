(function() {
    'use strict';

    angular.module('inprotech.configuration.general.numbertypes', [
        'inprotech.core',
        'inprotech.api',
        'inprotech.components'
    ]);

    angular.module('inprotech.configuration.general.numbertypes')
        .run(function(modalService) {
            modalService.register('NumberTypeMaintenance', 'NumberTypeMaintenanceController', 'condor/configuration/general/numbertypes/numbertypes.maintenance.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        });

    angular.module('inprotech.configuration.general.numbertypes')
        .run(function(modalService) {
            modalService.register('ChangeNumberTypeCode', 'ChangeNumberTypeCodeController', 'condor/configuration/general/numbertypes/numbertypes.changecode.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        });

    angular.module('inprotech.configuration.general.numbertypes').config(function($stateProvider) {
        $stateProvider.state('numbertypes', {
            url: '/configuration/general/numbertypes',
            templateUrl: 'condor/configuration/general/numbertypes/numbertypes.html',
            controller: 'NumberTypesController',
            controllerAs: 'vm',
            resolve: {
                viewData: function(numberTypesService) {
                    return numberTypesService.viewData();
                }
            },
            data: {
                pageTitle: 'Number Type Maintenance'
            }
        });
    });

     angular.module('inprotech.configuration.general.numbertypes')
        .run(function(modalService) {
            modalService.register('NumberTypesOrder', 'NumberTypesOrderController', 'condor/configuration/general/numbertypes/numbertypes.order.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        });
})();
