angular.module('inprotech.components.tooltip')
    .directive('ipTooltip', function($compile) {
        'use strict';

        return {
            restrict: 'A',
            terminal: true,
            priority: 1000,
            scope: true,
            link: function($scope, element, attrs) {
                // Disabled elements need a wrapper div for tooltip to be displayed correctly in all browsers
                if (element.is('button, a') && attrs.ngDisabled) {
                    element.wrap('<div class="tooltip-wrap" ng-class="{disabled:' + attrs.ngDisabled + '}" uib-tooltip="' + attrs.ipTooltip + '"></div>');
                    if (attrs.tooltipPlacement) {
                        element.parent().attr('data-tooltip-placement', attrs.tooltipPlacement);
                    }

                    element.removeAttr('ip-tooltip');
                    $compile(element.parent())($scope);
                } else {
                    attrs.$set('uib-tooltip', attrs.ipTooltip);
                    if (attrs.class && attrs.class.indexOf('tooltip-error') !== -1) {
                        // inherit tooltip-error from element to tooltip
                        attrs.$set('tooltip-class', 'tooltip-error');
                    }

                    element.removeAttr('ip-tooltip');
                    $compile(element)($scope);
                }
            }
        };
    });
