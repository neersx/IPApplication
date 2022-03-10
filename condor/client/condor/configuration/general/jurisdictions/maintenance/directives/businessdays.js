angular.module('inprotech.configuration.general.jurisdictions').directive('ipJurisdictionBusinessDays', function() {
    'use strict';
    return {
        restrict: 'E',
        scope: {
            parentId: '=',
            workDayFlag: '='
        },
        controller: 'BusinessDaysController',
        controllerAs: 'vm',
        templateUrl: 'condor/configuration/general/jurisdictions/maintenance/directives/businessdays.html',
        bindToController: {
            topic: '='
        }
    };
});

