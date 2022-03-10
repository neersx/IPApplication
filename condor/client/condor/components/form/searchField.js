angular.module('inprotech.components.form').directive('ipSearchField', function($timeout) {
    'use strict';

    return {
        restrict: 'E',
        templateUrl: 'condor/components/form/searchField.html',
        scope: {
            value: '=?',
            search: '&'
        },
        link: function(scope, element) {
            scope.clear = function() {
                if (scope.value) {
                    scope.value = null;
                    $timeout(function() {
                        scope.search({
                            value: scope.value
                        });
                    });
                }
            };

            element.find('.input-wrap').on('click', function() {
                element.find('input[type="text"]').focus();
            });

            scope.$on('$destroy', function() {
                element.find('.input-wrap').off('click');
            });

            element.on('setFocus', function() {
                setTimeout(function() {
                    element.find('input[type="text"]').focus();
                }, 300);
            });
        }
    };
});
