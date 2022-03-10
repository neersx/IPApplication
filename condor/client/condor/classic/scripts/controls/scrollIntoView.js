angular.module('Inprotech')
    .directive('scrollIntoView', function() {
        'use strict';

        function link(scope, element, attrs) {
            scope.$watch(attrs.scrollIntoView, function(value) {
                if (value) {
                    scrollIntoViewIfNeeded(element[0]);
                }
            });

            element.on('$destroy', function() {
                element.unbind();
            });

            function scrollIntoViewIfNeeded(target) {
                var parent = target.offsetParent;
                if (parent) {
                    scrollTo(target, parent);
                }
            }

            function scrollTo(element, parent) {
                var parentBottom = parent.offsetTop + parent.offsetHeight;

                var elementTop = element.offsetTop;
                var elementBottom = elementTop + element.offsetHeight;

                if (elementTop > parent.scrollTop && elementBottom < parent.scrollTop + parent.offsetHeight) {
                    return;
                }

                var scrollTop;
                if (elementTop < parent.scrollTop) {
                    scrollTop = { scrollTop: elementTop };
                } else {
                    scrollTop = { scrollTop: parent.scrollTop + (elementBottom - parentBottom) };
                }

                $(parent).animate(scrollTop, 100);
                return this;
            }
        }

        return {
            restrict: 'A',
            link: link
        };
    });