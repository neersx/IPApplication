'use strict';

class MenuItemDetail {
    public url: string;
    public icon: string;
    public text: string;
    public type: string;
    public queryContextKey?: number;
    public description: string;
    public items: MenuItemDetail[]
}

class MenuService {
    static $inject = ['$http'];
    menuTemplate: any;
    constructor(private $http: ng.IHttpService) {
        this.menuTemplate = {
            text: null,
            encoded: false
        }
    }

    private fetch = (): ng.IPromise<MenuItemDetail[]> => {
        return this.$http.get('api/portal/menu'
        ).then(function (response) {
            return <MenuItemDetail[]>response.data;
        });
    }

    buildMenuItem = (item: MenuItemDetail, collapsable: boolean): any => {
        let result = angular.merge({}, this.menuTemplate, { text: this.getMenuText(item.icon, item.text, item.url || '', item.type, collapsable, item.description || '', item.queryContextKey || '') });
        if (item.items && item.items.length > 0) {
            result.items = []
            let context = this;
            _.each(item.items, function (i) {
                result.items.push(this.buildMenuItem(i))
            }, context);
        }

        return result;
    }

    private getMenuText = (icon: string, text: string, url: string, type: string, collapsable: boolean, description: string, queryContextKey: any): string => {
        let expanded = 'expanded="true"';
        if (collapsable) {
            expanded = 'expanded="vm.leftBarExpanded"';
        }
        return `<menu-item url="${url}" type="${type}" icon-name="${icon}" id="${text + '_' + queryContextKey}" text="${text}" query-context-key="${queryContextKey}" ${expanded} tooltip="${description}"></menu-item>`;
    }

    private getHomeMenu = (): any => {
        let homeUrl = '#/home';
        let menuText = `<menu-item url="${homeUrl}" icon-name="cpa-icon-home" text="Home" id="Home" expanded="vm.leftBarExpanded"></menu-item>`;
        return angular.merge({}, this.menuTemplate, { text: menuText });
    }

    build = (): ng.IPromise<any> => {
        let context = this;
        let result = [];
        return this.fetch().then(function (data) {
            result.push(context.getHomeMenu());
            _.each(data, function (item) {
                result.push(this.buildMenuItem(item, true));
            }, context);

            return result;
        });
    }
}

angular.module('inprotech.portal')
    .service('menuService', MenuService);
