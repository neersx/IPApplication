'use strict';

interface IGridColumn {
    width?: String;
    fixed?: Boolean;
    title?: String;
    field?: String;
    template?: String;
    headerTemplate?: String;
    oneTimeBinding?: Boolean;
}

interface IMenuAction {
    id: String;
    enabled: Function;
    click: Function;
    maxSelection?: Number;
}

interface IHotKey {
    combo: string;
    description: string;
    callback: Function;
}

interface IValidationError {
    topic: string;
    field: string;
    message: string;
}

interface IModalOptions {
    id: string;
    viewData?: any;
    controllerAs: string;
    dataItem?: any;
    allItems?: Array<any>;
    callbackFn?: Function
}

interface IGridAttributes {
    id: any,
    inUse: boolean,
    selected: boolean,
    saved: boolean
}

interface IGridAttributes {
    id: any,
    inUse: boolean,
    selected: boolean,
    saved: boolean
}




