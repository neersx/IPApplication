'use strict';
angular.module('inprotech.names.consolidation', [])
    .config(function($stateProvider) {
        $stateProvider
            .state('namesConsolidation', {
                url: '/names/consolidation',
                templateUrl: 'condor/names/consolidation/names-consolidation.html',
                controller: 'NamesConsolidationController',
                controllerAs: 'vm',
                data: {
                    pageTitle: 'namesConsolidation.pageTitle'
                }
            });
    });

angular.module('inprotech.names.consolidation')
    .run(function(modalService) {
        modalService.register('NamesConsolidationConfirmation', 'NamesConsolidationConfirmationController', 'condor/names/consolidation/names-consolidation-confirmation.html', {
            windowClass: 'centered picklist-window',
            backdrop: 'static',
            controllerAs: 'vm',
            size: 'lg'
        });
    });