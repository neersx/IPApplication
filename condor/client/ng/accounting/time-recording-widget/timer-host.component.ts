import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import { delay, take, takeUntil } from 'rxjs/operators';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import { TimeRecordingTimerGlobalService } from './time-recording-timer-global.service';

@Component({
    selector: 'app-timer-host',
    template: '<div></div>',
    providers: [TimeRecordingTimerGlobalService, IpxDestroy],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class AppTimerHostComponent implements OnInit {
    @Input() caseKey: number;

    constructor(private readonly timerWidgetService: TimeRecordingTimerGlobalService,
        private readonly messagingService: WindowParentMessagingService,
        private readonly destroy$: IpxDestroy) {
    }

    ngOnInit(): void {
        this.timerWidgetService.timerDetailsClosed$
            .pipe(delay(1500), take(1), takeUntil(this.destroy$))
            .subscribe(() => {
                this.messagingService.postLifeCycleMessage({ action: 'onNavigate', target: 'startTimerForCaseHost', payload: true });
            });

        this.timerWidgetService.startTimerForCase(this.caseKey);
    }
}
