angular.module('inprotech.processing.policing').directive('ipQueueErrorview', function() {
    'use strict';

    return {
        restrict: 'E',
        templateUrl: 'condor/processing/policing/queue/directives/errorView/queue.errorview.html',
        scope: {
            parent: '='
        },
        controller: 'ipQueueErrorviewController',
        controllerAs: 'vm'
    };
});
