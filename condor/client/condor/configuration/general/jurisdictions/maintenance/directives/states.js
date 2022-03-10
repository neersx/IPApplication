angular.module('inprotech.configuration.general.jurisdictions').directive('ipJurisdictionStates', function() {
    'use strict';
    return {
        restrict: 'E',
        scope: {
            parentId: '=',
            stateLabel: '='
        },
        controller: 'StatesController',
        controllerAs: 'vm',
        templateUrl: 'condor/configuration/general/jurisdictions/maintenance/directives/states.html',
        bindToController: {
            topic: '='
        }
    };
});

