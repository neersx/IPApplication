import { AfterViewInit, ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { AppContextService } from 'core/app-context.service';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import { NameViewService } from 'names/name-view/name-view.service';
import { BehaviorSubject, of } from 'rxjs';
import { take } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { Topic } from 'shared/component/topics/ipx-topic.model';

@Component({
    selector: 'app-name-hosted-topic',
    templateUrl: './hosted-case-topic.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class HostedNameTopicComponent implements OnInit, AfterViewInit {
    topic: Topic;
    topicData: any;
    isSaving = new BehaviorSubject(false);
    disabled = new BehaviorSubject(true);
    showHeaderBar = true;
    componentRef: any;
    showWebLink: boolean;
    hostId: string;
    onRequestDataResponseReceived: { [key: string]: (data: { value: any }) => void } = {
      sanityCheckClosed: (ignorSantityCheck) => {
        if (ignorSantityCheck.value) {
          this.save(null, ignorSantityCheck.value);
        }
        this.isSaving.next(false);
      }
    };

    constructor(private readonly nameService: NameViewService, private readonly notificationService: NotificationService, private readonly windowParentMessagingService: WindowParentMessagingService,
        private readonly confirmNotificationService: IpxNotificationService, private readonly appContextService: AppContextService) {}

    ngOnInit(): void {
        this.appContextService.appContext$.subscribe(v => {
            this.showWebLink = (v.user ? v.user.permissions.canShowLinkforInprotechWeb === true : false);
        });
        this.resolveComponent();
    }

    ngAfterViewInit(): void {
      this.nameService.enableSave.subscribe((s: boolean) => {
        this.disabled.next(!(s || false));
      });
    }

    afterViewInit = (data: Event): void => {
      this.componentRef = data;
      this.componentRef.showWebLink = this.showWebLink;
    };

    save = (e: Event, ignorSantityCheck: boolean): void => {
        let data = {};
        data = {
            supplierDetails: this.componentRef.formData
        };

        if (this.componentRef.formData.hasOutstandingPurchases && (this.componentRef.formData.oldRestrictionKey !== this.componentRef.formData.restrictionKey)) {
              const notificationRef = this.confirmNotificationService.openConfirmationModal(null, 'nameview.supplierDetails.restrictionConfirmMessage', null, null, null, null, false);
              notificationRef.content.confirmed$.pipe(
                  take(1))
                  .subscribe(() => {
                    this.componentRef.formData.updateOutstandingPurchases = true;
                       this.saveNameData(data, ignorSantityCheck);
                  });
              notificationRef.content.cancelled$.pipe(
                  take(1))
                  .subscribe(() => {
                    this.componentRef.formData.updateOutstandingPurchases = false;
                       this.saveNameData(data, ignorSantityCheck);
                  });
          } else {
            this.saveNameData(data, ignorSantityCheck);
          }
    };

    saveNameData = (data: any, ignorSantityCheck: boolean) => {
        this.nameService.maintainName$({
            nameId: this.componentRef.nameId,
            ignoreSanityCheck: ignorSantityCheck,
            topics: data
        }).subscribe(result => {
            this.isSaving.next(true);
            if (result.status === 'error') {
              this.notificationService.alert('unSavedChanges');

              return;
            } else if (result.savedSuccessfully) {
                this.notificationService.success();
                this.nameService.savedSuccessful.next(true);
                this.componentRef.originalFormData = {
                    ...this.componentRef.formData
                };
                this.windowParentMessagingService.postLifeCycleMessage({
                    action: 'onChange',
                    target: 'supplierHost',
                    payload: {
                        isDirty: false
                    }
                });
                this.isSaving.next(false);
            }
            this.proceedWithSanityCheck(result);
        });
    };

    revert = (e: Event): void => {
        this.nameService.resetChanges.next(true);
        this.disabled.next(true);
    };

    private readonly resolveComponent = (): void => {
      if (this.topic.params.viewData.hostId === 'trustHost' || this.topic.params.viewData.hostId === 'nameDMSHost') {
        this.showHeaderBar = false;
      }
      this.hostId = this.topic.params.viewData.hostId;
      this.topicData = {
        component: this.topic.component,
        resolve: () => of(
          { topic: this.topic })
      };
    };

    private readonly proceedWithSanityCheck = (saveResults) => {
      if (saveResults.sanityCheckResults && saveResults.sanityCheckResults.length !== 0) {
        this.windowParentMessagingService.postLifeCycleMessage({
          target: this.hostId,
          action: 'SanityCheckResults',
          payload: saveResults.sanityCheckResults
        });
      }
      this.isSaving.next(false);
    };
  }