angular.module('inprotech.components.tooltip')
    .directive('ipInlineDialog', function () {
        'use strict';

        return {
            restrict: 'E',
            scope: {
                'template': '@',
                'title': '@',
                'content': '@',
                'placement': '@',
                'popoverClass': '@'
            },
            replace: true,
            templateUrl: 'condor/components/tooltip/inlineDialog.html'
        };
    });
