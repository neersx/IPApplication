import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { TimerService } from 'accounting/time-recording-widget/timer.service';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { StepsPersistenceService } from 'search/multistepsearch/steps.persistence.service';
import * as _ from 'underscore';
import { SearchHelperService } from '../../common/search-helper.service';
import { SearchOperator } from '../../common/search-operators';
import { CaseSearchTopicBaseComponent } from './case-search-topics.base.component';

@Component({
  selector: 'ipx-case-search-eventactions',
  templateUrl: './event.actions.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class EventActionsComponent extends CaseSearchTopicBaseComponent implements OnInit {
  periodTypes: any;
  importanceLevelOptions: any;
  showEventNoteType: any;
  showEventNoteSection: any;

  constructor(private readonly dateHelper: DateHelper,
    public persistenceService: StepsPersistenceService,
    public casehelper: SearchHelperService,
    readonly timeService: TimerService, private readonly datePipe: DatePipe,
    public cdRef: ChangeDetectorRef) {
    super(persistenceService, casehelper, cdRef);
  }

  ngOnInit(): void {
    this.onInit();
  }

  initTopicsData = () => {
    this.periodTypes = this.casehelper.getPeriodTypes();
    this.importanceLevelOptions = this.viewData.importanceOptions;
    this.showEventNoteType = this.viewData.showEventNoteType;
    this.showEventNoteSection = this.viewData.showEventNoteSection;

    if (this.formData) {
      this.formData.startDate = this.formData.startDate ? new Date(this.formData.startDate) : null;
      this.formData.endDate = this.formData.endDate ? new Date(this.formData.endDate) : null;
    }
  };

  isImportanceLevelDisabled(): boolean {
    return (this.formData.eventOperator === SearchOperator.equalTo || this.formData.eventOperator === SearchOperator.notEqualTo ||
      this.formData.eventOperator === SearchOperator.exists || this.formData.eventOperator === SearchOperator.notExists);
  }

  eventOperatorChange(): void {
    if (this.isImportanceLevelDisabled()) {
      this.formData.isRenewals = null;
      this.formData.isNonRenewals = null;
      this.formData.importanceLevelFrom = null;
      this.formData.importanceLevelTo = null;
    }
    this.cdRef.detectChanges();
  }

  extendNoteTypeFilter = (query) => {
    return {
      ...query,
      isExternal: this.isExternal
    };
  };

  updateSearchCheckbox(ctrl: String): void {
    if (ctrl === 'occurredEvent' && this.formData.occurredEvent === false) {
      this.formData.dueEvent = true;
    } else if (ctrl === 'dueEvent' && this.formData.dueEvent === false) {
      this.formData.occurredEvent = true;
    }
    this.cdRef.detectChanges();
  }

  getFilterCriteria = (savedFormData?): any => {
    const formData = savedFormData ? savedFormData : this.formData;

    return {
      ActionKey: this.casehelper.buildStringFilterFromTypeahead(formData.actionValue, formData.actionOperator, { IsOpen: Number(formData.actionIsOpen) }),
      Event: this.buildEvent(formData)
    };
  };

  buildEvent(formData: any): any {
    const eventResult = {
      operator: this.getEventOperatorKey(formData),
      isRenewalsOnly: Number(formData.isRenewals),
      isNonRenewalsOnly: Number(formData.isNonRenewals),
      byEventDate: Number(formData.occurredEvent)
    };
    if (formData.dueEvent) {
      Object.assign(eventResult, { byDueDate: Number(formData.dueEvent) });
    }
    if (formData.includeClosedActions) {
      Object.assign(eventResult, { includeClosedActions: Number(formData.includeClosedActions) });
    }
    if (formData.event) {
      Object.assign(eventResult, { eventKey: this.casehelper.getKeysFromTypeahead(formData.event, true) });
    }
    if (formData.event && formData.eventForCompare && !formData.eventOperator.key && formData.eventOperator !== SearchOperator.specificDate) {
      Object.assign(eventResult, { eventKeyForCompare: this.casehelper.getKeysFromTypeahead(formData.eventForCompare, true) });
    }
    if (formData.eventOperator === SearchOperator.specificDate) {

      const from =  this.dateHelper.toLocal(this.formData.startDate);
      const to =  this.dateHelper.toLocal(this.formData.endDate);
      const dateRangeReturn = this.casehelper.buildFromToValues(from, to);
      if (_.isEqual(dateRangeReturn, {})) {
        eventResult.operator = null;
      } else {
        Object.assign(eventResult, { dateRange: dateRangeReturn });
      }
    }
    if ((formData.eventOperator === 'L' || formData.eventOperator === 'N') && formData.eventWithinValue) {
      Object.assign(eventResult, {
        period: {
          type: formData.eventWithinValue.type,
          quantity: (formData.eventWithinValue.value) ?
            ((formData.eventOperator === 'L') ? '-' : '') + formData.eventWithinValue.value : ''
        }
      });
      eventResult.operator = 7;
    }
    if (formData.importanceLevelFrom || formData.importanceLevelTo) {
      const importanceLevelReturn = this.casehelper.buildFromToValues(formData.importanceLevelFrom, formData.importanceLevelTo);
      Object.assign(importanceLevelReturn, { operator: formData.importanceLevelOperator });
      if (!_.isEqual(importanceLevelReturn, {})) {
        Object.assign(eventResult, { importanceLevel: importanceLevelReturn });
      }
    }

    Object.assign(eventResult, { eventNoteTypeKeys: this.casehelper.buildStringFilterFromTypeahead(formData.eventNoteType, formData.eventNoteTypeOperator, null, true) });

    Object.assign(eventResult, { eventNoteText: this.casehelper.buildStringFilter(formData.eventNotesText, formData.eventNotesOperator) });

    return eventResult;
  }

  getEventOperatorKey(formData: any): any {
    if (formData.eventOperator === SearchOperator.specificDate) {
      return formData.eventDatesOperator;
    }

    // getting key from composite keys (eg. withinLast)
    return formData.eventOperator.key || formData.eventOperator;
  }

  discard = (): void => {
    this.formData = this.persistenceService.getTopicsDefaultViewModel(this.topic.key);

    this.cdRef.detectChanges();
  };

  onEventChange = (): any => {
    if (!this.formData.event || _.isEmpty(this.formData.event)) {
      this.formData.eventForCompare = [];
    }
  };

  isEventToCompareDisabled = (): Boolean => {
    return !this.formData.event || _.isEmpty(this.formData.event);
  };
}
