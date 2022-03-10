namespace inprotech.components.savedSearchpanel {
    describe('inprotech.components.menu.savedSearchMenuService', () => {
        'use strict';

        let savedSearchMenuService: SavedSearchMenuService, httpMock: any;

        beforeEach(() => {
            angular.mock.module('inprotech.components.menu');
            let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);
            httpMock = $injector.get('httpMock');

        });

        beforeEach(function () {
            savedSearchMenuService = new SavedSearchMenuService(httpMock);
        });

        it('get should make backend call to fetch the record', () => {
            let response = {
                data: [
                    { 'text': 'US Patents' },
                    { 'text': 'AU Patents' },
                ]
            }
            httpMock.get.returnValue = {
                then: function (cb) {
                    return cb(response);
                }
            };
            savedSearchMenuService.build(1);
            expect(httpMock.get).toHaveBeenCalledWith('api/savedsearch/menu/1');
        });

        it('should return matching menuitem', () => {
            savedSearchMenuService.menuItemsOriginal = <SavedSearchMenuItemDetail[]>[
                { 'text': 'US Patents' },
                { 'text': 'AU Patents' },
            ]
            let menuItemsFiltered = savedSearchMenuService.filterMenu('US');

            expect(menuItemsFiltered.length).toEqual(1);
            expect(menuItemsFiltered[0].text).toEqual('US Patents');
        });

        it('should not return any menuitem', () => {
            let menuItemsFiltered = savedSearchMenuService.filterMenu('usa');
            expect(menuItemsFiltered.length).toEqual(0);
        });

        it('should return matching group search ', () => {
            savedSearchMenuService.menuItemsOriginal = <SavedSearchMenuItemDetail[]>[
                { 'text': 'US Patents' },
                { 'text': 'AU Patents' },
                {
                    'text': 'Group', 'items': [
                        { 'text': '1234 cases' }
                    ]
                }
            ]
            let menuItemsFiltered = savedSearchMenuService.filterMenu('1234');

            expect(menuItemsFiltered.length).toEqual(1);
            expect(menuItemsFiltered[0].text).toEqual('Group');
            expect(menuItemsFiltered[0].items.length).toEqual(1);
        });
    });
}
