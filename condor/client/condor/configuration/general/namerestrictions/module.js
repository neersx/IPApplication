(function() {
    'use strict';

    angular.module('inprotech.configuration.general.namerestrictions', [
        'inprotech.core',
        'inprotech.api',
        'inprotech.components'
    ]);

    angular.module('inprotech.configuration.general.namerestrictions')
        .run(function(modalService) {
            modalService.register('NameRestrictionsMaintenance', 'NameRestrictionsMaintenanceController', 'condor/configuration/general/namerestrictions/namerestrictions.maintenance.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        });

    angular.module('inprotech.configuration.general.namerestrictions').config(function($stateProvider) {
        $stateProvider.state('namerestrictions', {
            url: '/configuration/general/namerestrictions',
            templateUrl: 'condor/configuration/general/namerestrictions/namerestrictions.html',
            controller: 'NameRestrictionsController',
            controllerAs: 'vm',
            resolve: {
                viewData: function(nameRestrictionsService) {
                    return nameRestrictionsService.viewData();
                }
            },
            data: {
                pageTitle: 'Name Restriction Maintenance'
            }
        });
    });
})();
