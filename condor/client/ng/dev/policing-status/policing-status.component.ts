import { ChangeDetectionStrategy, Component, NgZone, OnDestroy, OnInit } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { MessageBroker } from 'core/message-broker';

@Component({
  selector: 'policing-status',
  templateUrl: './policing-status.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class PolicingStatusComponent implements OnInit, OnDestroy {
  caseId = -486;
  policingStatus: string;
  bindings: Array<string> = [];
  constructor(
    private readonly messageBroker: MessageBroker,
    private readonly notificationService: NotificationService,
    private readonly zone: NgZone) {

  }

  ngOnInit(): void {
    this.updatedCaseId();
  }

  updatedCaseId(): void {
    const binding = 'policing.change.' + this.caseId;
    this.bindings.push(binding);

    this.zone.runOutsideAngular(() => {
      this.policingStatus = null;
      this.messageBroker.subscribe(binding, (status: string) => {
        this.policingStatus = status;
        if (this.policingStatus) {
          this.notificationService.success('New status received');
        }
      });
      this.messageBroker.connect();
    });
  }

  ngOnDestroy(): void {
    this.messageBroker.disconnectBindings(this.bindings);
  }

}
