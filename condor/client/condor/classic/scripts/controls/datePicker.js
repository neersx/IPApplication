angular.module('Inprotech')
    .directive('inDatePicker', ['url', function(url) {
        'use strict';
        return {
            restrict: 'E',
            templateUrl: url.of('scripts/controls/datePicker.html'),
            scope: {
                bindValue: '=',
                dateOnlyString: '=',
                minDate: '&',
                maxDate: '&',
                isRequired: '=',
                isDisabled: '='
            },
            link: function(scope, element, attrs) { // jshint ignore:line
                scope.open = function($event) {
                    $event.preventDefault();
                    $event.stopPropagation();

                    if (scope.opened) {
                        scope.opened = false;
                    } else {
                        scope.opened = true;
                    }
                };

                if (attrs.isfuturedate !== undefined) {
                    scope.minDate = new Date();
                }

                if (attrs.ispastdate !== undefined) {
                    scope.maxDate = new Date();
                }

                scope.$watch('bindValue', function() {
                    if (scope.bindValue && scope.bindValue instanceof Date) {
                        scope.dateOnlyString = scope.bindValue.getFullYear() + '\/' + (scope.bindValue.getMonth()+1) + '\/' + scope.bindValue.getDate();
                    }
                });
            }
        };
    }]);
