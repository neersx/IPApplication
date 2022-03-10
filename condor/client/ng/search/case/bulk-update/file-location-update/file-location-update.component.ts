import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { CommonUtilityService } from 'core/common.utility.service';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import { BulkUpdateData } from '../bulk-update.data';

@Component({
  selector: 'app-file-location-update',
  templateUrl: './file-location-update.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class FileLocationUpdateComponent implements OnInit {
  topic: Topic;
  initFormData: any = {
    toRemove: false,
    fileLocation: null,
    movedBy: null,
    bayNumber: null,
    whenMoved: new Date()
  };

  clear = false;
  formData: any = { ...this.initFormData };
  caseIds: Array<number>;
  labelTranslationKey: string;
  @ViewChild('ngForm', { static: true }) form: NgForm;

  constructor(private readonly changeDetectorRef: ChangeDetectorRef, readonly commonUtilityService: CommonUtilityService) { }

  ngOnInit(): void {
    this.labelTranslationKey = 'bulkUpdate.fileLocationUpdate';
    this.caseIds = this.topic.params.viewData.caseIds;
    Object.assign(this.topic, { getSaveData: this.getSaveData, discard: this.discard, isValid: this.isValid });
  }

  discard = (): void => {
    this.formData = { ...this.initFormData };
    this.clear = false;
    this.formData.whenMoved = new Date();
    this.changeDetectorRef.markForCheck();
  };

  isValid = (): boolean => {
    return this.form.valid;
  };

  getSaveData = (): BulkUpdateData => {
    const data = {};
    const key = 'fileLocation';
    if (this.formData.fileLocation && this.formData.fileLocation.key !== '') {
      data[key] = {
        fileLocation: this.formData.fileLocation.key,
        movedBy: this.formData.movedBy ? this.formData.movedBy.key : null,
        bayNumber: this.formData.bayNumber,
        whenMoved: this.formData.whenMoved,
        toRemove: this.clear,
        labelTranslationKey: this.labelTranslationKey,
        value: this.formData.fileLocation.value
      };
    }

    return data;
  };

}

export class FileLocationUpdateTopic extends Topic {
  readonly key = 'fileLocationUpdate';
  readonly title = 'bulkUpdate.fileLocationUpdate.header';
  readonly component = FileLocationUpdateComponent;
  readonly info: string;
  constructor(public params: FileLocationUpdateTopicParams, private readonly infoMessage: string) {
    super();
    this.info = infoMessage;
  }
}

export class FileLocationUpdateTopicParams extends TopicParam { }