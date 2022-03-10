angular.module('inprotech.components.notification').directive('ipInlineAlert', function() {
    'use strict';

    return {
        restrict: 'EA',
        transclude: true,
        scope: {
            text: '@',
            type: '@',
            textParams: '<'
        },
        template: '<div class="alert alert-{{type}}"><icon name="info-circle"></icon><span translate="{{text}}" translate-values="textParams"></span><ng-transclude></ng-transclude></div>'
    };
});