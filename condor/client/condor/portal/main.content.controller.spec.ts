describe('inprotech.portal.MainContentController', () => {
    'use strict';

    let controller: (dependencies?: any) => MainContentController,
        menuBuilder: MenuBuilder, menuService: MenuService, splitterBuilder: SplitterBuilder, storeObj: any;

    let q: any;
    let rootScope: ng.IRootScopeService

    beforeEach(() => {
        angular.mock.module('inprotech.portal');

        menuBuilder = jasmine.createSpyObj('MenuBuilder', ['BuildOptions']);
        menuService = jasmine.createSpyObj('MenuService', ['build']);
        splitterBuilder = jasmine.createSpyObj('SplitterBuilder', ['BuildOptions']);

        angular.mock.module(($provide) => {
            let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks', 'ng']);

            $provide.value('store', $injector.get('storeMock'));
            $provide.value('$q', $injector.get('$q'));
            $provide.value('$rootScope', $injector.get('$rootScope'));
            $provide.provider('appContext', $injector.get('appContextMock'));
        });
    });

    let c: MainContentController;
    beforeEach(inject(($q: ng.IQService, $rootScope: ng.IRootScopeService, appContext: any, store: any) => {
        controller = function (dependencies?) {
            dependencies = angular.extend({
                scope: $rootScope.$new()
            }, dependencies);
            return new MainContentController(dependencies.scope, splitterBuilder, menuBuilder, menuService, store, appContext);
        };

        storeObj = store;
        rootScope = $rootScope;
        q = $q;
    }));

    describe('on Init', function () {
        it('initializes by calling appropriate methods', () => {
            (menuService.build as jasmine.Spy).and.returnValue(q.when({}));
            (splitterBuilder.BuildOptions as jasmine.Spy).and.returnValue({});

            c = controller();
            expect(splitterBuilder.BuildOptions).toHaveBeenCalled();
            expect((splitterBuilder.BuildOptions as jasmine.Spy).calls.mostRecent().args[0]).toBe('mainContent');
            expect((splitterBuilder.BuildOptions as jasmine.Spy).calls.mostRecent().args[1].panes.length).toBe(3);
            expect(menuService.build).toHaveBeenCalled();
        });

        it('initialises menu with the data returned', () => {
            let menu = [{ someMenu: { menu1: 'SomeValue' } }];
            let builtMenu: MenuDetails = { id: 'a', options: null };
            (menuService.build as jasmine.Spy).and.callFake(function () { return q.when(menu); });
            (menuBuilder.BuildOptions as jasmine.Spy).and.returnValue(builtMenu);

            c = controller();
            rootScope.$apply();

            expect(menuService.build).toHaveBeenCalled();
            expect(menuBuilder.BuildOptions).toHaveBeenCalledWith('mainMenu', { dataSource: menu });
            expect(c.menuDetails).toEqual(builtMenu);
        });

        it('sets the state of left bar collapse/expand by reading it from store', () => {
            (menuService.build as jasmine.Spy).and.returnValue(q.when({}));

            c = controller();
            rootScope.$apply();

            expect(storeObj.local.default).toHaveBeenCalledWith('portal.leftbar.expanded', false);
            expect(storeObj.local.get).toHaveBeenCalledWith('portal.leftbar.expanded');

            expect(c.leftBarExpanded).toBe(false);
        });

        it('watches toggle state and applies the collapse/expand selection as required', () => {
            let splitterDetails: SplitterDetails = {
                id: 'a',
                options: null,
                resize: jasmine.createSpy('', () => { }),
                resizePanesHeight: jasmine.createSpy('', () => { }),
                resizePane: jasmine.createSpy('', () => { }),
                togglePane: jasmine.createSpy('', () => { })
            };

            (menuService.build as jasmine.Spy).and.returnValue(q.when({}));
            (splitterBuilder.BuildOptions as jasmine.Spy).and.returnValue(splitterDetails);

            c = controller();
            rootScope.$apply();

            c.leftBarExpanded = true;
            rootScope.$apply();

            expect(c.splitterDetails.resizePane).toHaveBeenCalledWith('leftBar', '160px');
            expect(storeObj.local.set).toHaveBeenCalledWith('portal.leftbar.expanded', true);

            c.leftBarExpanded = false;
            rootScope.$apply();

            expect(c.splitterDetails.resizePane).toHaveBeenCalledWith('leftBar', '40px');
            expect(storeObj.local.set).toHaveBeenCalledWith('portal.leftbar.expanded', false);
        });
    });
});
