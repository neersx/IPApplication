angular.module('inprotech.configuration.general.validcombination')
    .directive('ipControllerParser', function ($compile, $parse) {
        'use strict';
        return {
            restrict: 'A',
            priority: 1000,
            terminal: true,
            link: function (scope, element) {
                var name = $parse(element.attr('ip-controller-parser'))(scope);
                element = element.removeAttr('ip-controller-parser');
                element.attr('controller-name', name);
                $compile(element)(scope);
            }
        };
    });
