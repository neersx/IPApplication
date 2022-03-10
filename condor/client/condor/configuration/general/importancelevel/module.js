(function() {
    'use strict';

    angular.module('inprotech.configuration.general.importancelevel', [
        'inprotech.core',
        'inprotech.api',
        'inprotech.components'
    ]);

    angular.module('inprotech.configuration.general.importancelevel').config(function($stateProvider) {
        $stateProvider.state('importancelevel', {
            url: '/configuration/general/importancelevel',
            templateUrl: 'condor/configuration/general/importancelevel/importancelevel.html',
            controller: 'ImportanceLevelController',
            controllerAs: 'vm',
            resolve: {
                viewData: function(importanceLevelService) {
                    return importanceLevelService.viewData();
                }
            },
            data: {
                pageTitle: 'Importance Level Maintenance'
            }
        });
    });
})();
