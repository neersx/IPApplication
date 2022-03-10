import { SavedPresentationQuery, SelectedColumn } from '../presentation/search-presentation.model';
import { DueDateFormData } from './due-date/due-date.model';

export class DropDownData {
    key: string;
    value: string;
}

export class CaseSearchViewData {
    isExternal: boolean;
    queryContextKey: number;
    nameTypes: Array<DropDownData>;
    numberTypes: Array<DropDownData>;
    textTypes: Array<DropDownData>;
    importanceOptions: Array<DropDownData>;
    attributes: Array<DropDownData>;
    sentToCpaBatchNo: Array<string>;
    designElementTopicVisible: boolean;
    isPatentTermAdjustmentTopicVisible: boolean;
    allowMultipleCaseTypeSelection: boolean;
    showCeasedNames: boolean;
    showEventNoteType: boolean;
    showEventNoteSection: boolean;
    hasDueDatePresentationColumn: boolean;
    hasAllDatePresentationColumn: boolean;
    canCreateSavedSearch: boolean;
    canMaintainPublicSearch: boolean;
    canUpdateSavedSearch: boolean;
    userHasDefaultPresentation: boolean;
    canDeleteSavedSearch: boolean;
    entitySizes: Array<DropDownData>;
}

export class CaseSavedSearchData {
    queryKey: number;
    queryName: string;
    steps: any;
    dueDateFormData: DueDateFormData;
    isPublic?: Boolean;
    queryContext?: number;
}

export type CaseSearchData = {
    viewData: CaseSearchViewData;
    savedSearchData: CaseSavedSearchData;
};

export type CaseStateParams = {
    name: string;
    params: any;
};

export type Program = {
    id: string;
    name: string;
    isDefault: boolean;
};
