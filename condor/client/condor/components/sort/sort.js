angular.module('inprotech.components.sort')
    .directive('inSort', function() {
        'use strict';
        return {
            restrict: 'A',
            transclude: true,
            templateUrl: 'condor/components/sort/sort.html',
            scope: {
                by: '@',
                inSort: '='
            },
            link: function(scope, elem, attr) {
                scope.value = scope.inSort ? scope.inSort : scope.$parent;

                var sortByThis = function(reverse) {
                    scope.value.order = scope.by;
                    scope.value.reverse = reverse;
                };

                if (attr.defaultsortasc !== undefined) {
                    sortByThis(false);
                }
                if (attr.defaultsortdesc !== undefined) {
                    sortByThis(true);
                }

                scope.onClick = function() {
                    if (scope.by === scope.value.order) {
                        scope.value.reverse = !scope.value.reverse;
                    } else {
                        sortByThis(false);
                    }
                };
            }
        };
    });
