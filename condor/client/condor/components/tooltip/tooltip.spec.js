describe('inprotech.components.tooltip', function() {
    'use strict';

    var scope, element, compileDirective;
    beforeEach(function() {
        module('inprotech.components.tooltip');
    });

    beforeEach(inject(function($compile, $rootScope) {
        scope = $rootScope.$new();

        compileDirective = function(customMarkup) {
            var defaultMarkup = angular.element('<button ip-tooltip="Tooltip text">Mischa Button</button>');
            element = $compile(customMarkup || defaultMarkup)(scope);
            scope.$digest();
        };
    }));

    describe('tooltip directive', function() {
        it('initialises uib tooltip', function() {
            compileDirective();
            expect(element.attr('uib-tooltip')).toBe('Tooltip text');
        });

        it('derives tooltip-error class from element class', function() {
            compileDirective('<icon class="tooltip-error" ip-tooltip="error tooltip"></icon>');
            expect(element.attr('tooltip-class')).toBe('tooltip-error');
        });

        it('wraps disabled buttons with correct attributes so tooltips will still work', function() {
            compileDirective('<button data-tooltip-placement="left" ip-tooltip="disabled text" ng-disabled="true">Disabled button</button>');
            var wrapperElement = element.parent();
            expect(wrapperElement).toBeDefined();
            expect(wrapperElement.attr('uib-tooltip')).toBe('disabled text');
            expect(wrapperElement.prop('tagName')).toBe('DIV');
            expect(wrapperElement.attr('data-tooltip-placement')).toBe('left');
            expect(wrapperElement.attr('class')).toMatch('disabled');
        });

        it('wraps disabled <a> with correct attributes so tooltips will still work', function() {
            compileDirective('<a ip-tooltip="disabled text" tooltip-placement="right" ng-disabled="true">Disabled a</a>');
            var wrapperElement = element.parent();
            expect(wrapperElement).toBeDefined();
            expect(wrapperElement.attr('uib-tooltip')).toBe('disabled text');
            expect(wrapperElement.prop('tagName')).toBe('DIV');
            expect(wrapperElement.attr('data-tooltip-placement')).toBe('right');
            expect(wrapperElement.attr('class')).toMatch('disabled');
        });

        it('removes itself to avoid an infinite compile loop', function() {
            compileDirective();
            expect(element.attr('ip-tooltip')).not.toBeDefined();
        });

        it('removes itself when disabled and wrapped in an element', function() {
            compileDirective('<button class="tooltip-error" ip-tooltip="disabled text" disabled="disabled">Disabled button</button>');
            expect(element.attr('ip-tooltip')).not.toBeDefined();
        });

    });
});
