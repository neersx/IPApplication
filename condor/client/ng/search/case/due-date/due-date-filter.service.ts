import { Injectable } from '@angular/core';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { SearchHelperService } from '../../common/search-helper.service';
import { DueDateFilterCriteria, DueDateFormData } from './due-date.model';

@Injectable()
export class DueDateFilterService {
    constructor(readonly casehelper: SearchHelperService, readonly dateHelper: DateHelper) { }

    prepareFilter = (formData: DueDateFormData): DueDateFilterCriteria => {
        const filter: DueDateFilterCriteria = {
            dueDates: {
                useEventDates: formData.event ? 1 : 0,
                useAdHocDates: formData.adhoc ? 1 : 0
            }
        };

        filter.dueDates.dates = {};
        filter.dueDates.dates.useDueDate = formData.searchByDate ? 1 : 0;
        filter.dueDates.dates.useReminderDate = formData.searchByRemindDate ? 1 : 0;

        if (formData.rangeType === 0 && (formData.startDate || formData.endDate)) {
            filter.dueDates.dates.dateRange = {};
            filter.dueDates.dates.dateRange.operator = formData.dueDatesOperator;
            filter.dueDates.dates.dateRange.from = formData.startDate ? this.dateHelper.toLocal(formData.startDate) : formData.startDate;
            filter.dueDates.dates.dateRange.to = formData.endDate ? this.dateHelper.toLocal(formData.endDate) : formData.endDate;
        }

        if (formData.rangeType === 1 && (formData.fromPeriod || formData.toPeriod) && formData.periodType) {
            filter.dueDates.dates.periodRange = {};
            filter.dueDates.dates.periodRange.operator = formData.dueDatesOperator;
            filter.dueDates.dates.periodRange.from = formData.fromPeriod;
            filter.dueDates.dates.periodRange.to = formData.toPeriod;
            filter.dueDates.dates.periodRange.type = formData.periodType;
        }

        filter.dueDates.eventCategoryKey = this.casehelper.buildStringFilterFromTypeahead(
            formData.eventCategoryValue,
            formData.eventCategoryOperator,
            null,
            true
        );

        filter.dueDates.eventKey = this.casehelper.buildStringFilterFromTypeahead(
            formData.eventValue,
            formData.eventOperator,
            null,
            true
        );

        filter.dueDates.importanceLevel = {};
        filter.dueDates.importanceLevel.operator = formData.importanceLevelOperator;
        filter.dueDates.importanceLevel.from = formData.importanceLevelFrom;
        filter.dueDates.importanceLevel.to = formData.importanceLevelTo;

        filter.dueDates.actions = {};
        filter.dueDates.actions.includeClosed = formData.isClosedActions ? 1 : 0;
        filter.dueDates.actions.isRenewalsOnly = formData.isRenevals ? 1 : 0;
        filter.dueDates.actions.isNonRenewalsOnly = formData.isNonRenevals ? 1 : 0;
        filter.dueDates.actions.actionKey = this.casehelper.buildStringFilterFromTypeahead(
            formData.actionValue,
            formData.actionOperator
        );

        filter.dueDates.dueDateResponsibilityOf = {};
        filter.dueDates.dueDateResponsibilityOf.isAnyName = formData.isAnyName ? 1 : 0;
        filter.dueDates.dueDateResponsibilityOf.isStaff = formData.isStaff ? 1 : 0;
        filter.dueDates.dueDateResponsibilityOf.isSignatory = formData.isSignatory ? 1 : 0;
        filter.dueDates.dueDateResponsibilityOf.nameType = this.casehelper.buildStringFilterFromTypeahead(
            formData.nameTypeValue,
            formData.nameTypeOperator
        );
        filter.dueDates.dueDateResponsibilityOf.nameKey = this.casehelper.buildStringFilterFromTypeahead(
            formData.nameValue,
            formData.nameOperator,
            null,
            true
        );
        filter.dueDates.dueDateResponsibilityOf.nameGroupKey = this.casehelper.buildStringFilterFromTypeahead(
            formData.nameGroupValue,
            formData.nameGroupOperator,
            null,
            true
        );
        filter.dueDates.dueDateResponsibilityOf.staffClassificationKey = this.casehelper.buildStringFilterFromTypeahead(
            formData.staffClassificationValue,
            formData.staffClassificationOperator
        );

        return filter;
    };

    getPeriodTypes(): Array<{ key: string, value: string }> {
        return [{
            key: 'D',
            value: 'periodTypes.days'
        }, {
            key: 'W',
            value: 'periodTypes.weeks'
        }, {
            key: 'M',
            value: 'periodTypes.months'
        }, {
            key: 'Y',
            value: 'periodTypes.years'
        }];
    }
}