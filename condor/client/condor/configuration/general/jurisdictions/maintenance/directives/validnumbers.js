angular.module('inprotech.configuration.general.jurisdictions').directive('ipJurisdictionValidNumbers', function() {
    'use strict';
    return {
        restrict: 'E',
        scope: {
            parentId: '='
        },
        controller: 'ValidNumbersController',
        controllerAs: 'vm',
        templateUrl: 'condor/configuration/general/jurisdictions/maintenance/directives/validnumbers.html',
        bindToController: {
            topic: '='
        }
    };
});

