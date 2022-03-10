namespace inprotech.components.page {
    'use strict';

    // problem: fixed-positioned divs cannot specify width
    // in percentage of parent, only percentage of the window.
    // this directive helps to overcome the limitation by
    // measuring the parent and resizing fixed-positioned
    // child to match the parent

    export class MatchParentWidthDirective implements ng.IDirective {
        restrict: string;

        constructor() {
            this.restrict = 'A';
        }

        link(scope, element): any {
            if (!element.length) {
                return;
            }

            let parent = element.parent();

            doResize();

            $(window).resize(function() {
                window.setTimeout(doResize, 200);
            });

            function doResize() {
                element.css('width', parent.width());
            }
        }
    }
    angular.module('inprotech.components.page')
        .directive('matchParentWidth', () => new MatchParentWidthDirective());
}
