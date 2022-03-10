describe('inprotech.components.menu.savedSearchPanel', () => {
    'use strict';

    let controller: SavedSearchPanelController, savedSearchMenuService: any;

    beforeEach(() => {
        angular.mock.module('inprotech.components.menu');
        let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);
        savedSearchMenuService = $injector.get('SavedSearchMenuServiceMock');

    });

    beforeEach(function () {
        controller = new SavedSearchPanelController(savedSearchMenuService);
    });

    describe('isIconDisplayed', () => {
        it('should display icon when icon name is not null', () => {
            expect(controller.isIconDisplayed('icontName')).toBeTruthy();
        });

        it('should not display icon when icon name is null', () => {
            expect(controller.isIconDisplayed('null')).toBeFalsy();
        });
    });

    describe('getFilteredData', () => {
        it('should return matching menuitem', () => {
            controller.filter = 'US Patents';
            controller.getFilteredData();

            expect(controller.menuDetails.length).toEqual(1);
            expect(controller.menuDetails[0].text).toEqual('US Patents');
        });

        it('should return zero menuitem', () => {
            controller.filter = 'USA';
            controller.getFilteredData();

            expect(controller.menuDetails.length).toEqual(0);
        });
    });

    describe('refreshData', () => {
        it('Calling refreshData should have called getFilteredData', () => {
            spyOn(controller, 'getFilteredData');
            spyOn(controller, 'build');
            controller.filter = 'US';
            controller.refreshData(false);

            expect(controller.filter).toBe('');
            expect(controller.getFilteredData).toHaveBeenCalled();
            expect(controller.build).not.toHaveBeenCalled();
        });
    });

    describe('refreshData', () => {
        it('Calling refreshData should have called build', () => {
            spyOn(controller, 'getFilteredData');
            spyOn(controller, 'build');
            controller.refreshData(true);

            expect(controller.build).toHaveBeenCalled();
            expect(controller.getFilteredData).not.toHaveBeenCalled();
        });
    });
});
