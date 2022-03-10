/**
 * This was implemented for content inside fixed components not being visible when the screen is too small.
 * When the browser or fixed element is resized, it will adjust the css height of this element to fit on the page.
 * It is intended for use on an element with overflow-y inside a fixed position element.
 **/

angular.module('inprotech.components.page').directive('ipResizeHandler', function(bus) {
    'use strict';
    return {
        restrict: 'EA',
        link: function(scope, element, attr) {
            var isScrollablePaneMode = attr['resizeHandlerType'] && attr['resizeHandlerType'].toUpperCase() === 'PANEL';
            if (isScrollablePaneMode) {
                attr.$addClass('main-content-scrollable');
            }
            var adjustHeight = initAdjustHeight(element);
            setTimeout(adjustHeight, 10);

            $(window).on('resize', adjustHeight);
            var containerSensor = tryInitContainerSensor();

            scope.$on('$destroy', function() {
                if (containerSensor) {
                    containerSensor.detach();
                }
                $(window).off('resize', adjustHeight);
                bus.channel('resize').unsubscribe(adjustHeight);
            });

            bus.channel('resize').subscribe(adjustHeight);

            function initAdjustHeight(element) {
                return _.debounce(function() {
                    if (!containerSensor) {
                        containerSensor = tryInitContainerSensor();
                    }

                    var availableHeight = getAvailableHeight(element);
                    var fullContentHeight = getFullContentHeight(element);

                    var heightToFit = (isScrollablePaneMode) ? (availableHeight - 40) : Math.min(fullContentHeight, availableHeight);
                    element.css('height', heightToFit);
                }, 50);
            }

            function getAvailableHeight(element) {
                var pageHeight = $('html').height();
                var elementPositionTop = element.position().top;
                var containerPositionTop = element.offsetParent().position().top;

                return pageHeight - containerPositionTop - elementPositionTop - 5;
            }

            function getFullContentHeight(element) {
                var borderHeight = element[0].offsetHeight - element[0].clientHeight;
                return element[0].scrollHeight + borderHeight;
            }

            function tryInitContainerSensor() {
                var parentOffset = element.offsetParent();
                if (parentOffset[0] == $('html')[0]) {
                    return null;
                }

                return new window.ResizeSensor(parentOffset, adjustHeight);
            }
        }
    }
});