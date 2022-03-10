import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { AbstractControl, NgForm } from '@angular/forms';
import { DueDateFilterService } from 'search/case/due-date/due-date-filter.service';
import { PeriodTypes } from 'search/case/due-date/due-date.model';
import { TaskPlannerService } from 'search/task-planner/task-planner.service';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { DateFilterType, GeneralSearchBuilder } from '../search-builder.data';

@Component({
  selector: 'app-general-search-builder',
  templateUrl: './general-search-builder.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class GeneralSearchBuilderComponent implements TopicContract, OnInit {
  topic: Topic;
  viewData: any;
  formData: GeneralSearchBuilder;
  periodTypes: Array<any>;
  dateFilterType: DateFilterType;
  belongingToOptions: Array<any>;
  importanceLevelOptions: Array<any>;
  disabledReminderRecipient = false;
  disabledDueDateResponsibleStaff = false;

  disableReminders = false;
  disableDueDates = false;
  disableAdHocDates = false;
  @ViewChild('generalForm', { static: true }) generalForm: NgForm;
  @ViewChild('dueDateInfoTemplate', { static: true }) dueDateInfoTemplate: TemplateRef<any>;
  constructor(
    private readonly filterService: DueDateFilterService,
    private readonly cdr: ChangeDetectorRef,
    private readonly taskPlannerService: TaskPlannerService
  ) {
    this.periodTypes = this.filterService.getPeriodTypes();
    this.initFormData();
  }

  ngOnInit(): void {
    this.viewData = this.topic.params.viewData;
    this.belongingToOptions = this.taskPlannerService.getBelongingToOptions();
    this.importanceLevelOptions = this.viewData.importanceLevels;
    if (this.viewData && this.viewData.formData && this.viewData.formData.general) {
      this.setDateFilterType();
      this.formData = this.viewData.formData.general;
      this.formData.belongingToFilter.value = this.formData.belongingToFilter.value === '' ? 'allNames' : this.formData.belongingToFilter.value;
      this.disabledReminderRecipient = !this.formData.includeFilter.adHocDates && !this.formData.includeFilter.reminders && this.formData.includeFilter.dueDates;
      this.disabledDueDateResponsibleStaff = this.formData.includeFilter.adHocDates && !this.formData.includeFilter.reminders && !this.formData.includeFilter.dueDates;
      this.disableReminders = !this.formData.includeFilter.adHocDates && this.formData.includeFilter.reminders && !this.formData.includeFilter.dueDates ? true : false;
      this.disableDueDates = !this.formData.includeFilter.adHocDates && !this.formData.includeFilter.reminders && this.formData.includeFilter.dueDates ? true : false;
      this.disableAdHocDates = this.formData.includeFilter.adHocDates && !this.formData.includeFilter.reminders && !this.formData.includeFilter.dueDates ? true : false;
    } else {
      this.formData.belongingToFilter.value = 'myself';
    }

    Object.assign(this.topic, {
      getFormData: this.getFormData,
      clear: this.clear,
      isValid: this.isValid,
      isDirty: this.isDirty,
      setPristine: this.setPristine
    });
  }

  setDateFilterType(): void {
    if (this.viewData.formData.general.dateFilter.dateFilterType === DateFilterType.range) {
      this.viewData.formData.general.dateFilter.dateRange.from = this.viewData.formData.general.dateFilter.dateRange.from ? new Date(this.viewData.formData.general.dateFilter.dateRange.from) : null;
      this.viewData.formData.general.dateFilter.dateRange.to = this.viewData.formData.general.dateFilter.dateRange.to ? new Date(this.viewData.formData.general.dateFilter.dateRange.to) : null;
      this.viewData.formData.general.dateFilter.operator = (!this.viewData.formData.general.dateFilter.dateRange.from && !this.viewData.formData.general.dateFilter.dateRange.to) ? '7' : this.viewData.formData.general.dateFilter.operator;
    } else {
      this.viewData.formData.general.dateFilter.operator = (!this.viewData.formData.general.dateFilter.datePeriod.from && !this.viewData.formData.general.dateFilter.datePeriod.to) ? '7' : this.viewData.formData.general.dateFilter.operator;
    }
  }

  clear = (): void => {
    this.initFormData();
    this.cdr.markForCheck();
  };

  isValid = (): boolean => {
    return this.generalForm.valid;
  };

  isDirty = (): boolean => {
    return this.generalForm.dirty;
  };

  setPristine = (): void => {
    _.each(this.generalForm.controls, (c: AbstractControl) => {
      c.markAsPristine();
      c.markAsUntouched();
    });
  };

  // tslint:disable-next-line: cyclomatic-complexity
  getFormData = (): any => {
    const searchRequest: any = {};
    if (this.generalForm.valid) {
      const belongsTo = this.formData.belongingToFilter.value;
      searchRequest.include = {
        isReminders: this.formData.includeFilter.reminders ? 1 : 0,
        isDueDates: this.formData.includeFilter.dueDates ? 1 : 0,
        isAdHocDates: this.formData.includeFilter.adHocDates ? 1 : 0
      };
      searchRequest.dates = {
        useDueDate: this.formData.searchByFilter.dueDate ? 1 : 0,
        useReminderDate: this.formData.searchByFilter.reminderDate ? 1 : 0,
        sinceLastWorkingDay: this.formData.dateFilter.operator === '14' ? 1 : 0,
        dateRange: null,
        periodRange: null
      };
      searchRequest.belongsTo = {
        nameKey: belongsTo === 'myself' ? {
          isCUrrentUser: 1,
          operator: 0
        } : null,
        memberOfGroupKey: belongsTo === 'myTeam' ? {
          isCUrrentUser: 1,
          operator: 0
        } : null,
        nameKeys: belongsTo === 'otherNames' && _.any(this.formData.belongingToFilter.names) ? { value: _.pluck(this.formData.belongingToFilter.names, 'key').join(',') } : null,
        memberOfGroupKeys: belongsTo === 'otherTeams' && _.any(this.formData.belongingToFilter.nameGroups) ? { value: _.pluck(this.formData.belongingToFilter.nameGroups, 'key').join(',') } : null,
        actingAs: {
          isReminderRecipient: this.formData.belongingToFilter.actingAs.isReminder ? 1 : 0,
          isResponsibleStaff: this.formData.belongingToFilter.actingAs.isDueDate ? 1 : 0,
          nameTypeKey: _.any(this.formData.belongingToFilter.actingAs.nameTypes) ? _.pluck(this.formData.belongingToFilter.actingAs.nameTypes, 'code') : null
        }
      };
      searchRequest.importanceLevel = !this.formData.importanceLevel.to && !this.formData.importanceLevel.from ? null : this.formData.importanceLevel;

      if (this.formData.dateFilter.dateFilterType === DateFilterType.range) {
        searchRequest.dates.dateRange = this.formData.dateFilter.dateRange.from || this.formData.dateFilter.dateRange.to ? {
          operator: this.formData.dateFilter.operator,
          from: this.formData.dateFilter.dateRange.from,
          to: this.formData.dateFilter.dateRange.to
        } : null;
        searchRequest.dates.periodRange = null;
      } else {
        searchRequest.dates.periodRange = this.formData.dateFilter.datePeriod.from || this.formData.dateFilter.datePeriod.to ? {
          operator: this.formData.dateFilter.operator,
          type: this.formData.dateFilter.datePeriod.periodType,
          from: this.formData.dateFilter.datePeriod.from,
          to: this.formData.dateFilter.datePeriod.to
        } : null;
        searchRequest.dates.dateRange = null;
      }
    }

    return { searchRequest, formData: { general: this.formData } };
  };

  changeReminders(): void {
    this.checkForReminderDate();
    this.checkForOnlyAdHocDate();
    this.checkForOnlyDueDate();
    this.checkForOnlyReminders();
  }

  changeDueDates(): void {
    this.checkForOnlyAdHocDate();
    this.checkForOnlyDueDate();
    this.checkForOnlyReminders();
  }

  changeAdHocDates(): void {
    this.checkForOnlyAdHocDate();
    this.checkForOnlyDueDate();
    this.checkForOnlyReminders();
    this.taskPlannerService.adHocDateCheckedChangedt$.next({ checked: this.formData.includeFilter.adHocDates });
  }

  private readonly checkForReminderDate = (): void => {
    if (this.formData.includeFilter.reminders) {
      this.formData.searchByFilter.reminderDate = true;
      this.formData.searchByFilter.dueDate = true;
    }
  };

  private readonly checkForOnlyReminders = (): void => {
    this.disableReminders = this.formData.includeFilter.reminders &&
      !this.formData.includeFilter.adHocDates &&
      !this.formData.includeFilter.dueDates
      ? true
      : false;
  };
  private readonly checkForOnlyAdHocDate = (): void => {
    if (this.formData.includeFilter.adHocDates && !this.formData.includeFilter.reminders && !this.formData.includeFilter.dueDates) {
      this.formData.searchByFilter.reminderDate = true;
      this.formData.searchByFilter.dueDate = true;
      this.formData.belongingToFilter.actingAs.isDueDate = false;
      this.disabledDueDateResponsibleStaff = true;
      this.disableAdHocDates = true;
    } else {
      this.disabledDueDateResponsibleStaff = false;
      this.disableAdHocDates = false;
    }
  };

  private readonly checkForOnlyDueDate = (): void => {
    if (!this.formData.includeFilter.adHocDates && !this.formData.includeFilter.reminders && this.formData.includeFilter.dueDates) {
      this.formData.searchByFilter.reminderDate = false;
      this.formData.belongingToFilter.actingAs.isReminder = false;
      this.formData.searchByFilter.dueDate = true;
      this.disabledReminderRecipient = true;
      this.disableDueDates = true;
    } else {
      this.disabledReminderRecipient = false;
      this.disableDueDates = false;
    }
  };

  changeBelongingTo(): void {
    this.formData.belongingToFilter.names = null;
    this.formData.belongingToFilter.nameGroups = null;
  }

  changeDateOperator(): void {
    if (this.formData.dateFilter.operator === '14') {
      this.formData.dateFilter.dateRange.from = null;
      this.formData.dateFilter.datePeriod.from = null;
    }
  }

  changePeriodDate(): void {
    this.cdr.detectChanges();
  }

  toggleRangePeriod(): void {
    if (this.formData.dateFilter.dateFilterType === DateFilterType.period) {
      this.formData.dateFilter.dateRange.from = null;
      this.formData.dateFilter.dateRange.to = null;
      this.formData.dateFilter.datePeriod.periodType = PeriodTypes.days;
    } else {
      this.formData.dateFilter.datePeriod.from = null;
      this.formData.dateFilter.datePeriod.to = null;
    }
  }

  validateRangeControl = (controlName, fromValue, toValue): any => {
    const control = this.generalForm.controls[controlName];
    if (fromValue && toValue
      && (!isNaN(fromValue) && !isNaN(toValue))) {
      if (parseInt(fromValue, 10) > parseInt(toValue, 10)) {
        control.markAsTouched();
        control.setErrors({ 'taskPlanner.general.periodErrorMessage': true });
      } else {
        control.setErrors(null);
      }
    }
  };

  initFormData(): void {

    this.formData = {
      includeFilter: {
        reminders: true,
        dueDates: true,
        adHocDates: true
      },
      searchByFilter: {
        dueDate: true,
        reminderDate: true
      },
      dateFilter: {
        dateFilterType: 0,
        operator: '7',
        dateRange: {
          from: null,
          to: null
        },
        datePeriod: {
          from: null,
          to: null,
          periodType: PeriodTypes.days
        }
      },
      importanceLevel: { operator: '7', from: null, to: null },
      belongingToFilter: { names: [], nameGroups: [], actingAs: { isDueDate: true, isReminder: true, nameTypes: [] }, value: 'myself' }
    };
  }
}

export class GeneralSearchBuilderTopic extends Topic {
  readonly key = 'general';
  readonly title = 'taskPlanner.searchBuilder.general.header';
  readonly component = GeneralSearchBuilderComponent;
  constructor(public params: GeneralSearchBuilderTopicParams) {
    super();
  }
}

export class GeneralSearchBuilderTopicParams extends TopicParam { }
