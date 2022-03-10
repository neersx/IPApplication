angular.module('inprotech.components.picklist').directive('ipPicklistModalSearch', function() {
    'use strict';

    return {
        restrict: 'E',
        transclude: true,
        scope: false,
        templateUrl: 'condor/components/picklist/modals/directives/picklistModalSearch.html'
    };
});
