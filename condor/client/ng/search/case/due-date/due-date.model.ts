import { TypeaheadStringFilter } from '../../common/search-helper.service';
import { SearchOperator } from '../../common/search-operators';

export enum PeriodTypes {
    days = 'D',
    weeks = 'W',
    months = 'M',
    years = 'Y'
}

export type DueDateFormData = {
    event?: Boolean;
    adhoc?: Boolean;
    searchByRemindDate?: Boolean;
    isRange?: Boolean;
    isPeriod?: Boolean;
    rangeType?: Number;
    searchByDate?: Boolean;
    dueDatesOperator?: SearchOperator;
    periodType?: PeriodTypes;
    fromPeriod?: Number;
    toPeriod?: Number;
    startDate?: Date;
    endDate?: Date;
    importanceLevelOperator?: SearchOperator;
    importanceLevelFrom?: string;
    importanceLevelTo?: string;
    eventOperator?: SearchOperator;
    eventValue?: any;
    eventCategoryOperator?: SearchOperator;
    eventCategoryValue?: any;
    actionOperator?: SearchOperator;
    actionValue?: any;
    isRenevals?: Boolean;
    isNonRenevals?: Boolean;
    isClosedActions?: Boolean;
    isAnyName?: Boolean;
    isStaff?: Boolean;
    isSignatory?: Boolean;
    nameTypeOperator?: SearchOperator;
    nameTypeValue?: any;
    nameOperator?: SearchOperator;
    nameValue?: any;
    nameGroupOperator?: SearchOperator;
    nameGroupValue?: any;
    staffClassificationOperator?: SearchOperator;
    staffClassificationValue?: any;
};

export type DueDate = {
    dates?: { useDueDate?: Number, useReminderDate?: Number, dateRange?: { operator?: SearchOperator, from?: any, to?: any }, periodRange?: { operator?: SearchOperator, from?: any, to?: any, type?: PeriodTypes }};
    useEventDates?: Number;
    useAdHocDates?: Number;
    eventCategoryKey?: TypeaheadStringFilter;
    eventKey?: TypeaheadStringFilter;
    importanceLevel?: { operator?: SearchOperator, from?: string, to?: string };
    actions?: { includeClosed?: Number, isRenewalsOnly?: Number, isNonRenewalsOnly?: Number, actionKey?: TypeaheadStringFilter };
    dueDateResponsibilityOf?: { isAnyName?: Number, isStaff?: Number, isSignatory?: Number, nameType?: TypeaheadStringFilter, nameKey?: TypeaheadStringFilter, nameGroupKey?: TypeaheadStringFilter, staffClassificationKey?: TypeaheadStringFilter };
};

export type DueDateFilterCriteria = {
    dueDates: DueDate;
};

export type DueDateCallbackParams = {
    formData: DueDateFormData;
    filterCriteria: DueDateFilterCriteria;
    isModalClosed: Boolean;
};
