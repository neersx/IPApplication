import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { AbstractControl, NgForm } from '@angular/forms';
import { SearchOperator } from 'search/common/search-operators';
import { TaskPlannerService } from 'search/task-planner/task-planner.service';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { AdhocDateSearchBuilder, OperatorCombinations } from '../search-builder.data';

@Component({
  selector: 'app-adhoc-date-search-builder',
  templateUrl: './adhoc-date-search-builder.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class AdhocDateSearchBuilderComponent implements TopicContract, OnInit {
  topic: Topic;
  viewData: any;
  formData: AdhocDateSearchBuilder;
  searchOperator: any = SearchOperator;
  operatorCombinations: any = OperatorCombinations;
  @ViewChild('adhocDateForm', { static: true }) form: NgForm;

  constructor(
    private readonly cdr: ChangeDetectorRef,
    private readonly taskPlannerService: TaskPlannerService
  ) {
    this.initFormData();
  }

  ngOnInit(): void {
    this.viewData = this.topic.params.viewData;

    if (this.viewData && this.viewData.formData && this.viewData.formData.adhocDates) {
      this.formData = this.viewData.formData.adhocDates;
    }

    this.taskPlannerService.adHocDateCheckedChangedt$.subscribe((param: any) => {
      if (!param) {
        return;
      }

      this.formData.includeCase = param.checked;
      this.formData.includeName = param.checked;
      this.formData.includeGeneral = param.checked;
      this.cdr.markForCheck();
    });

    Object.assign(this.topic, {
      getFormData: this.getFormData,
      clear: this.clear,
      isValid: this.isValid,
      isDirty: this.isDirty,
      setPristine: this.setPristine
    });
  }

  changeInclude = (include: boolean, name: string): void => {
    if (!include) {
      this.formData[name].value = null;
    }
  };

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
      names: { operator: SearchOperator.equalTo },
      generalRef: { operator: SearchOperator.startsWith },
      message: { operator: SearchOperator.startsWith },
      emailSubject: { operator: SearchOperator.startsWith },
      includeCase: true,
      includeName: true,
      includeGeneral: true,
      includeFinalizedAdHocDates: false
    };
  }

  getFormData = (): any => {
    const searchRequest: any = {};
    if (this.form.valid) {

      searchRequest.adHocReference = this.getSearchElement('generalRef');
      searchRequest.nameReferenceKeys = this.getSearchElement('names');
      searchRequest.adHocMessage = this.getSearchElement('message');
      searchRequest.adHocEmailSubject = this.getSearchElement('emailSubject');
      searchRequest.includeAdhocDate = {
        hasCase: this.formData.includeCase ? 1 : 0,
        hasName: this.formData.includeName ? 1 : 0,
        isGeneral: this.formData.includeGeneral ? 1 : 0,
        includeFinalizedAdHocDates: this.formData.includeFinalizedAdHocDates ? 1 : 0
      };

      return { searchRequest, formData: { adhocDates: this.formData } };
    }
  };

  private readonly getSearchElement = (itemName: string, valueProperty = 'key'): any => {
    const element = this.formData[itemName];
    const data = element.value ?
      {
        operator: element.operator,
        value: Array.isArray(element.value) ? _.pluck(element.value, valueProperty).join(',') : element.value
      } : null;

    return data;
  };

}

export class AdhocDateSearchBuilderTopic extends Topic {
  readonly key = 'adhocDate';
  readonly title = 'taskPlanner.searchBuilder.adhocDate.header';
  readonly component = AdhocDateSearchBuilderComponent;
  constructor(public params: AdhocDateSearchBuilderTopicParams) {
    super();
  }
}

export class AdhocDateSearchBuilderTopicParams extends TopicParam { }
