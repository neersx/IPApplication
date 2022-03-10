import { SelectedColumn } from '../presentation/search-presentation.model';
export class SearchResultsViewData {
    hasOffices: boolean;
    hasFileLocation: boolean;
    q: string;
    filter: any;
    queryKey: number;
    queryName: string;
    isExternal: boolean;
    searchQueryKey: boolean;
    rowKey?: string;
    clearSelection?: boolean;
    programs: Array<Program>;
    hasDueDatePresentation: boolean;
    selectedColumns?: Array<SelectedColumn>;
    queryContext: number;
    presentationType: string;
    globalProcessKey: number;
    backgroundProcessResultTitle: string;
    permissions: any;
    reportProviderInfo: any;
    xmlCriteriaExecuted?: string;
    billingWorksheetTimeout: number;
    exportLimit: number;
    entities?: Array<any>;
}

export enum SearchResultEntryPoint {
    QuickCaseSearch,
    ExecuteSavedSearch,
    SavedSearchBuilder,
    NewSearchBuilder
}

export type StateParams = {
    name: string;
    params: any;
};

export type Program = {
    id: string;
    name: string;
    isDefault: boolean;
};

export type CaseSearchPermissions = {
    canAccessDocumentsFromDms: Boolean;
    canUpdateEventsInBulk: Boolean;
    canMaintainCase: Boolean;
    canOpenWorkflowWizard: Boolean;
    canOpenDocketingWizard: Boolean;
    canMaintainFileTracking: Boolean;
    canOpenFirstToFile: Boolean;
    canOpenWipRecord: Boolean;
    canOpenCopyCase: Boolean;
    canRecordTime: Boolean;
    canOpenReminders: Boolean;
    canCreateAdHocDate: Boolean;
    canShowLinkforInprotechWeb: Boolean;
    canMaintainGlobalNameChange: Boolean;
    canViewCaseDataComparison: Boolean;
    canOpenWebLink: Boolean;
    canRequestCaseFile: Boolean;
    canPoliceInBulk: Boolean;
    canMaintainCaseList: Boolean;
    canUseTimeRecording: Boolean;
};

export type NameSearchPermissions = {
    canMaintainNameNotes: Boolean;
    canMaintainNameAttributes: Boolean;
    canMaintainName: Boolean;
    canMaintainOpportunity: Boolean;
    canMaintainAdHocDate: Boolean;
    canMaintainContactActivity: Boolean;
    canAccessDocumentsFromDms: Boolean;
};

export type PriorArtSearchPermissions = {
    canMaintainPriorArt: Boolean;
};

export type WipOverviewSearchPermissions = {
    canMaintainDebitNote: Boolean;
    canCreateBillingWorksheet: Boolean;
};

export type BillSearchPermissions = {
    canMaintainCreditNote: boolean;
    canMaintainDebitNote: boolean;
    canDeleteDebitNote: boolean;
    canDeleteCreditNote: boolean;
    canReverseBill: BillReversalType;
    canCreditBill: boolean;
};

export enum BillReversalType {
    ReversalAllowed = 'ReversalAllowed',
    ReversalNotAllowed = 'ReversalNotAllowed',
    CurrentPeriodReversalAllowed = 'CurrentPeriodReversalAllowed'
}