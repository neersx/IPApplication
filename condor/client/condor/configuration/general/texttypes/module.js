(function() {
    'use strict';

    angular.module('inprotech.configuration.general.texttypes', [
        'inprotech.core',
        'inprotech.api',
        'inprotech.components'
    ]);

    angular.module('inprotech.configuration.general.texttypes')
        .run(function(modalService) {
            modalService.register('TextTypeMaintenance', 'TextTypeMaintenanceController', 'condor/configuration/general/texttypes/texttypes.maintenance.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        });

    angular.module('inprotech.configuration.general.texttypes')
        .run(function(modalService) {
            modalService.register('ChangeTextTypeCode', 'ChangeTextTypeCodeController', 'condor/configuration/general/texttypes/texttypes.changecode.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        });

    angular.module('inprotech.configuration.general.texttypes').config(function($stateProvider) {
        $stateProvider.state('texttypes', {
            url: '/configuration/general/texttypes',
            templateUrl: 'condor/configuration/general/texttypes/texttypes.html',
            controller: 'textTypesController',
            controllerAs: 'vm',
            resolve: {
                viewData: function(textTypesService) {
                    return textTypesService.viewData();
                }
            },
            data: {
                pageTitle: 'Text Type Maintenance'
            }
        });
    });

})();
