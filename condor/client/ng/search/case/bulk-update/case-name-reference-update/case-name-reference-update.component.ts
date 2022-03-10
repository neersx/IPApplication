import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import { BulkUpdateData } from '../bulk-update.data';

@Component({
  selector: 'case-name-reference-update',
  templateUrl: './case-name-reference-update.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseNameReferenceUpdateComponent implements TopicContract, OnInit {
  topic: Topic;
  caseIds: Array<number>;
  initFormData: any = {
    nameType: '',
    reference: ''
  };
  clear = false;
  formData: any = { ...this.initFormData };
  labelTranslationKey: string;
  @ViewChild('ngForm', { static: true }) form: NgForm;

  constructor(private readonly changeDetectorRef: ChangeDetectorRef) { }

  ngOnInit(): void {
    this.labelTranslationKey = 'bulkUpdate.caseNameReferenceUpdate';
    this.caseIds = this.topic.params.viewData.caseIds;
    Object.assign(this.topic, {
      getSaveData: this.getSaveData,
      discard: this.discard,
      isValid: this.isValid
    });
  }

  discard = (): void => {
    this.formData = { ...this.initFormData };
    this.clear = false;
    this.changeDetectorRef.markForCheck();
  };

  isValid = (): boolean => {

    return this.validateTopic();
  };

  resetReference = (): void => {
    this.formData.reference = '';
  };

  private readonly validateTopic = (): boolean => {
    let isValid = true;
    const referenceControl = this.form.controls.reference;
    if (!this.clear && this.formData.nameType && this.formData.reference === '') {
      referenceControl.setErrors({ required: true });
      if (!referenceControl.dirty) {
        referenceControl.markAsTouched();
        referenceControl.markAsDirty();
        referenceControl.updateValueAndValidity();
      }
      isValid = false;
      this.changeDetectorRef.markForCheck();
    } else {
      referenceControl.setErrors(undefined);
      this.form.form.setErrors(undefined);
    }

    return isValid;
  };

  getSaveData = (): BulkUpdateData => {
    const data = {};
    const key = 'caseNameReference';
    if (this.validateTopic() && this.formData.nameType) {
      data[key] = {
        labelTranslationKey: this.labelTranslationKey,
        nameType: this.formData.nameType.code,
        toRemove: this.clear,
        value: this.formData.nameType.value,
        reference: this.formData.reference
      };
    }

    return data;
  };
}

export class CaseNameReferenceUpdateTopic extends Topic {
  readonly key = 'caseNameReferenceUpdate';
  readonly title = 'bulkUpdate.caseNameReferenceUpdate.header';
  readonly component = CaseNameReferenceUpdateComponent;
  constructor(public params: CaseNameReferenceUpdateTopicParams) {
    super();
  }
}

export class CaseNameReferenceUpdateTopicParams extends TopicParam { }