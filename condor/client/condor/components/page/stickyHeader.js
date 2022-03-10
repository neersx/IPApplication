angular.module('inprotech.components.page').directive('ipStickyHeader', function() {
    'use strict';
    return {
        restrict: 'AE',
        transclude: true,
        template: '<div ng-transclude></div>',
        link: function(scope, element) {
            if (!element.length) {
                return;
            }

            var sensor = new window.ResizeSensor(element.children()[0], function() {
                adjustMargin();
            });

            scope.$on('$destroy', function() {
                sensor.detach();
            });

            var debouncedAdjust = _.debounce(adjustMargin, 100);

            $(window).on('resize', debouncedAdjust);

            adjustMargin();

            function adjustMargin() {
                if (!element.is(':visible')) {
                    return;
                }
                element.parent().css('paddingTop', element.height());
            }
        }
    };
});
