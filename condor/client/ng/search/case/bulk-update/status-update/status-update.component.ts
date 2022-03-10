import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { BsModalService } from 'ngx-bootstrap/modal';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { StatusUpdateConfirmationComponent } from '../bulk-update-confirmation/status-update-confirmation.component';
import { BulkUpdateData } from '../bulk-update.data';

@Component({
  selector: 'ipx-bulk-edit-case-status-update',
  templateUrl: './status-update.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})

export class CaseStatusUpdateComponent implements TopicContract, OnInit {
  topic: Topic;
  initFormData: any = {
    isRenewal: false,
    status: ''
  };

  modalRef: any;
  clear = false;
  formData: any = { ...this.initFormData };
  caseIds: Array<number>;
  labelTranslationKey: string;
  isDialogOpen: boolean;
  @ViewChild('ngForm', { static: true }) form: NgForm;

  constructor(private readonly changeDetectorRef: ChangeDetectorRef,
    private readonly modalService: BsModalService) { }

  ngOnInit(): void {
    this.labelTranslationKey = 'bulkUpdate.caseStatusUpdate';
    this.caseIds = this.topic.params.viewData.caseIds;
    Object.assign(this.topic, {
      getSaveData: this.getSaveData,
      discard: this.discard
    });
  }

  extendStatus = (query) => {
    return {...query,
        isRenewal: this.formData.isRenewal
    };
  };

  clearCaseStatus = () => {
    this.formData.status = '';
  };

  changeStatus = (event: any) => {
    if (!!event && event.key && !this.isDialogOpen) {
      if (this.formData.status && this.formData.status.isConfirmationRequired) {
        this.isDialogOpen = true;
        this.openConfirmDialog();
      }
    }
  };

  openConfirmDialog = (): void => {
    if (this.modalRef) { return; }
    this.modalRef = this.modalService.show(StatusUpdateConfirmationComponent, {
      animated: false,
      backdrop: 'static',
      class: 'modal-md'
    });

    this.modalService.onHide
      .subscribe(() => {
        this.modalRef = null;
        this.isDialogOpen = false;
      });

    this.modalRef.content.onClose.subscribe(value => {
      if (value) {
        this.formData.status.password = value;
      } else {
        this.clearCaseStatus();
        this.changeDetectorRef.markForCheck();
      }
    });
  };

  discard = (): void => {
    this.formData = { ...this.initFormData };
    this.changeDetectorRef.markForCheck();
  };

  getSaveData = (): BulkUpdateData => {
    const data = {};
    const key = this.formData.isRenewal ? 'renewalStatus' : 'caseStatus';
    if ((this.formData.status && this.formData.status.key !== '') || this.clear) {
      data[key] = {
        statusCode: this.formData.status ? this.formData.status.key : null,
        value: this.formData.status ? this.formData.status.value : null,
        toRemove: this.clear,
        isRenewal: this.formData.isRenewal,
        labelTranslationKey: this.labelTranslationKey,
        confirmStatus: this.formData.status ? this.formData.status.isConfirmationRequired : false,
        password: this.formData.status ? this.formData.status.password : null
      };
    }

    return data;
  };
}

export class CaseStatusUpdateTopic extends Topic {
  readonly key = 'CaseStatusUpdate';
  readonly title = 'bulkUpdate.caseStatusUpdate.header';
  readonly component = CaseStatusUpdateComponent;
  constructor(public params: CaseStatusUpdateTopicParams) {
    super();
  }
}

export class CaseStatusUpdateTopicParams extends TopicParam { }