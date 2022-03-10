import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { BulkUpdateData, DropDownData } from '../bulk-update.data';

@Component({
  selector: 'ipx-bulk-edit-field-update',
  templateUrl: './field-update.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})

export class FieldUpdateComponent implements TopicContract, OnInit {
  topic: Topic;
  initFormData: any = {
    caseOffice: {},
    profitCentre: {},
    caseFamily: {},
    purchaseOrder: '',
    entitySize: '',
    typeOfMark: {},
    titleMark: ''
  };

  formControls: any = {};
  formData: any = { ...this.initFormData };
  caseIds: Array<number>;
  entitySizes: Array<DropDownData>;
  labelTranslationKey: string;
  @ViewChild('ngForm', { static: true }) form: NgForm;

  constructor(private readonly changeDetectorRef: ChangeDetectorRef) { }

  ngOnInit(): void {
    this.labelTranslationKey = 'bulkUpdate.fieldUpdate';
    this.caseIds = this.topic.params.viewData.caseIds;
    this.entitySizes = this.topic.params.viewData.entitySizes;
    Object.assign(this.topic, {
      getSaveData: this.getSaveData,
      discard: this.discard
    });
  }
  clear = (fieldName: any) => {
    this.formData[fieldName] = '';
  };

  discard = (): void => {
    this.formData = { ...this.initFormData };
    this.formControls = {};
    this.changeDetectorRef.markForCheck();
  };

  getSaveData = (): BulkUpdateData => {
    const data = {};
    _.each(this.formControls, (value, key) => {
      if (value) {
        data[key] = { key: '', toRemove: true, labelTranslationKey: this.labelTranslationKey };
      }
    });
    _.each(this.formData, (value: any, key: string) => {
      if (!_.isEmpty(value) || (_.isNumber(value) && value)) {
        switch (key) {
          case 'entitySize':
            const entitySizeName = _.first(_.filter(this.entitySizes, (entityData: DropDownData) => {
              return entityData.key === value;
            }));
            data[key] = { key: entitySizeName.key, value: entitySizeName.value, labelTranslationKey: this.labelTranslationKey };
            break;
          case 'profitCentre':
            data[key] = { key: value.code, value: value.description, labelTranslationKey: this.labelTranslationKey };
            break;
          case 'purchaseOrder':
          case 'titleMark':
            data[key] = { key: value, value, labelTranslationKey: this.labelTranslationKey };
            break;
          default:
            data[key] = { key: value.key, value: value.value, labelTranslationKey: this.labelTranslationKey };
            break;
        }
      }
    });

    return data;
  };
}

export class FieldUpdateTopic extends Topic {
  readonly key = 'fieldUpdate';
  readonly title = 'bulkUpdate.fieldUpdate.header';
  readonly component = FieldUpdateComponent;
  constructor(public params: FieldUpdateTopicParams) {
    super();
  }
}

export class FieldUpdateTopicParams extends TopicParam { }