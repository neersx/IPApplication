angular.module('inprotech.configuration.general.jurisdictions').directive('ipJurisdictionGroups', function() {
    'use strict';
    return {
        restrict: 'E',
        scope: {
            parentId: '=',
            type: '='
        },
        controller: 'GroupsController',
        controllerAs: 'vm',
        templateUrl: 'condor/configuration/general/jurisdictions/maintenance/directives/groups.html',
        bindToController: {
            topic: '='
        }
    };
});
