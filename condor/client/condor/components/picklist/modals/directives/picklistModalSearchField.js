angular.module('inprotech.components.picklist').directive('ipPicklistModalSearchField', function() {
    'use strict';

    return {
        restrict: 'E',
        transclude: true,
        scope: false,
        templateUrl: 'condor/components/picklist/modals/directives/picklistModalSearchField.html',
        link: function($scope) {
            $scope.keydown = function($event) {
                var triggerEvent;
                switch ($event.keyCode) {
                    case 40: // down arrow
                        triggerEvent = 'setFocus';
                        break;
                    case 34: // page down
                        triggerEvent = 'nextPage';
                        break;
                    case 33: // page up
                        triggerEvent = 'previousPage';
                        break;
                    case 35: // end
                        triggerEvent = 'lastPage';
                        break;
                    case 36: // home
                        triggerEvent = 'firstPage';
                        break;
                }

                if (triggerEvent) {
                    var resultsGrid = $('ip-picklist-modal-search-results ip-kendo-grid');
                    if (resultsGrid.length > 0) {
                        resultsGrid.trigger(triggerEvent);
                    }
                }
            };
        }
    };
});
