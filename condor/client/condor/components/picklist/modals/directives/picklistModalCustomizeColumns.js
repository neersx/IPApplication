angular.module('inprotech.components.picklist').directive('ipPicklistModalCustomizeColumns', function() {
    'use strict';

    return {
        restrict: 'E',
        scope: false,
        templateUrl: 'condor/components/picklist/modals/directives/picklistModalCustomizeColumns.html',
        link: function(scope, element, attrs){
            if(attrs.iconRight == ""){
                scope.iconRight = true;
            }
        }
    };
});
