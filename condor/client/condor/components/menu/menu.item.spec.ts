describe('inprotech.components.menu.menuItem', () => {
    'use strict';

    let controller: MenuItemController, $window: any, featureDetectionMock: any, modalService: any, state: any, notificationService: any, translate: any,
        uibModal: any, searchPresentationPersistenceServiceMock: any,
        serviceMock: any;

    beforeEach(() => {
        angular.mock.module('inprotech.components.menu');
        let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);
        featureDetectionMock = $injector.get('featureDetectionMock');
        modalService = $injector.get('modalServiceMock');
        searchPresentationPersistenceServiceMock = {
            clear: jasmine.createSpy('clear')
        };
        state = {
            go: jasmine.createSpy('go'),
            current: {
                name: 'casesearch',

            }
        };

        angular.mock.module(function ($provide) {
            $provide.value('$window', {
                location: {
                    href: ''
                },
                navigator: {
                    userAgent: 'internal'
                }
            });
        });
        angular.mock.module(() => {
            translate = $injector.get('translateMock');
            notificationService = $injector.get('notificationServiceMock');
            uibModal = $injector.get('uibModalMock');
            serviceMock = $injector.get('menuItemServiceMock');
        });

        jasmine.clock().uninstall();

        jasmine.clock().install();
    });

    beforeEach(inject(function (_$window_) {
        $window = _$window_;
        controller = new MenuItemController($window, featureDetectionMock, modalService, state, notificationService, translate, uibModal, serviceMock, searchPresentationPersistenceServiceMock);
    }));

    afterEach(() => {
        jasmine.clock().uninstall();
    });

    it('should display icon when icon name is not null', () => {
        controller.iconName = 'iconname';
        expect(controller.isIconDisplayed()).toBeTruthy();
    });

    it('should not display icon when icon name is not null', () => {
        controller.iconName = 'null';
        expect(controller.isIconDisplayed()).toBeFalsy();
    });

    it('should not display icon when icon name is not null', () => {
        controller.iconName = 'null';
        expect(controller.isIconDisplayed()).toBeFalsy();
    });

    describe('when menu is clicked', function () {
        it('if the type is new tab it sets the target', () => {
            controller.type = 'newtab';
            state.current.url = 'case/search';
            let url = '#/accounting/time';
            controller.loadUrl(url, '', null);
            spyOn(controller, 'doSavedSearch');
            expect(controller.doSavedSearch).not.toHaveBeenCalled();
            expect(controller.target).toBe('');

        });
        it('if the type is new tab but is in the same route it leaves target blank', () => {
            let url = '#/accounting/time';
            controller.type = 'newtab';
            state.current.url = url;

            controller.loadUrl(url, '', null);
            expect(controller.target).toBe('');
        });
        it('if the saved search cannot be edited, it should call doSavedSearch', () => {
            let url = '#/accounting/time';
            controller.canEdit = false;
            state.current.url = url;
            spyOn(controller, 'doSavedSearch');
            controller.loadUrl(url, '1', null);
            expect(controller.doSavedSearch).toHaveBeenCalled();
        });
        it('when queryKey is provided it should called showSavedSearchMenu', () => {
            spyOn(controller, 'showSavedSearchMenu');
            controller.loadUrl('', '1', null);
            jasmine.clock().tick(500);
            expect(controller.togglePopOver).toBeFalsy();
        });
    });
    describe('when edit menu is clicked', function () {
        it('it should called showSavedSearchMenu', () => {
            spyOn(controller, 'showSavedSearchMenu');
            controller.queryContextKey = 1;
            controller.canEdit = true;
            controller.editSearch('1', null);
            jasmine.clock().tick(500);
            expect(controller.editTogglePopOver).toBeFalsy();
            expect(controller.showSavedSearchMenu).toHaveBeenCalled();
        });
        it('it should change state to case search', () => {
            controller.queryContextKey = 1;
            controller.canEdit = true;
            spyOn(controller, 'showSavedSearchMenu');
            controller.editSearch('1', null);
            expect(state.go).toHaveBeenCalled();
            expect(state.go.calls.mostRecent().args[0]).toEqual('casesearch');
        });
        it('it should call notificationService.alert when can edit is false', () => {
            controller.queryContextKey = 1;
            controller.canEdit = false;
            controller.editSearch('1', null);
            jasmine.clock().tick(500);
            expect(controller.editTogglePopOver).toBeFalsy();
            expect(controller.notificationService.alert).toHaveBeenCalled();
        });
    });
});