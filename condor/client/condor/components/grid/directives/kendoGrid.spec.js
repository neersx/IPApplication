describe('inprotech.components.grid.directives.ipKendoGrid', function() {
    'use strict';

    var scope, directive, compileDirective, isolateScope, keyboardShortcutMock, elementTriggerSpy, busMock;
    beforeEach(function() {
        module('inprotech.components.grid');
        module('condor/components/grid/directives/kendoSearchGrid.html');
        module('condor/components/grid/directives/kendoNormalGrid.html');
        module(function($provide) {
            keyboardShortcutMock = {
                bindShortcuts: jasmine.createSpy()
            };
            elementTriggerSpy = jasmine.createSpy();

            // hook into bindShortcuts call to override the directive's element.trigger method
            keyboardShortcutMock.bindShortcuts.and.callFake(function(id, element) {
                element.trigger = elementTriggerSpy;
            });

            var $injector = angular.injector(['inprotech.mocks']);
            busMock = $injector.get('BusMock');
            $provide.value('bus', busMock);

            $provide.value('ipKendoGridKeyboardShortcuts', keyboardShortcutMock);
        });

        inject(function($compile, $rootScope) {
            scope = $rootScope.$new();

            compileDirective = function(directiveMarkup) {
                var defaultMarkup = '<ip-kendo-grid data-id="normalResults" data-grid-options="vm.gridOptions" data-search-hint="foo"></ip-kendo-grid>';
                scope.vm = {
                    gridOptions: {
                        id: 'normalResults'
                    }
                };
                directive = $compile(directiveMarkup || defaultMarkup)(scope);
                scope.$digest();
                isolateScope = directive.isolateScope();
            };
        });
    });

    describe('build search grid', function() {
        beforeEach(function() {
            compileDirective('<ip-kendo-grid data-id="searchResults" data-grid-options="vm.gridOptions" data-search-hint="foo" mode="search"></ip-kendo-grid>');
        });

        it('initialises correct values', function() {
            expect(isolateScope.id).toBe('searchResults');
            expect(isolateScope.searchHint).toBe('foo');
            expect(isolateScope.hideSearchHint).toBe(false);
            expect(isolateScope.hideNoResults).toBe(true);
            expect(scope.vm.gridOptions.hidePagerWhenNoResults).toBe(true);
            expect(scope.vm.gridOptions.onDataBound).toBeDefined();
        });

        it('subscribes to bus broadcast to itself', function() {
            expect(busMock.singleSubscribe).toHaveBeenCalledWith('grid.' + isolateScope.id, jasmine.any(Function));
            expect(busMock.singleSubscribe).toHaveBeenCalledWith('gridRefresh.' + isolateScope.id, jasmine.any(Function));
        })

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

    describe('build normal grid', function() {
        it('initialises correct values', function() {
            compileDirective();
            expect(isolateScope.id).toBe('normalResults');
            expect(isolateScope.hideNoResults).toBe(true);
            expect(isolateScope.addLabelParams.itemName).toBe('grid.messages.defaultItemName');
            expect(scope.vm.gridOptions.hidePagerWhenNoResults).toBe(true);
            expect(scope.vm.gridOptions.onDataBound).toBeDefined();
        });

        it('shows no results message', function() {
            compileDirective();
            scope.vm.gridOptions.onDataBound([], true);

            expect(isolateScope.hideNoResults).toBe(false);
        });

        it('initialises add label params', function() {
            compileDirective('<ip-kendo-grid data-grid-options="vm.gridOptions" add-item-name="instructor"></ip-kendo-grid>');

            expect(isolateScope.addLabelParams.itemName).toBe('instructor');
        });
    });

    describe('grid focus', function() {
        beforeEach(function() {
            compileDirective('<ip-kendo-grid data-id="searchResults" data-grid-options="vm.gridOptions" data-search-hint="foo" mode="search"></ip-kendo-grid>');
            scope.vm.gridOptions.navigatable = true;
            scope.vm.gridOptions.selectable = true;
        });
    });
});