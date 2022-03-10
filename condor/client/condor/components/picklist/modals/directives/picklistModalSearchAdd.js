angular.module('inprotech.components.picklist').directive('ipPicklistModalSearchAdd', function() {
    'use strict';

    return {
        restrict: 'E',
        transclude: true,
        scope: false,
        templateUrl: 'condor/components/picklist/modals/directives/picklistModalSearchAdd.html'
    };
});
