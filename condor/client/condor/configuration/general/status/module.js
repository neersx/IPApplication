(function() {
    'use strict';

    angular.module('inprotech.configuration.general.status', [
        'inprotech.core',
        'inprotech.api',
        'inprotech.components'
    ]);

    angular.module('inprotech.configuration.general.status')
        .run(function(modalService) {
            modalService.register('StatusMaintenance', 'StatusMaintenanceController', 'condor/configuration/general/status/status.maintenance.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        })
        .config(function($stateProvider) {
            $stateProvider.state('status', {
                url: '/configuration/general/status',
                templateUrl: 'condor/configuration/general/status/status.html',
                controller: 'StatusController',
                controllerAs: 'vm',
                resolve: {
                    supportData: function(statusService) {
                        return statusService.supportData();
                    }
                },
                data: {
                    pageTitle: 'status.statusMaintenance'
                }
            });
        });
}());

