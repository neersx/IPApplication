import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { StateService } from '@uirouter/core';
import { PostTimeResponseDlgComponent } from 'accounting/time-recording/post-time/post-time-response-dlg/post-time-response-dlg.component';
import { PostResult } from 'accounting/time-recording/post-time/post-time.model';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { CommonUtilityService } from 'core/common.utility.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { queryContextKeyEnum } from 'search/common/search-type-config.provider';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { BackgroundNotificationMessage, BackgroundNotificationService, ProcessSubType, ProcessType } from './background-notification.service';
import { GraphIntegrationService } from './graph-integration.service';

@Component({
  selector: 'background-notification',
  templateUrl: './background-notification.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BackgroundNotificationComponent implements AfterViewInit {

  modalRef: BsModalRef;
  gridoptions: IpxGridOptions;
  hasGridData: boolean;
  callBack: Function;
  constructor(readonly cdref: ChangeDetectorRef,
    readonly backgroundNotificationService: BackgroundNotificationService,
    readonly notificationService: NotificationService,
    readonly stateService: StateService,
    readonly translate: TranslateService,
    readonly commonUtilityService: CommonUtilityService,
    private readonly graphService: GraphIntegrationService,
    readonly modalService: IpxModalService
  ) {
    this.gridoptions = this.getGridOptions();
  }

  ngAfterViewInit(): void {
    this.cdref.detectChanges();
  }

  private getGridOptions(): IpxGridOptions {
    return {
      autobind: true,
      read$: () => {
        const notifications = this.backgroundNotificationService.readMessages$();
        notifications.subscribe(result => {
          this.hasGridData = result.length > 0;
          this.cdref.detectChanges();
        });

        return notifications;
      },
      columns: [{
        field: 'processName',
        title: 'backgroundNotifications.processName',
        width: 100,
        template: true
      }, {
        field: 'status',
        title: 'backgroundNotifications.status',
        width: 100
      }, {
        field: 'statusDate',
        title: 'backgroundNotifications.statusDate',
        width: 150,
        template: true
      },
      {
        field: 'statusInfo',
        title: 'backgroundNotifications.statusDetails',
        width: 200,
        template: true
      },
      {
        field: 'processId',
        title: '',
        width: 15,
        template: true
      }]
    };
  }

  handleClick = (message: BackgroundNotificationMessage): void => {
    if (!message) { return; }
    switch (message.processType.toLowerCase()) {
      case ProcessType[ProcessType.GlobalCaseChange].toLowerCase():
        this.stateService.go('search-results', {
          presentationType: 'GlobalCaseChangeResults',
          globalProcessKey: message.processId,
          backgroundProcessResultTitle: this.getPageTitle(message.processSubType),
          queryContext: queryContextKeyEnum.caseSearch as number
        }, { inherit: false });
        if (this.callBack) {
          this.callBack();
        }
        break;
      case ProcessType[ProcessType.CpaXmlExport].toLowerCase():
        this.backgroundNotificationService.downloadCpaXmlExport(message.processId);
        break;
      case ProcessType[ProcessType.CpaXmlForImport].toLowerCase():
        this.backgroundNotificationService.downloadCpaXmlExport(message.processId);
        break;
      case ProcessType[ProcessType.StandardReportRequest].toLowerCase():
        this.backgroundNotificationService.downloadExportContent(message.processId);
        break;
      case ProcessType[ProcessType.SanityCheck].toLowerCase():
        this.stateService.go('sanity-check-results', { id: message.processId }, { inherit: false });
        if (this.callBack) {
          this.callBack();
        }
        break;
      default:
        break;
    }
  };

  loginGraphIntegration = (dataItem: any): void => {
    this.graphService.login(dataItem);
  };

  getPageTitle = (processSubType) => {
    if (processSubType && processSubType != null) {
      return this.translate.instant('backgroundNotifications.title.' + processSubType.toLowerCase());
    }

    return this.translate.instant('backgroundNotifications.title.bulkFieldUpdateResults');
  };

  deleteProcess(process: Array<number>): void {
    this.notificationService.confirmDelete({
      message: 'backgroundNotifications.deleteConfirmationText', cancel: 'Cancel',
      continue: 'Delete'
    }).then(() => {
      this.backgroundNotificationService.deleteProcessIds(process).subscribe((response) => {
        if (response) {
          this.notificationService.success('backgroundNotifications.deleteSuccess');
        }
      });
    });
  }

  canShowLink = (dataItem: any): boolean => {

      return dataItem.status === 'Completed' && dataItem.processType !== 'globalNameChange' && dataItem.processSubType !== 'applyRecordals' && dataItem.processSubType !== 'timePosting';
  };

  displayTimePostingResults(statusInfo: string): void {
    const data: PostResult = JSON.parse(statusInfo);
    this.modalService.openModal(PostTimeResponseDlgComponent, {
        animated: false, ignoreBackdropClick: true, initialState: data
    });
  }

  navigateToTime(statusInfo: string): void {
      const data = JSON.parse(statusInfo);
      this.stateService.go('timeRecording', {
          entryDate: new Date(data.entryDate),
          entryNo: data.entryNo
      });
  }
}