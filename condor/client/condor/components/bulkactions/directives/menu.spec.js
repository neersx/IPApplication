describe('Service inprotech.components.bulkactions.bulkActionsMenu', function() {
    'use strict';

    beforeEach(module('inprotech.components'));

    beforeEach(module('condor/components/bulkactions/directives/menu.html'));
    beforeEach(module('condor/components/bulkactions/directives/standardmenu.html'));

    var scope, compile, directive, compileDirective, isolateScope, bus, commonActions;

    beforeEach(module(function($provide) {
        var $injector = angular.injector(['inprotech.mocks']);
        $provide.value('translateFilter', $injector.get('TranslationFilterMock'));

        bus = $injector.get('BusMock');
        commonActions = $injector.get('CommonActionsMock');

        $provide.value('bus', bus);
        $provide.value('commonActions', commonActions);
    }));

    beforeEach(inject(function($rootScope, $compile) {
        scope = $rootScope.$new();
        compile = $compile;

        scope.actions = [];
        scope.invokeOnUpdate = jasmine.createSpy();
        scope.invokeOnSelectAll = jasmine.createSpy();
        scope.invokeOnClear = jasmine.createSpy();

        compileDirective = function(directiveMarkup) {

            var defaultMarkup = '<div data-bulk-actions-menu actions="actions" data-context="the-context"';
            defaultMarkup += ' data-on-clear="invokeOnClear();" data-on-select-all="invokeOnSelectAll();" data-on-update-values="invokeOnUpdate();">';
            directive = compile(directiveMarkup || defaultMarkup)(scope);
            scope.$digest();
            isolateScope = directive.isolateScope();
        };
    }));

    it('should set up the directive', function() {
        compileDirective();

        expect(isolateScope.selectionOptions).toBeDefined();
        expect(isolateScope.items).toBeDefined();
        expect(isolateScope.paging).toBeDefined();
        expect(isolateScope.currentMode).toBeDefined();
        expect(isolateScope.isManualSelection).toBeDefined();
        expect(isolateScope.isAllSelected).toBeDefined();
        expect(isolateScope.isPageSelected).toBeDefined();
        expect(isolateScope.doClear).toBeDefined();
        expect(isolateScope.isClearDisabled).toBeDefined();
        expect(isolateScope.doSelectAll).toBeDefined();
        expect(isolateScope.doSelectThisPage).toBeDefined();
        expect(isolateScope.doUpdateValues).toBeDefined();
        expect(isolateScope.actionItems).toBeDefined();
    });

    describe('when no actions or items are available', function() {
        it('should not have a menu', function() {
            compileDirective();

            expect(isolateScope.items.totalCount).toEqual(0);
            expect(isolateScope.items.currentCount).toEqual(0);
            expect(isolateScope.items.selected).toEqual(0);
            expect(isolateScope.paging.size).toEqual(0);
            expect(isolateScope.paging.available).toEqual(false);
            expect(isolateScope.currentMode).toEqual('none');

            expect($(directive).find('div.group-heading').length).toBe(0);
        });

        it('should initially not have an option set', function() {
            compileDirective();
            expect(isolateScope.currentMode).toEqual('none');
        });

        it('should prevent menu from being accessed', function() {
            compileDirective();

            expect($(directive).find('button.dd-link').is(':disabled')).toBe(true);
        });
    });

    describe('at any given time', function() {
        it('should display badge, if the selection was user initiated', function() {
            compileDirective();

            isolateScope.currentMode = 'manual';
            expect(isolateScope.isManualSelection()).toEqual(true);
        });

        it('should not display badge, if nothing is selected', function() {
            compileDirective();

            expect(isolateScope.isManualSelection()).toEqual(false);
        });

        it('should not display badge, if the selection was "all"', function() {
            compileDirective();
            isolateScope.doSelectAll();

            expect(isolateScope.isManualSelection()).toEqual(false);
        });

        it('should display badge, if page selection made', function() {
            compileDirective();

            isolateScope.currentMode = 'page';
            expect(isolateScope.isManualSelection()).toEqual(true);
        });
    });

    describe('when "clear" is selected', function() {
        it('should call "on-clear"', function() {

            compileDirective();

            isolateScope.items.totalCount = 5;
            isolateScope.items.selected = 4;
            isolateScope.currentMode = 'manual';

            isolateScope.doClear();

            expect(isolateScope.items.totalCount).toEqual(5);
            expect(isolateScope.items.selected).toEqual(0);

            expect(scope.invokeOnClear).toHaveBeenCalled();
        });
    });

    describe('when "select all" is selected', function() {
        it('should call "on-select-all"', function() {

            compileDirective();

            isolateScope.items.totalCount = 5;
            isolateScope.items.selected = 2;

            isolateScope.doSelectAll();
            expect(isolateScope.currentMode).toEqual('all');
        });
    });

    describe('when "select page" is selected', function() {
        it('should call "on-select-this-page"', function() {

            compileDirective();

            isolateScope.paging = {
                available: true,
                sizr: 3
            };

            isolateScope.items.totalCount = 5;
            isolateScope.items.currentCount = 2;
            isolateScope.items.selected = 0;

            isolateScope.doSelectThisPage();

            expect(isolateScope.currentMode).toEqual('page');
        });
    });

    describe('mode check functions', function() {
        it('isAllSelected returns true, if selection mode is all', function() {
            compileDirective();

            isolateScope.currentMode = 'all';
            expect(isolateScope.isAllSelected()).toBe(true);
        });

        it('isAllSelected returns false, if selection mode is not all', function() {
            compileDirective();

            isolateScope.currentMode = 'other';
            expect(isolateScope.isAllSelected()).toBe(false);
        });

        it('isPageSelected returns true, if selection mode is page', function() {
            compileDirective();

            isolateScope.currentMode = 'page';
            expect(isolateScope.isPageSelected()).toBe(true);
        });

        it('isPageSelected returns false, if selection mode is not page', function() {
            compileDirective();

            isolateScope.currentMode = 'other';
            expect(isolateScope.isPageSelected()).toBe(false);
        });
    });

    describe('functon isClearDisabled', function() {
        it('returns false, if selected items', function() {
            compileDirective();

            isolateScope.items.selected = 10;
            expect(isolateScope.isClearDisabled()).toBe(false);
        });

        it('returns false, if selected mode is all', function() {
            compileDirective();

            isolateScope.currentMode = 'all';
            expect(isolateScope.isClearDisabled()).toBe(false);
        });

        it('returns true, if nothing selected', function() {
            compileDirective();

            isolateScope.items.selected = 0;
            expect(isolateScope.isClearDisabled()).toBe(true);
        });
    });

    describe('when actions are available', function() {

        beforeEach(function() {
            scope.actions = [{
                id: 'some'
            }];
        });

        it('should build action item from actions', function() {

            var myclick = function() {};
            scope.actions = [{
                id: 'some',
                click: myclick
            }];

            compileDirective();

            isolateScope.items.totalCount = 5;
            isolateScope.items.selected = 1;

            expect(isolateScope.actionItems.length).toBe(1);
            expect(isolateScope.actionItems[0].id).toBe('some');
            expect(isolateScope.actionItems[0].shouldDisable).toBeDefined();
            expect(isolateScope.actionItems[0].invokeIfEnabled).toBeDefined();
            expect(isolateScope.actionItems[0].click).toBe(myclick);
        });

        it('should invoke action item if it is not disabled', function() {

            var click = jasmine.createSpy();

            scope.actions = [{
                id: 'some',
                click: click,
                maxSelection: 1
            }];

            compileDirective();

            isolateScope.items.totalCount = 5;
            isolateScope.items.selected = 1;

            isolateScope.actionItems[0].invokeIfEnabled();

            expect(click).toHaveBeenCalled();
        });

        it('should not invoke action item only when it is disabled', function() {

            var click = jasmine.createSpy();

            scope.actions = [{
                id: 'some',
                click: click,
                maxSelection: 1
            }];

            compileDirective();

            isolateScope.items.totalCount = 5;
            isolateScope.items.selected = 2;

            isolateScope.actionItems[0].invokeIfEnabled();

            expect(click).not.toHaveBeenCalled();
        });

        it('should not invoke action item only when it is disabled', function() {

            var click = jasmine.createSpy();

            scope.actions = [{
                id: 'some',
                enabled: function() {
                    return false;
                },
                click: click,
                maxSelection: 1
            }];

            compileDirective();

            isolateScope.items.totalCount = 5;
            isolateScope.items.selected = 1;

            isolateScope.actionItems[0].invokeIfEnabled();

            expect(click).not.toHaveBeenCalled();
        });

        it('should call "on-update-values" following the action', function() {

            var click = jasmine.createSpy();

            scope.actions = [{
                id: 'some',
                click: click
            }];

            compileDirective();

            isolateScope.items.totalCount = 5;
            isolateScope.items.selected = 1;

            isolateScope.actionItems[0].invokeIfEnabled();

            expect(click).toHaveBeenCalled();
            expect(scope.invokeOnUpdate).toHaveBeenCalled();
        });
    });

    describe('is empty list method', function() {
        it('should return true when there are no items', function() {
            compileDirective();
            isolateScope.items.totalCount = 0;
            expect(isolateScope.isEmptyList()).toBe(true);
        });

        it('should return false when there are items', function() {
            compileDirective();
            isolateScope.items.totalCount = 1;
            expect(isolateScope.isEmptyList()).toBe(false);
        });
    });

    describe('menu triggers', function() {
        beforeEach(function() {
            scope.actions = [{
                id: 'some',
                click: jasmine.createSpy()
            }];
        });

        it('should set menu active and focus on click', function() {
            compileDirective();
            isolateScope.items.totalCount = 1;

           // var focusSpy = spyOn($.fn, 'focus');
            $.fx.off = true; // required to execute fadeToggle callback immediately

            directive.trigger('click');

            expect(directive.find('.dd-link').first().hasClass('active')).toBe(true);
           // expect(focusSpy).toHaveBeenCalled();
        });

        it('should set menu not active on focus out', function() {
            compileDirective();
            isolateScope.items.totalCount = 1;
            
            directive.find('.dd-link').first().addClass('active')
            directive.find('.dd-dropdown').trigger('focusout');

            expect(directive.find('.dd-link').first().hasClass('active')).toBe(false);
        });
    });
});
