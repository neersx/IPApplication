import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, Output, ViewChild } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import { delay, take, takeUntil } from 'rxjs/operators';
import { IpxClockComponent } from 'shared/component/forms/ipx-clock/ipx-clock.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { LocaleDatePipe } from 'shared/pipes/locale-date.pipe';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { TimeMessagingService } from './message.service';
import { TimerModalComponent } from './timer-modal/timer-modal.component';
import { TimerService } from './timer.service';

@Component({
    selector: 'ipx-time-recording-widget',
    templateUrl: './time-recording-widget.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})
export class TimeRecordingWidgetComponent implements OnInit {
    _isTimerRunning = false;
    get isTimerRunning(): boolean {
        return this._isTimerRunning;
    }
    set isTimerRunning(value: boolean) {
        this._isTimerRunning = value;
        this.sendMessageForTimerStateChange(this._isTimerRunning);
    }

    get timeFormat(): string {
        return this.timerService.timeFormat;
    }

    data: TimerDetail;
    bindings: Array<string>;
    isHosted = false;
    hostId = null;
    @ViewChild('clock', { static: false }) _timer: IpxClockComponent;

    constructor(private readonly cdr: ChangeDetectorRef,
        readonly timerService: TimerService,
        private readonly notificationService: NotificationService,
        private readonly destroy$: IpxDestroy,
        readonly datePipe: DatePipe,
        readonly localDate: LocaleDatePipe,
        private readonly messagingService: TimeMessagingService,
        private readonly windowParentMessagingService: WindowParentMessagingService,
        private readonly modalService: IpxModalService) {
    }

    ngOnInit(): void {
        this.checkCurrentRunningTimers();
        this.messagingService.message$
            .pipe(takeUntil(this.destroy$))
            .subscribe((message: any) => {
                if (!!message) {
                    if (this.isTimerRunning && !message.hasActiveTimer) {
                        const start = message.basicDetails.start;
                        this.notificationService.success('accounting.time.recording.prevTimerStopped', { timerDate: this.localDate.transform(start, null), startTime: this.datePipe.transform(start, this.timerService.timeFormat) });
                    }
                    this.isTimerRunning = message.hasActiveTimer;
                    this.data = new TimerDetail(message.basicDetails);
                    this.cdr.detectChanges();
                    if (this.isTimerRunning && !!this._timer && (!this._timer.start || this._timer.startTime !== new Date(message.basicDetails.start).getTime())) {
                        this._timer.resetTimer(message.basicDetails.start);
                    }
                }
            });
    }

    checkCurrentRunningTimers = (): void => {
        this.timerService
            .checkCurrentRunningTimers()
            .pipe(take(1), takeUntil(this.destroy$))
            .subscribe((t: any) => {
                if (!!t.stoppedTimer && !!t.stoppedTimer.start) {
                    const start = t.stoppedTimer.start;
                    this.notificationService.success('accounting.time.recording.prevTimerStopped', { timerDate: this.localDate.transform(start, null), startTime: this.datePipe.transform(start, this.timerService.timeFormat) });
                }
                if (!!t.runningTimer) {
                    this.data = new TimerDetail(t.runningTimer);
                    this.isTimerRunning = true;
                    this.cdr.markForCheck();
                }
            });
    };

    stopTimer = (): void => {
        const dataToSave = { ...this.getTimerDataToSave() };
        this.timerService.stopTimer(dataToSave, this._timer.time).pipe().subscribe(() => {
            this.notificationService.success();
        });
    };

    getTimerDataToSave = (): any => {
        let dataToSave = {} as any;
        dataToSave = { ...dataToSave, ..._.pick(this.data, 'staffId', 'entryNo', 'parentEntryNo', 'start') };
        dataToSave.isTimer = true;

        return dataToSave;
    };

    widgetClick = (): any => {
        const modalRef = this.modalService.openModal(TimerModalComponent, { animated: false, ignoreBackdropClick: true, initialState: { timerDetails: { ...this.data } } });
        modalRef.content.onClose$
            .pipe(take(1), delay(500))
            .subscribe((isTimerRunning: boolean) => {
                if (!isTimerRunning) {
                    this.isTimerRunning = false;

                    return;
                }
                this.sendMessageForExpansion(false);
            });

        this.sendMessageForExpansion(true);
    };

    sendMessageForExpansion = (expand: boolean): void => {
        if (this.isHosted) {
            this.windowParentMessagingService.postLifeCycleMessage({
                action: 'onChange',
                target: this.hostId,
                payload: {
                    expand,
                    timerState: true
                }
            });
        }
    };

    sendMessageForTimerStateChange = (timerState: boolean): void => {
        if (this.isHosted) {
            this.windowParentMessagingService.postLifeCycleMessage({
                action: 'onChange',
                target: this.hostId,
                payload: {
                    timerState
                }
            });
        }
    };
}
export class TimerDetail {
    staffId: number;
    entryNo: number;
    start: Date;
    caseReference: string;
    activity: string;
    name: string;
    parentEntryNo: number;

    constructor(data: any) {
        if (!!data) {
            Object.assign(this, data);
            this.start = new Date(data.start);
        }
    }
}
