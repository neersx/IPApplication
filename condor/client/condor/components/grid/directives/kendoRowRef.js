// This component is still experimental. The intention is for replacing 'rowAttributes' property in kendo grid.
// The 'rowAttributes' property relies on custom row template which doesn't work very well in some scenarios, for example, column reordering. 
angular.module('inprotech.components.grid').directive('ipKendoRowRef', function() {
    'use strict';

    return {
        restrict: 'E',
        link: function(scope, element) {
            scope.$watch(function() {
                return element.attr('class');
            }, function(newClasses, oldClasses) {
                if (newClasses === oldClasses) {
                    return;
                }

                if (oldClasses) {
                    element.parents('tr').removeClass(oldClasses);
                }

                if (newClasses) {
                    element.parents('tr').addClass(newClasses);
                }
            });
        }
    };
});
