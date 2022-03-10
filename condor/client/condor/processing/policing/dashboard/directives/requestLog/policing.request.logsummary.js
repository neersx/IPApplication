angular.module('inprotech.processing.policing').directive('ipPolicingRequestLogsummary', function() {
    'use strict';

    return {
        restrict: 'E',
        templateUrl: 'condor/processing/policing/dashboard/directives/requestLog/policing.request.logsummary.html',
        scope: {},
        controller: 'ipPolicingRequestLogsummaryController',
        controllerAs: 'vm'
    };
});
