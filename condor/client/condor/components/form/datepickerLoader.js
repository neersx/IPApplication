angular.module('inprotech.components.form')
    .directive('ipDatepickerLoader', function($compile, $parse) {
        'use strict';

        var knownStates = ['idle', 'loading'];

        function isValidState(state) {
            return _.any(knownStates, function(t) {
                return t === state;
            });
        }

        return {
            require: '^?ipDatepicker',
            link: function(scope, element, attrs) {
                scope.state = 'idle';
                var stateBinding = $parse(attrs.ipDatepickerLoader);

                var button = element.find('span.date-content-wrap');
                var loaderSpan = $compile('<span data-ng-if="state===\'loading\'" class="input-action"><span class="cpa-icon loading-circle"></span></span>')(scope);

                button.append(loaderSpan);

                scope.$watch(stateBinding, function(newVal, oldVal) {
                    if (isValidState(newVal) && newVal != oldVal) {
                        scope.state = newVal;
                    }
                });
            }
        }
    });