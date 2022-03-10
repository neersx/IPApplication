import { ChangeDetectionStrategy, ChangeDetectorRef, Component } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicOptions } from 'shared/component/topics/ipx-topic.model';

@Component({
    template: '',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class NameViewTopicBaseComponent implements TopicContract {
    topic: Topic;
    formData: any = {};
    viewData: any;
    isExternal: Boolean;
    form: NgForm;
    constructor(private readonly cdRef: ChangeDetectorRef) {
    }

    onInit = (): void => {
        this.initFormData();
        this.initStates();
        this.initTopicsData();
    };

    initFormData = () => {
        if (this.topic.params && this.topic.params.viewData) {
          this.viewData = { ...this.topic.params.viewData };
          setTimeout(() => {
            this.cdRef.markForCheck();
          });
        }
      };

      initStates = () => {
        Object.assign(this.topic, {
          loadFormData: this.loadFormData,
          updateFormData: this.updateFormData,
          formData: this.formData
        });
      };
    // tslint:disable-next-line:no-empty
  initTopicsData = () => { };

  // tslint:disable-next-line:no-empty
  loadFormData = () => { };

  updateFormData = () => {
    const formData = this.formData;
    Object.assign(this.topic, { formData });
    this.cdRef.detectChanges();
  };
}