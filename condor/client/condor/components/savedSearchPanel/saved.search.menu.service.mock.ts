
class SavedSearchMenuServiceMock {

    public returnValues: any; menuItemsOriginal: any;

    constructor() {
        this.returnValues = {};
        spyOn(this, 'build').and.callThrough();
    }


    fetch = (queryContextKey) => {
        return {
            then: (cb) => {
                let response = {
                    data: [
                        { 'text': 'US Patents' },
                        { 'text': 'AU Patents' },
                    ]
                };
                return cb(response);
            }
        };
    }

    build = (queryContextKey) => {
        return {
            then: (cb) => {
                return cb(cb.returnValues);
            }
        };
    }

    filterMenu = (filtertext) => {
        let data = [
            { 'text': 'US Patents', 'items': null },
            { 'text': 'AU Patents', 'items': null },
        ];
        return _.filter(data, (menuItem) => {
            return menuItem.text.toLowerCase().indexOf(filtertext.toLowerCase()) >= 0
                || _.some(menuItem.items, (item: any) => {
                    return item.text.toLowerCase().indexOf(filtertext.toLowerCase()) >= 0
                });
        });
    }
}
angular.module('inprotech.mocks.components.savedsearchpanel')
    .service('SavedSearchMenuServiceMock', SavedSearchMenuServiceMock);

