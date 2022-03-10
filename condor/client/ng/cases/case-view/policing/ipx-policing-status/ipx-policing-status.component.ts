import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, NgZone, OnDestroy, OnInit, Output } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { BusService } from 'core/bus.service';
import { MessageBroker } from 'core/message-broker';
import { PolicingService } from '../policing.service';

@Component({
  selector: 'ipx-policing-status',
  templateUrl: './ipx-policing-status.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxPolicingStatusComponent implements OnInit, OnDestroy {
  @Input() caseKey: number;
  @Output() readonly policingCompleted = new EventEmitter();
  policingStatus: string;
  hasFailedPolicing: boolean;
  bindings: Array<string> = [];
  subscription: any;
  processing: boolean;
  constructor(
    private readonly zone: NgZone,
    private readonly messageBroker: MessageBroker,
    private readonly cdr: ChangeDetectorRef,
    private readonly policingService: PolicingService,
    private readonly bus: BusService,
    private readonly notificationService: NotificationService) { }

  ngOnInit(): void {
    this.subscribeToPolicing();
    this.subscription = this.policingService.policingCompleted.subscribe((reload) => {
      if (reload) {
        this.policingCompleted.emit();
      }
    });
  }

  ngOnDestroy(): void {
    this.messageBroker.disconnectBindings(this.bindings);
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
  }

  private readonly subscribeToPolicing = () => {
    const binding = 'policing.change.' + this.caseKey;
    this.bindings.push(binding);
    this.messageBroker.subscribe(binding, (status) => {
      this.zone.runOutsideAngular(() => {
        this.updatePolicingStatus(status);
      });
    });
    this.messageBroker.connect();
  };

  private readonly updatePolicingStatus = (status) => {
    if (this.policingStatus != null && status == null) {
      this.policingCompleted.emit();
      this.notificationService.success('caseview.summary.policing.statusCompleted');
      this.bus.channel('policingCompleted').broadcast();
    }
    this.policingStatus = status;
    this.hasFailedPolicingStatus(status);
    this.processing = status != null && status.toLowerCase() === 'running';
    this.cdr.markForCheck();
  };

  private readonly hasFailedPolicingStatus = (status) => {
    this.hasFailedPolicing = status != null && status.toLowerCase() === 'error';
  };
}
