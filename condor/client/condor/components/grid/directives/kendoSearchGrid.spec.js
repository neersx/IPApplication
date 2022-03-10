describe('inprotech.components.grid.directives.kendoSearchGrid', function() {
    'use strict';

    var scope, directive, isolateScope, keyboardShortcutMock, elementTriggerSpy;
    beforeEach(function() {
        module('inprotech.components.grid');
        module('condor/components/grid/directives/kendoSearchGrid.html');
        module(function($provide) {
            keyboardShortcutMock = {
                bindShortcuts: jasmine.createSpy()
            };
            elementTriggerSpy = jasmine.createSpy();
            // hook into bindShortcuts call to override the directive's element.trigger method
            keyboardShortcutMock.bindShortcuts.and.callFake(function(id, element) {
                element.trigger = elementTriggerSpy;
            });
            $provide.value('ipKendoGridKeyboardShortcuts', keyboardShortcutMock);
        });

        inject(function($compile, $rootScope) {
            scope = $rootScope.$new();

            var defaultMarkup = '<ip-kendo-search-grid data-id="searchResults" data-grid-options="vm.gridOptions" data-search-hint="foo"></ip-kendo-search-grid>';
            scope.vm = {
                gridOptions: {
                    id: 'searchResults'
                }
            };
            directive = $compile(defaultMarkup)(scope);
            scope.$digest();
            isolateScope = directive.isolateScope();

        });
    });

    describe('build search grid', function() {
        it('initialises correct values', function() {
            expect(isolateScope.id).toBe('searchResults');
            expect(isolateScope.searchHint).toBe('foo');
            expect(isolateScope.hideSearchHint).toBe(false);
            expect(isolateScope.hideNoResults).toBe(true);
            expect(scope.vm.gridOptions.hidePagerWhenNoResults).toBe(true);
            expect(scope.vm.gridOptions.onDataBound).toBeDefined();
        });

        it('shows no results message', function() {
            scope.vm.gridOptions.onDataBound([], true);

            expect(isolateScope.hideNoResults).toBe(false);
            expect(isolateScope.hideSearchHint).toBe(true);
        });

        it('shows search hint on reset', function() {
            scope.vm.gridOptions.onDataBound([], false);

            expect(isolateScope.hideNoResults).toBe(true);
            expect(isolateScope.hideSearchHint).toBe(false);
        });

        it('hides both messages when results', function() {
            scope.vm.gridOptions.onDataBound([1], true);

            expect(isolateScope.hideNoResults).toBe(true);
            expect(isolateScope.hideSearchHint).toBe(true);
        });
    });
    describe('grid focus', function() {
        beforeEach(function() {
            scope.vm.gridOptions.navigatable = true;
            scope.vm.gridOptions.selectable = true;
        });
    });
});