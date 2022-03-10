import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { BulkUpdateData, DropDownData } from '../bulk-update.data';

@Component({
  selector: 'ipx-bulk-edit-case-text-update',
  templateUrl: './case-text-update.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})

export class CaseTextUpdateComponent implements TopicContract, OnInit {
  topic: Topic;
  initFormData: any = {
    canAppend: true,
    language: '',
    textType: '',
    notes: '',
    class: ''
  };

  clear = false;
  formData: any = { ...this.initFormData };
  caseIds: Array<number>;
  labelTranslationKey: string;
  isTextTypeGS = false;
  allowRichText = false;
  @ViewChild('ngForm', { static: true }) form: NgForm;

  constructor(private readonly changeDetectorRef: ChangeDetectorRef) { }

  ngOnInit(): void {
    this.labelTranslationKey = 'bulkUpdate.caseTextUpdate';
    this.caseIds = this.topic.params.viewData.caseIds;
    this.allowRichText = this.topic.params.viewData.allowRichText;
    Object.assign(this.topic, {
      getSaveData: this.getSaveData,
      discard: this.discard
    });
  }

  resetNotesControl = () => {
    if (!this.formData.textType || this.formData.textType.key === '') {
      this.formData.notes = '';
    }
    this.isTextTypeGS = this.formData.textType != null && this.formData.textType !== '' && this.formData.textType.key === 'G';
    this.formData.canAppend = this.isTextTypeGS ? false : this.formData.canAppend;
    this.formData.class = '';
  };

  clearCaseText = () => {
    this.formData.notes = '';
  };

  discard = (): void => {
    this.formData = { ...this.initFormData };
    this.clear = false;
    this.isTextTypeGS = false;
    this.changeDetectorRef.markForCheck();
  };

  getSaveData = (): BulkUpdateData => {
    const data = {};
    const key = 'caseText';
    if (this.formData.textType && this.formData.textType.key !== '') {
      data[key] = {
        textType: this.formData.textType.key,
        language: this.formData.language ? this.formData.language.key : null,
        toRemove: this.clear,
        canAppend: this.formData.canAppend,
        labelTranslationKey: this.labelTranslationKey,
        notes: this.formData.notes,
        value: this.formData.textType.value,
        class: this.formData.class ? this.formData.class.code : null

      };
    }

    return data;
  };
}

export class CaseTextUpdateTopic extends Topic {
  readonly key = 'caseTextUpdate';
  readonly title = 'bulkUpdate.caseTextUpdate.header';
  readonly component = CaseTextUpdateComponent;
  constructor(public params: CaseTextUpdateTopicParams) {
    super();
  }
}

export class CaseTextUpdateTopicParams extends TopicParam { }