angular.module('inprotech.configuration.general.jurisdictions').directive('ipJurisdictionValidCombinations', function() {
    'use strict';
    return {
        restrict: 'E',
        scope: {
            parentId: '=',
            parentName: '=',
            displayLink: '='
        },
        controller: 'ValidCombinationsController',
        controllerAs: 'vm',
        templateUrl: 'condor/configuration/general/jurisdictions/maintenance/directives/combinations.html',
        bindToController: {
            topic: '='
        }
    };
});
