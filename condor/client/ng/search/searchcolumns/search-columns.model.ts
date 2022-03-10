
export class SearchCriteria {
    text?: string;
    queryContextKey?: Number;
}

export class FilterValue {
    internalContext?: number;
    externalContext?: number;
    displayForInternal?: Boolean;
}

export type QueryContextPermissions = {
    queryContextType: string,
    queryContext: number,
    canCreateSearchColumn?: Boolean,
    canUpdateSearchColumn?: Boolean,
    canDeleteSearchColumn?: Boolean,
    displayForInternal?: Boolean
};

export type QueryColumnViewData = {
    queryContextPermissions: Array<QueryContextPermissions>,
    queryContextKey: Number
};

export class Columns {
    dataItemID: number;
    contextID: number;
    displayName: string;
    columnNameDescription: string;
}

export class SearchColumnSaveDetails {
    columnId?: number;
    displayName?: string;
    columnName?: SearchColumnNamePayload;
    parameter?: string;
    docItem?: DataItem;
    description?: string;
    isMandatory = false;
    isVisible = true;
    dataFormat?: string;
    columnGroup?: QueryColumnGroupPayload;
    queryContextKey?: number;
}

export class SearchColumnNamePayload {
    key?: Number;
    description?: string;
    queryContext?: Number;
    isQualifierAvailable?: boolean;
    isUserDefined?: boolean;
    dataFormat?: string;
    isUsedBySystem?: boolean;
}

export class DataItem {
    key?: Number;
    code?: string;
    value?: string;
    itemType?: number;
}

export class QueryColumnGroupPayload {
    key?: Number;
    value?: string;
    contextId?: Number;
}

export enum SearchColumnState {
    Adding = 'adding',
    Updating = 'updating'
}

export enum ItemType {
    SqlStatement = 0,
    StoredProcedure = 1,
    StoredProcedureExternalDataSource = 3
}