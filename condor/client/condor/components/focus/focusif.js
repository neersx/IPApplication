angular.module('inprotech.components.focus').directive('focusIf', function($timeout) {
    'use strict';

    return {
        restrict: 'A',
        link: function(scope, element, attrs) {
            if (scope.$eval(attrs.focusIf)) {
                $timeout(function() {
                    element.focus();
                }, 0);
            }
        }
    };
});
