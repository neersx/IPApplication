import { TemplateRef } from '@angular/core';
import { MenuEvent, MenuItem } from '@progress/kendo-angular-menu';
import { FilterDescriptor } from '@progress/kendo-data-query';
import { LocalSetting } from 'core/local-settings';

export type GridColumnDefinition = {
    title: string;
    iconName?: string;
    field: string;
    key?: boolean;
    width?: number;
    sortable?: boolean | { allowUnsort: boolean };
    disabled?: boolean;
    editor?: string;
    /**
     * If set to true, then child content must be supplied for the template
     * @example
     * <ng-template ipxTemplateColumnField="Name of the field" let-dataItem>
     * <span> {{ dataItem.field }} </span>
     * </ng-template>
     */
    defaultColumnTemplate?: DefaultColumnTemplateType;
    template?: boolean | TemplateRef<any>;
    headerTooltip?: string;
    customizeHeaderTemplate?: boolean | TemplateRef<any>;

    footer?: TemplateRef<any>;
    templateExternalContext?: { [propName: string]: any };
    /**
     * Internal Property.
     * Should not be set directly
     * @private Do Not Set
     */
    _templateResolved?: TemplateRef<any>;
    _editTemplateResolved?: TemplateRef<any>;
    /**
     * Include this column in the column chooser
     * @default true
     */
    includeInChooser?: boolean;
    filter?: boolean | 'date' | 'numeric' | 'text' | 'boolean';
    defaultFilters?: Array<string> | Array<number>;
    locked?: boolean;
    hidden?: boolean;
    headerClass?: string;
    hideByDefault?: boolean;
    menu?: boolean;
    displayOrder?: '';
    description?: '';
    preventCopy?: boolean;
    fixed?: boolean;
    cellEditable?(dataItem, formgroup): boolean;
    type?: string | 'date' | 'time'
};

export type GridQueryParameters = {
    skip: number;
    take: number;
    sortBy?: string;
    sortDir?: string;
    filters?: Array<FilterDescriptor>;
    filterEmpty?: boolean;
};

export type GridPagableData = {
    data: Array<any>;
    pagination: { total: number };
};

export interface MaintenanceMetaData {
    maintainability: Maintainability;
    maintainabilityActions: MaintainabilityActions;
}

export interface Maintainability {
    canAdd: boolean;
    canDelete: boolean;
    canEdit: boolean;
}

export interface MaintainabilityActions {
    allowAdd: boolean;
    allowDelete: boolean;
    allowDuplicate: boolean;
    allowEdit: boolean;
    allowView: boolean;
    action: string;
}

export type PageSettings = {
    /**
     * If Local setting is provided in "pageSizeSetting", then this value will be owerwritten by local storage on grid initialization
     */
    pageSize?: number;
    pageSizes?: Array<number>;
    /**
     * Grid can use this setting to automatically get and store the page size
     */
    pageSizeSetting?: LocalSetting;
};

export type ColumnSelection = {
    localSetting?: LocalSetting;
    localSettingSuffix?: string;
};

export enum DefaultColumnTemplateType {
    none,
    selection = 'selection',
    image = 'image',
    icon = 'icon',
    codeDescription = 'codeDescription',
    protected = 'protected',
    date = 'date',
    textarea = 'textarea',
    number = 'number'
}

export enum BulkActionEventType {
    ClearSelection,
    SelectAllPage,
    DeSelectAllPage
}

export enum NavigationActions {
    PrevRow,
    NextRow,
    FirstPage,
    LastPage,
    PrevPage,
    NextPage
}

export type ColumnSettings = {
    field: string;
    title?: string;
    orderIndex?: number;
};

export interface MenuDataItemEventData {
    event: MenuEvent;
    dataItem: any;
}

export class TaskMenuItem implements MenuItem {
    isSeparator?: boolean;
    id: string;
    text?: string;
    icon?: string;
    action?: any;
    disabled?: boolean;
}

export type GridMessages = {
    noResultsFound?: string;
    performSearch?: string;
};

export class RowState {
    constructor(readonly isExpanded?: boolean, readonly isInEditMode?: boolean) { }
}

export class EnterPressedEvent {
    constructor(readonly dataItem: any, readonly rowState: RowState, readonly colIndex: number) {
    }
}

export class Sort {
    sortBy: string;
    sortDir: string;
}