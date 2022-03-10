import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { StepsPersistenceService } from 'search/multistepsearch/steps.persistence.service';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { SearchHelperService } from '../../common/search-helper.service';
import { SearchOperator } from '../../common/search-operators';
@Component({
  template: '',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseSearchTopicBaseComponent implements TopicContract {

  topic: Topic;
  formData: any = {};
  viewData: any;
  isExternal: Boolean;
  form: NgForm;
  searchOperator: any = SearchOperator;

  constructor(public persistenceService: StepsPersistenceService,
    public casehelper: SearchHelperService, public cdRef: ChangeDetectorRef) {
  }

  onInit = (): void => {
    this.initFormData();
    this.initStates();
    this.initTopicsData();
  };

  initFormData = () => {
    if (this.topic.params && this.topic.params.viewData) {
      this.viewData = { ...this.topic.params.viewData };
      this.isExternal =
        this.viewData.isExternal === true ||
        this.viewData.isExternal === 'true';
      this.viewData.model = this.persistenceService.getTopicExistingViewModel(
        this.topic.key
      );
      this.formData = { ...this.viewData.model };
      setTimeout(() => {
        this.cdRef.markForCheck();
      });
    }
  };

  initStates = () => {
    Object.assign(this.topic, {
      discard: this.discard,
      loadFormData: this.loadFormData,
      updateFormData: this.updateFormData,
      getFilterCriteria: this.getFilterCriteria,
      formData: this.formData
    });
  };

  // tslint:disable-next-line:no-empty
  initTopicsData = () => { };

  discard = (): void => {
    this.formData = this.persistenceService.getTopicsDefaultViewModel(this.topic.key);
    this.cdRef.detectChanges();
  };

  // tslint:disable-next-line:no-empty
  getFilterCriteria = () => { };

  loadFormData = (formData): void => {
    this.formData = formData;
    _.assign(this.topic, { formData });
    this.cdRef.detectChanges();
  };

  updateFormData = () => {
    const formData = this.formData;
    Object.assign(this.topic, { formData });
    this.cdRef.detectChanges();
  };
}