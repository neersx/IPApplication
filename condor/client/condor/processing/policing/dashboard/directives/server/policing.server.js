angular.module('inprotech.processing.policing').directive('ipPolicingServerStatus', function() {
    'use strict';

    return {
        restrict: 'E',
        templateUrl: 'condor/processing/policing/dashboard/directives/server/status.html',
        scope: {},
        controller: 'ipPolicingServerStatusController',
        controllerAs: 'vm'
    };
});
