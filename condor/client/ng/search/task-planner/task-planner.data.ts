import { SelectedColumn } from 'search/presentation/search-presentation.model';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';

export class TaskPlannerViewData {
    q: string;
    filter: any;
    isExternal: boolean;
    searchQueryKey?: boolean;
    rowKey?: string;
    presentationType?: string;
    selectedColumns?: Array<SelectedColumn>;
    queryContext: number;
    permissions: any;
    xmlCriteriaExecuted?: string;
    criteria: Criteria;
    query: QueryData;
    isPublic?: boolean;
    timePeriods: Array<TimePeriod>;
    maintainEventNotes: boolean;
    showReminderComments?: boolean;
    maintainReminderComments?: boolean;
    replaceEventNotes?: boolean;
    maintainEventNotesPermissions?: any;
    reminderDeleteButton: number;
    maintainTaskPlannerSearch: boolean;
    maintainTaskPlannerSearchPermission?: any;
    maintainPublicSearch?: boolean;
    canFinaliseAdhocDates?: boolean;
    resolveReasons?: Array<any>;
    exportLimit: number;
    canCreateAdhocDate?: boolean;
    autoRefreshGrid: boolean;
    canViewAttachments: boolean;
    canAddCaseAttachments: boolean;
    canMaintainAdhocDate?: boolean;
    canChangeDueDateResponsibility?: boolean;
    showLinksForInprotechWeb: boolean;
    provideDueDateInstructions: boolean;
}

export class TimePeriod {
    id: number;
    description: string;
    fromDate: Date;
    toDate: Date;
}
export class SavedSearchData {
    query: QueryData;
    criteria: Criteria;
}

export class QueryData {
    key?: number;
    searchName: string;
    presentationId?: number;
    description?: string;
    tabSequence: number;
    isPublic?: boolean;
}

export class DateRange {
    useDueDate: number;
    useReminderDate: number;
    sinceLastWorkingDay: number;
    operator: string;
    from?: Date;
    to?: Date;
}

export class Criteria {
    dateFilter: DateRange;
    belongsTo: BelongsTo;
    hasNameGroup: boolean;
    timePeriodId: number;
    importanceLevel: any;
}

export class BelongsTo {
    names: Array<any>;
    nameGroups: Array<any>;
}

export class TabData {
    queryKey: number;
    description: string;
    presentationId: number;
    sequence: number;
    filter?: any;
    dateRange?: DateRange;
    timePeriods?: any;
    savedSearch?: SavedSearchData;
    selectedPeriodId?: number;
    belongsTo?: BelongsTo;
    names?: any;
    nameGroups?: any;
    showFilterArea?: boolean;
    isPersisted?: boolean;
    showPreview?: boolean;
    queryParams?: GridQueryParameters;
    selectedColumns?: Array<any>;
    defaultTimePeriods?: Array<any>;
    builderFormData?: any;
    searchName?: string;
    results?: Array<any>;
    canRevert: boolean;
    dirtyQuickFilters?: Map<string, boolean>;
}
export enum TaskPlannerItemType {
    AdHocDate = 'A',
    ReminderOrDueDate = 'C'
}
export enum ReminderActionStatus {
    PartialCompletion = 'partialCompletion',
    UnableToComplete = 'unableToComplete',
    Success = 'success'
}
export class ReminderResult {
    status: ReminderActionStatus;
    messageTitle: string;
    message: string;
    unprocessedRowKeys: Array<string>;
}

export class ReminderEmailContent {
    subject: string;
    body: string;
}

export enum ReminderRequestType {
    InlineTask = 'inlineTask',
    BulkAction = 'bulkAction'
}

export class UserPreferenceViewData {
    maintainTaskPlannerSearch: boolean;
    defaultTabsData: Array<UserPreferenceTab>;
    preferenceData: TaskPlannerPreferenceModel;
}
export class TaskPlannerPreferenceModel {
    autoRefreshGrid: boolean;
    tabs: Array<UserPreferenceTab>;
}

export class UserPreferenceTab {
    isLocked: boolean;
    tabSequence: number;
    savedSearch: QueryData;
}

export enum MaintainActions {
    notes = 'N',
    comments = 'C',
    notesAndComments = 'NC'
}