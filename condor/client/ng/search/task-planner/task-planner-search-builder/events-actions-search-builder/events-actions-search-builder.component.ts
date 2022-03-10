import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { AbstractControl, NgForm } from '@angular/forms';
import { SearchOperator } from 'search/common/search-operators';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { EventsActionsSearchBuilder, OperatorCombinations } from '../search-builder.data';

@Component({
  selector: 'app-events-actions-search-builder',
  templateUrl: './events-actions-search-builder.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class EventsActionsSearchBuilderComponent implements TopicContract, OnInit {
  topic: Topic;
  viewData: any;
  formData: EventsActionsSearchBuilder;
  searchOperator: any = SearchOperator;
  operatorCombinations: any = OperatorCombinations;
  showEventNoteType: boolean;
  @ViewChild('eventsActionsForm', { static: true }) eventsActionsForm: NgForm;

  constructor(private readonly cdr: ChangeDetectorRef) {
    this.initFormData();
  }

  ngOnInit(): void {
    this.viewData = this.topic.params.viewData;

    this.showEventNoteType = this.viewData.showEventNoteType;
    if (this.viewData && this.viewData.formData && this.viewData.formData.eventsAndActions) {
      this.formData = this.viewData.formData.eventsAndActions;
    }

    Object.assign(this.topic, {
      getFormData: this.getFormData,
      clear: this.clear,
      isValid: this.isValid,
      isDirty: this.isDirty,
      setPristine: this.setPristine
    });
  }

  clear = (): void => {
    this.initFormData();
    this.cdr.markForCheck();
  };

  isValid = (): boolean => {
    return this.eventsActionsForm.valid;
  };

  isDirty = (): boolean => {
    return this.eventsActionsForm.dirty;
  };

  setPristine = (): void => {
    _.each(this.eventsActionsForm.controls, (c: AbstractControl) => {
      c.markAsPristine();
      c.markAsUntouched();
    });
  };

  changeOperator = (field: string): void => {
    const data = this.formData[field];
    // tslint:disable-next-line: prefer-conditional-expression
    if (data.operator === SearchOperator.equalTo || data.operator === SearchOperator.notEqualTo) {
      data.value = Array.isArray(data.value) ? data.value : null;
    } else if (data.operator === SearchOperator.startsWith || data.operator === SearchOperator.endsWith || data.operator === SearchOperator.contains) {
      data.value = Array.isArray(data.value) ? null : data.value;
    } else {
      data.value = null;
    }
  };

  initFormData(): void {
    this.formData = {
      event: { operator: SearchOperator.equalTo },
      eventCategory: { operator: SearchOperator.equalTo },
      eventGroup: { operator: SearchOperator.equalTo },
      eventNoteType: { operator: SearchOperator.equalTo },
      eventNotes: { operator: SearchOperator.startsWith },
      action: { operator: SearchOperator.equalTo },
      isRenewals: true,
      isNonRenewals: true,
      isClosed: false
    };
  }

  getFormData = (): any => {
    const searchRequest: any = {};
    if (this.eventsActionsForm.valid) {

      searchRequest.eventKeys = this.getSearchElement('event');
      searchRequest.eventCategoryKeys = this.getSearchElement('eventCategory');
      searchRequest.eventGroupKeys = this.getSearchElement('eventGroup', 'key');
      searchRequest.eventNoteTypeKeys = this.getSearchElement('eventNoteType');
      searchRequest.eventNoteText = this.getSearchElement('eventNotes');
      searchRequest.actions = {
        actionKeys: this.getSearchElement('action', 'code'),
        isRenewalsOnly: this.formData.isRenewals ? 1 : 0,
        isNonRenewalsOnly: this.formData.isNonRenewals ? 1 : 0,
        includeClosed: this.formData.isClosed ? 1 : 0
      };

      return { searchRequest, formData: { eventsAndActions: this.formData } };
    }
  };

  private readonly getSearchElement = (itemName: string, valueProperty = 'key'): any => {
    const element = this.formData[itemName];
    if (element.operator === SearchOperator.exists || element.operator === SearchOperator.notExists || (element.value && (!Array.isArray(element.value) || element.value.length > 0))) {
      return {
        operator: element.operator,
        value: element.value && Array.isArray(element.value) ? _.pluck(element.value, valueProperty).join(',') : element.value
      };
    }

    return null;
  };

}

export class EventsActionsSearchBuilderTopic extends Topic {
  readonly key = 'eventsAndActions';
  readonly title = 'taskPlanner.searchBuilder.eventsAndActions.header';
  readonly component = EventsActionsSearchBuilderComponent;
  constructor(public params: EventsActionsSearchBuilderTopicParams) {
    super();
  }
}

export class EventsActionsSearchBuilderTopicParams extends TopicParam { }
