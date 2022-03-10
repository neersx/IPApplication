angular.module('inprotech.processing.policing').directive('ipRequestLogerror', function() {
    'use strict';

    return {
        restrict: 'E',
        templateUrl: 'condor/processing/policing/requestsLog/directives/policing.request.logerror.html',
        scope: {
            data: '='
        },
        controller: 'ipPolicingRequestLogerrorController',
        controllerAs: 'vm'
    };
});
