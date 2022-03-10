angular.module('inprotech.configuration.general.jurisdictions').directive('ipJurisdictionTexts', function() {
    'use strict';
    return {
        restrict: 'E',
        scope: {
            parentId: '='
        },
        controller: 'TextsController',
        controllerAs: 'vm',
        templateUrl: 'condor/configuration/general/jurisdictions/maintenance/directives/texts.html',
        bindToController: {
            topic: '='
        }
    };
});
