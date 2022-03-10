'use strict';

class SavedSearchMenuItemDetail {
    public key: string;
    public url: string;
    public icon: string;
    public text: string;
    public type: string;
    public description: string;
    public items: MenuItemDetail[];
    public showItems: boolean;
    public canEdit: boolean;
}

class SavedSearchMenuService {
    static $inject = ['$http'];
    public menuItemsOriginal: SavedSearchMenuItemDetail[];
    constructor(private $http: ng.IHttpService) {
        this.menuItemsOriginal = new Array<SavedSearchMenuItemDetail>();
    }

    private fetch = (queryContextKey: number): ng.IPromise<SavedSearchMenuItemDetail[]> => {
        return this.$http.get('api/savedsearch/menu/' + queryContextKey
        ).then(function (response) {
            return <SavedSearchMenuItemDetail[]>response.data;
        });
    }

    build = (queryContextKey: number): ng.IPromise<any> => {
        let context = this;
        return this.fetch(queryContextKey).then(function (data) {
            context.menuItemsOriginal = data;
            return data;
        });
    }

    filterMenu = (search: string): any => {
        let context = this;
        let menuItemsFiltered = new Array<SavedSearchMenuItemDetail>();
        angular.copy(context.menuItemsOriginal, menuItemsFiltered);
        if (search && search.length > 0) {
            menuItemsFiltered = _.filter(menuItemsFiltered, function (menuItem) {
                return menuItem.text.toLowerCase().indexOf(search.toLowerCase()) >= 0
                    || _.some(menuItem.items, function (item) {
                        return item.text.toLowerCase().indexOf(search.toLowerCase()) >= 0
                    });
            }, context);

            _.each(menuItemsFiltered, function (menuItem) {
                if (menuItem.items) {
                    let items = _.filter(menuItem.items, function (item) {
                        return item.text.toLowerCase().indexOf(search.toLowerCase()) >= 0;
                    });
                    if (items.length > 0) {
                        menuItem.items = items;
                        menuItem.showItems = true;
                    }
                }
            });
        }
        return menuItemsFiltered;
    }
}

angular.module('inprotech.components.menu')
    .service('savedSearchMenuService', SavedSearchMenuService);
