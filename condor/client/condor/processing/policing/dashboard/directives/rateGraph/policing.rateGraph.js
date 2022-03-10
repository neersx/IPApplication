angular.module('inprotech.processing.policing').directive('ipPolicingRateGraph', function() {
    'use strict';

    return {
        restrict: 'E',
        templateUrl: 'condor/processing/policing/dashboard/directives/rateGraph/chart.html',
        scope: {
            data: '='
        },
        controller: 'ipPolicingRateGraphController',
        controllerAs: 'vm'
    };
});
