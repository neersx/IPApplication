'use strict';

class MenuDetails {
    id: string;
    options: kendo.ui.MenuOptions;
    constructor(id: string, options: kendo.ui.MenuOptions) {
        this.id = id;
        this.options = options;
    }
}

interface IMenuBuilder {
    BuildOptions(id: string, options: kendo.ui.MenuOptions): SplitterDetails;
}

class MenuBuilder implements IMenuBuilder {
    defaultOptions: kendo.ui.MenuOptions;

    constructor() {
        this.defaultOptions = {
            orientation: 'vertical',
            openOnClick: {
                rootMenuItems: true,
                subMenuItems: true
            }
        }
    }

    public BuildOptions = (id: string, options: kendo.ui.MenuOptions): any => {
        let result = new MenuDetails(id, angular.merge({}, options, this.defaultOptions));
        return result;
    }
}

angular.module('inprotech.components.menu')
    .service('menuBuilder', () => new MenuBuilder());
