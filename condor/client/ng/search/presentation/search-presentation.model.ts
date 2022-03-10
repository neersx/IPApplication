import { DueDateFormData } from 'search/case/due-date/due-date.model';

export type PresentationColumnView = {
    id: String;
    parentId: String;
    columnKey: Number;
    columnDescription: String;
    groupKey?: Number;
    groupDescription: String;
    displayName: string;
    isGroup: Boolean;
    displaySequence?: Number;
    sortOrder?: Number;
    sortDirection: String;
    groupBySortOrder?: Number;
    groupBySortDirection?: String;
    hidden: Boolean;
    freezeColumn: Boolean;
    isDefault: Boolean;
    procedureItemId: string;
    isFreezeColumnDisabled: boolean;
    isGroupBySortOrderDisabled: boolean;
    isMandatory?: boolean;
};

export enum SearchContextEnum {
    CaseSearchExternal = 1,
    CaseSearch = 2,
    NameSearch = 10,
    NameSearchExternal = 15,
    OpportunitySearch = 550,
    CampaignSearch = 560,
    MarketingEventSearch = 570,
    LeadSearch = 500,
    WIPOverviewSearch = 200,
    PriorAreSearch = 900,
    TaskPlannerSearch = 970
}

export type SavedPresentationQuery = {
    key: Number;
    name: string;
};

export type SelectedColumn = {
    columnKey: Number;
    displaySequence?: Number;
    sortOrder?: Number;
    sortDirection?: String;
    groupBySortOrder?: Number;
    groupBySortDirection?: String;
    isFreezeColumnIndex?: Boolean;
};

export type SearchPresentationViewData = {
    isExternal?: Boolean;
    isPublic?: Boolean;
    filter: any;
    queryKey: Number;
    q?: string,
    queryName: string;
    queryContextKey: Number;
    importanceOptions: any;
    canCreateSavedSearch?: Boolean,
    canUpdateSavedSearch?: Boolean,
    canMaintainPublicSearch?: Boolean,
    userHasDefaultPresentation?: Boolean,
    canDeleteSavedSearch?: Boolean
    canMaintainColumns?: Boolean;
};

export class SearchPresentationData {
    selectedColumns: Array<PresentationColumnView>;
    selectedColumnsData: Array<SelectedColumn>;
    availableColumnsStore: Array<PresentationColumnView>;
    availableColumnsForSearch: Array<PresentationColumnView>;
    originalAvailableColumns: Array<PresentationColumnView>;
    copyPresentationQuery: Number;
    useDefaultPresentation: Boolean;
    dueDateFormData: DueDateFormData;
}

export class DueDateValidator {
    hasDueDateColumn: Boolean;
    hasAllDateColumn: Boolean;
}
export interface ISearchPresentationData {
    [id: string]: SearchPresentationData;
}