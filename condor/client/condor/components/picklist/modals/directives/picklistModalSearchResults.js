angular.module('inprotech.components.picklist').directive('ipPicklistModalSearchResults', function() {
    'use strict';

    return {
        restrict: 'E',
        transclude: true,
        scope: false,
        templateUrl: 'condor/components/picklist/modals/directives/picklistModalSearchResults.html'
    };
});
