import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { AbstractControl, NgForm } from '@angular/forms';
import { SearchOperator } from 'search/common/search-operators';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { OperatorCombinations, RemindersSearchBuilder } from '../search-builder.data';

@Component({
  selector: 'app-reminders-search-builder',
  templateUrl: './reminders-search-builder.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class RemindersSearchBuilderComponent implements TopicContract, OnInit {
  topic: Topic;
  viewData: any;
  formData: RemindersSearchBuilder;
  searchOperator: any = SearchOperator;
  operatorCombinations: any = OperatorCombinations;
  @ViewChild('remindersForm', { static: true }) form: NgForm;

  constructor(private readonly cdr: ChangeDetectorRef) {
    this.initFormData();
  }

  ngOnInit(): void {
    this.viewData = this.topic.params.viewData;

    if (this.viewData && this.viewData.formData && this.viewData.formData.reminders) {
      this.formData = this.viewData.formData.reminders;
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
    return this.form.valid;
  };

  isDirty = (): boolean => {
    return this.form.dirty;
  };

  setPristine = (): void => {
    _.each(this.form.controls, (c: AbstractControl) => {
      c.markAsPristine();
      c.markAsUntouched();
    });
  };

  initFormData(): void {
    this.formData = {
      reminderMessage: { operator: SearchOperator.startsWith },
      isOnHold: true,
      isNotOnHold: true,
      isRead: true,
      isNotRead: true
    };
  }

  getFormData = (): any => {
    const searchRequest: any = {};
    if (this.form.valid) {

      if (this.formData.reminderMessage.value) {
        searchRequest.reminderMessage = {
          operator: this.formData.reminderMessage.operator,
          value: this.formData.reminderMessage.value
        };
      }
      if ((this.formData.isOnHold && !this.formData.isNotOnHold) || (!this.formData.isOnHold && this.formData.isNotOnHold)) {
        searchRequest.isReminderOnHold = this.formData.isOnHold ? 1 : 0;
      }

      if ((this.formData.isRead && !this.formData.isNotRead) || (!this.formData.isRead && this.formData.isNotRead)) {
        searchRequest.isReminderRead = this.formData.isRead ? 1 : 0;
      }

      return { searchRequest, formData: { reminders: this.formData } };
    }
  };

}

export class RemindersSearchBuilderTopic extends Topic {
  readonly key = 'reminders';
  readonly title = 'taskPlanner.searchBuilder.reminders.header';
  readonly component = RemindersSearchBuilderComponent;
  constructor(public params: RemindersSearchBuilderTopicParams) {
    super();
  }
}

export class RemindersSearchBuilderTopicParams extends TopicParam { }
