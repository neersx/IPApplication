export class SearchBuilderViewData {
    queryKey: number;
    importanceLevels: Array<any>;
    numberTypes: Array<any>;
    nameTypes: Array<any>;
    showCeasedNames: boolean;
    formData?: any;
}

export class SavedTaskPlannerData {
    queryKey: number;
    queryName: string;
    formData: any;
    isPublic?: Boolean;
}

export class GeneralSearchBuilder {
    includeFilter: IncludeFilterData;
    searchByFilter: SearchByFilterData;
    dateFilter: DateFilterData;
    importanceLevel: ImportanceLevelData;
    belongingToFilter: BelongingToData;
}

export class IncludeFilterData {
    reminders: boolean;
    dueDates: boolean;
    adHocDates: boolean;
}

export class SearchByFilterData {
    reminderDate: boolean;
    dueDate: boolean;
}

export class DateFilterData {
    dateFilterType: DateFilterType;
    operator: string;
    dateRange?: DateRangeFilterData;
    datePeriod?: DatePeriodFilterData;
}

export class ImportanceLevelData {
    operator: string;
    from: number;
    to: number;
}

export class BelongingToData {
    value: string;
    names: Array<any>;
    nameGroups: Array<any>;
    actingAs: ActingAsData;
}
export class ActingAsData {
    isReminder: boolean;
    isDueDate: boolean;
    nameTypes: Array<any>;
}

export class DateRangeFilterData {
    from: Date;
    to: Date;
}

export class DatePeriodFilterData {
    from: number;
    to: number;
    periodType: any;
}

export enum DateFilterType {
    range = 0,
    period = 1
}
export class CasesCriteriaSearchBuilder {
    caseReference: CriteriaFilterData;
    officialNumber: CriteriaFilterData;
    caseFamily: CriteriaFilterData;
    caseList: CriteriaFilterData;
    caseOffice: CriteriaFilterData;
    caseType: CriteriaFilterData;
    jurisdiction: CriteriaFilterData;
    propertyType: CriteriaFilterData;
    caseCategory: CriteriaFilterData;
    subType: CriteriaFilterData;
    basis: CriteriaFilterData;
    instructor: CriteriaFilterData;
    owner: CriteriaFilterData;
    otherNameTypes: CriteriaFilterData;
    caseStatus: CriteriaFilterData;
    renewalStatus: CriteriaFilterData;
    isPending: Boolean;
    isRegistered: boolean;
    isDead: boolean;
}

export class EventsActionsSearchBuilder {
    event: CriteriaFilterData;
    eventCategory: CriteriaFilterData;
    eventGroup: CriteriaFilterData;
    eventNoteType: CriteriaFilterData;
    eventNotes: CriteriaFilterData;
    action: CriteriaFilterData;
    isRenewals: Boolean;
    isNonRenewals: boolean;
    isClosed: boolean;
}

export class RemindersSearchBuilder {
    reminderMessage: CriteriaFilterData;
    isOnHold: boolean;
    isNotOnHold: Boolean;
    isRead: boolean;
    isNotRead: boolean;
}

export class AdhocDateSearchBuilder {
    names: CriteriaFilterData;
    generalRef: CriteriaFilterData;
    message: CriteriaFilterData;
    emailSubject: CriteriaFilterData;
    includeCase: boolean;
    includeName: boolean;
    includeGeneral: boolean;
    includeFinalizedAdHocDates: boolean;
}

export class CriteriaFilterData {
    operator: string;
    value?: any;
    type?: string;
}

export enum OperatorCombinations {
    Full = 'Full',
    FullSoundsLike = 'FullSoundsLike',
    FullNoExist = 'FullNoExist',
    Equal = 'Equal',
    Between = 'Between',
    BetweenWithLastWorkDay = 'BetweenWithLastWorkDay',
    EqualExist = 'EqualExist',
    StartEndExist = 'StartEndExist',
    DatesFull = 'DatesFull'
}
