import { AfterViewInit, ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { MaintenanceTopicContract } from 'cases/case-view/base/case-view-topics.base.component';
import { CaseDetailService, TopicChanges } from 'cases/case-view/case-detail.service';
import { RegenerateChecklistComponent } from 'cases/case-view/checklists/regeneration/regenerate-checklist';
import { PolicingService } from 'cases/case-view/policing/policing.service';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { BehaviorSubject, of } from 'rxjs';
import { take } from 'rxjs/internal/operators/take';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import { PingService } from 'shared/shared-services/ping.service';

@Component({
  selector: 'app-hosted-topic',
  templateUrl: './hosted-case-topic.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class HostedCaseTopicComponent implements OnInit, AfterViewInit {
  topic: Topic;
  topicData: any;
  isSaving = new BehaviorSubject(false);
  disabled = new BehaviorSubject(true);
  showHeaderBar = true;
  componentRef: any;
  storedResponse: any = null;
  hostId: string;
  topicName: string;
  modalRef: BsModalRef;
  onRequestDataResponseReceived: { [key: string]: (data: { value: any }) => void } = {
    sanityCheckClosed: (forceUpdate) => {
      if (forceUpdate.value) {
        this.save(null, true, forceUpdate.value);
      } else if (this.storedResponse && this.storedResponse.savedSuccessfully) {
        const shouldPolice = this.storedResponse.shouldRunPolicing && this.storedResponse.batchNo;
        if (shouldPolice) {
          this.runPolicing(this.storedResponse.batchNo);
        } else {
          this.savingCompleted();
        }
      }
      this.isSaving.next(false);
    },
    hasTopicChanges: (message: any) => {
      this.windowParentMessagingService.postNavigationMessage({
        action: 'HasCaseTopicChanges',
        args: [!this.disabled.getValue(), message.value.action, message.value.topicName]
      });
    }
  };

  constructor(
    private readonly caseDetailService: CaseDetailService,
    private readonly notificationService: NotificationService,
    private readonly windowParentMessagingService: WindowParentMessagingService,
    private readonly policingService: PolicingService,
    private readonly pingService: PingService,
    private readonly modalService: IpxModalService) { }

  ngOnInit(): void {
    this.resolveComponent();
  }

  ngAfterViewInit(): void {
    this.caseDetailService.hasPendingChanges$.subscribe((s: boolean) => {
      this.disabled.next(!(s || false));
    });
  }

  afterViewInit = (data: Event): void => {
    this.componentRef = data;
  };

  save = (e: Event, forceUpdate = false, ignoreSanityCheck = false): void => {
    const validationRequired = (this.componentRef.topic.key === 'checklist');
    let topicValid = false;
    if (validationRequired) {
      topicValid = (this.componentRef as MaintenanceTopicContract).isValid();
    }

    if (!validationRequired || (validationRequired && topicValid)) {
      this.isSaving.next(true);
      this.windowParentMessagingService.postRequestForData('isPoliceImmediately', this.hostId, this, () => {
        return Promise.resolve(null as boolean);
      }).then((isPoliceImmediately) => {
        this.saveChanges(isPoliceImmediately, forceUpdate, ignoreSanityCheck);
      });
    }
  };

  saveChanges = (isPoliceImmediately: boolean, forceUpdate = false, ignoreSanityCheck = false): void => {
    this.pingService.ping().then(() => {
      const topicChanges = (this.componentRef as MaintenanceTopicContract).getChanges();
      const checklistPreSaveActionRequired = (this.componentRef.topic.key === 'checklist');
      if (checklistPreSaveActionRequired && topicChanges.checklistQuestions.showRegenerationDialog) {
        this.modalRef = this.modalService.openModal(RegenerateChecklistComponent, {
          animated: false,
          backdrop: 'static',
          ignoreBackdropClick: true,
          class: 'modal-lg',
          focus: true,
          initialState: topicChanges
        });
        this.modalRef.content.proceedData.pipe(take(1)).subscribe(() => {
          this.saveCaseData(topicChanges, isPoliceImmediately, forceUpdate, ignoreSanityCheck);
        });
        this.modalRef.content.dontSave.pipe(take(1)).subscribe(() => {
          this.isSaving.next(false);
        });
      } else {
        this.saveCaseData(topicChanges, isPoliceImmediately, forceUpdate, ignoreSanityCheck);
      }
    });
  };

  saveCaseData = (topicChanges: any, isPoliceImmediately: boolean, forceUpdate: boolean, ignoreSanityCheck: boolean): void => {
    this.caseDetailService.updateCaseDetails$({ caseKey: this.topic.params.viewData.caseKey, program: '', topics: topicChanges, isPoliceImmediately, forceUpdate, ignoreSanityCheck }).subscribe((res: any) => {
      const shouldPolice = res.shouldRunPolicing && res.batchNo;
      this.storedResponse = res;
      if (res.status === 'error' || res.status === 'warning') {
        const errors = (res.errors as Array<any> || []).filter((error) => {
          return error.topic === this.topicName;
        });
        if (res.status === 'warning' && (errors).length > 0) {
          this.notificationService.confirm({
            message: 'caseview.actions.events.saveWarning',
            cancel: 'Cancel',
            continue: 'Proceed'
          }).then(() => {
            this.saveChanges(isPoliceImmediately, true);
          });
        }

        this.caseDetailService.hasPendingChanges$.next(true);
        this.caseDetailService.errorDetails$.next(errors);
        this.isSaving.next(false);

        return;
      }

      this.proceedWithSanityCheck(res, shouldPolice);
    });
  };

  runPolicing = (batchNo: number): void => {
    this.windowParentMessagingService.postNavigationMessage({
      action: 'StartPolicing',
      args: [this.topic.params.viewData.caseKey]
    });
    this.policingService.policeBatch(batchNo).then(() => {
      this.windowParentMessagingService.postNavigationMessage({
        action: 'StopPolicing',
        args: [this.topic.params.viewData.caseKey, null, true]
      });
      this.savingCompleted();
    });
  };

  savingCompleted = (): void => {
    this.notificationService.success('saveMessage');
    this.disabled.next(true);
    this.caseDetailService.hasPendingChanges$.next(false);
    this.caseDetailService.resetChanges$.next(true);
    this.isSaving.next(false);
  };

  revert = (e: Event): void => {
    this.caseDetailService.resetChanges$.next(true);
    this.caseDetailService.hasPendingChanges$.next(false);
  };

  private readonly proceedWithSanityCheck = (res, shouldPolice) => {
    if (res.sanityCheckResults && res.sanityCheckResults.length !== 0) {
      this.windowParentMessagingService.postLifeCycleMessage({
        target: this.hostId,
        action: 'SanityCheckResults',
        payload: res.sanityCheckResults
      });
    } else if (res.savedSuccessfully) {
      if (shouldPolice) {
        this.runPolicing(res.batchNo);
      } else {
        this.savingCompleted();
      }
    } else {
      this.isSaving.next(false);
    }
  };
  private readonly resolveComponent = (): void => {
    this.hostId = this.topic.params.viewData.hostId;
    this.topicName = this.topic.key;
    if (!this.topic.params.viewData.canMaintainCase || this.topic.params.viewData.hostId === 'caseDMSHost') {
      this.showHeaderBar = false;
    }
    this.topicData = {
      component: this.topic.component,
      resolve: () => of(
        { topic: this.topic })
    };
  };
}
