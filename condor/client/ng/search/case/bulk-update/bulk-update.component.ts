import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { StateService } from '@uirouter/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import * as angular from 'angular';
import { CommonUtilityService } from 'core/common.utility.service';
import { LocalSettings } from 'core/local-settings';
import { queryContextKeyEnum } from 'search/common/search-type-config.provider';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { Topic, TopicOptions } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { BulkUpdateConfirmationComponent } from './bulk-update-confirmation/bulk-update-confirmation.component';
import { BulkUpdateData, BulkUpdateReasonData } from './bulk-update.data';
import { BulkUpdateService } from './bulk-update.service';
import { CaseNameReferenceUpdateTopic } from './case-name-reference-update/case-name-reference-update.component';
import { CaseTextUpdateTopic } from './case-text-update/case-text-update.component';
import { FieldUpdateTopic } from './field-update/field-update.component';
import { FileLocationUpdateTopic } from './file-location-update/file-location-update.component';
import { CaseStatusUpdateTopic } from './status-update/status-update.component';

@Component({
  selector: 'bulk-update',
  templateUrl: './bulk-update.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BulkUpdateComponent implements OnInit {

  topicOptions: TopicOptions;
  hasPreviousState: boolean;
  @Input() viewData: {
    caseIds: Array<number>,
    [propName: string]: any;
  };

  @Input() previousState: {
    name: string,
    params: any
  };

  modalRef: any;
  formData: BulkUpdateData;
  reasonData: BulkUpdateReasonData;
  showFileLocationTopic: boolean;
  additionalStateParam: any;
  constructor(
    private readonly stateService: StateService,
    private readonly bulkUpdateService: BulkUpdateService,
    private readonly notificationService: NotificationService,
    private readonly modalService: IpxModalService,
    private readonly localSettings: LocalSettings,
    private readonly translate: TranslateService,
    private readonly commonService: CommonUtilityService) {
  }

  ngOnInit(): void {
    const bulkUpdateData = this.localSettings.keys.bulkUpdate.data.getSession;
    if (!bulkUpdateData || !bulkUpdateData.caseIds) {
      this.localSettings.keys.bulkUpdate.data.setSession(null);
      this.stateService.go('search-results', { queryContext: queryContextKeyEnum.caseSearch as number }, { inherit: false });

      return;
    }

    this.viewData.caseIds = bulkUpdateData.caseIds.split(',');

    if (this.previousState && this.previousState.name === 'search-results') {
      this.hasPreviousState = true;
      this.additionalStateParam = {};
      angular.extend(this.additionalStateParam, this.previousState.params);
      this.additionalStateParam.checkPersistedData = true;
    }

    this.initializeTopics();
  }

  private initializeTopics(): void {
    const topics: Array<Topic> = [
      new FieldUpdateTopic({ viewData: angular.extend({}, this.viewData) }),
      new CaseTextUpdateTopic({ viewData: angular.extend({}, this.viewData) }),
      new CaseNameReferenceUpdateTopic({ viewData: angular.extend({}, this.viewData) })
    ];

    if (this.viewData.canMaintainFileTracking) {
      const fileLocationInfo = this.commonService.formatString('{0} {1}.', this.translate.instant('bulkUpdate.fileLocationUpdate.info'), (this.viewData.caseIds && this.viewData.caseIds.length === 1 ? this.translate.instant('bulkUpdate.case') : this.translate.instant('bulkUpdate.cases')));
      topics.push(new FileLocationUpdateTopic({ viewData: angular.extend({}, this.viewData) }, fileLocationInfo));
    }

    if (this.viewData.canUpdateBulkStatus) {
      topics.push(new CaseStatusUpdateTopic({ viewData: angular.extend({}, this.viewData) }));
    }

    this.topicOptions = { topics, actions: [] };
  }

  canDiscard(): boolean {

    return this.viewData.caseIds && this.viewData.caseIds.length > 0 && _.some(this.getFormData());
  }

  canApply(): boolean {

    return this.viewData.caseIds && this.isFormValid() && this.viewData.caseIds.length > 0 && _.some(this.getFormData());
  }

  save(): void {
    this.bulkUpdateService.applyBulkUpdateChanges(this.viewData.caseIds, this.formData, this.reasonData).subscribe((response) => {
      if (response.status) {
        this.notificationService.success('bulkUpdate.requestSubmitted');
        this.discard();
      }
    });
  }

  discard(): void {
    _.each(this.topicOptions.topics, (t: any) => {
      if (_.isFunction(t.discard)) {
        t.discard();
      }
    });
  }

  openConfirmationDialog = (): void => {
    this.formData = this.getFormData();
    this.modalRef = this.modalService.openModal(BulkUpdateConfirmationComponent, {
      animated: false,
      backdrop: 'static',
      class: 'modal-lg',
      initialState: {
        formData: this.formData,
        selectedCaseCount: this.viewData.caseIds ? this.viewData.caseIds.length : 0,
        textTypes: this.viewData.textTypes,
        selectedCases: this.viewData.caseIds,
        allowRichText: this.viewData.allowRichText
      }
    });

    this.modalRef.content.onClose.subscribe(value => {
      if (value) {
        this.reasonData = value;
        this.save();
      }
    });
  };

  private getFormData(): BulkUpdateData {
    if (!this.topicOptions) {
      return null;
    }
    const data: BulkUpdateData = {};
    _.each(this.topicOptions.topics, (t: any) => {
      if (_.isFunction(t.getSaveData)) {
        _.extend(data, t.getSaveData());
      }
    });

    return data;
  }

  private isFormValid(): boolean {
    let isValid = true;
    _.each(this.topicOptions.topics, (t: any) => {
      if (_.isFunction(t.isValid)) {
        if (!t.isValid()) {
          isValid = false;
        }
      }
    });

    return isValid;
  }
}
