'use strict';

function DataItemMaintenance(): ng.IDirective {
    return {
        restrict: 'E',
        templateUrl: 'condor/configuration/general/dataitem/directives/dataitemmaintenance.html',
        scope: {
            model: '=',
            maintenance: '=',
            state: '=?',
            src: '@?',
            errors: '=?',
            saveCall: '=?'
        },
        controller: 'ipDataItemMaintenanceController',
        controllerAs: 'vm'
    }
}

angular.module('inprotech.configuration.general.dataitem')
    .directive('ipDataItemMaintenance', DataItemMaintenance);