angular.module('inprotech.configuration.general.jurisdictions').directive('ipJurisdictionAttributes', function() {
    'use strict';
    return {
        restrict: 'E',
        scope: {
            parentId: '=',
            reportPriorArt: '='
        },
        controller: 'AttributesController',
        controllerAs: 'vm',
        templateUrl: 'condor/configuration/general/jurisdictions/maintenance/directives/attributes.html',
        bindToController: {
            topic: '='
        }
    };
});
