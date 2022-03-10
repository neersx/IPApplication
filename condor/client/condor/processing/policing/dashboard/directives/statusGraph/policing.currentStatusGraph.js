angular.module('inprotech.processing.policing').directive('ipPolicingCurrentStatusGraph', function() {
    'use strict';

    return {
        restrict: 'E',
        templateUrl: 'condor/processing/policing/dashboard/directives/statusGraph/chart.html',
        scope: {
            data: '='
        },
        controller: 'ipCurrentStatusGraphController',
        controllerAs: 'vm'
    };
});
