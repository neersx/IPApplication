angular.module('inprotech.configuration.general.jurisdictions').directive('ipJurisdictionStatusFlags', function() {
    'use strict';
    return {
        restrict: 'E',
        scope: {
            parentId: '='
        },
        controller: 'StatusFlagsController',
        controllerAs: 'vm',
        templateUrl: 'condor/configuration/general/jurisdictions/maintenance/directives/statusflags.html',
        bindToController: {
            topic: '='
        }
    };
});

