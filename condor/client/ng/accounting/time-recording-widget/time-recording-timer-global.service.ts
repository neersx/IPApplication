import { DatePipe } from '@angular/common';
import { Injectable } from '@angular/core';
import { WarningCheckerService } from 'accounting/warnings/warning-checker.service';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { Subject } from 'rxjs';
import { take } from 'rxjs/operators';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { TimerModalComponent } from './timer-modal/timer-modal.component';
import { TimerService } from './timer.service';

@Injectable({
  providedIn: 'root'
})
export class TimeRecordingTimerGlobalService {
  private readonly timerDetailsClosedSubject: Subject<boolean> = new Subject<boolean>();
  timerDetailsClosed$ = this.timerDetailsClosedSubject.asObservable();

  constructor(
    private readonly notificationService: NotificationService,
    private readonly modalService: IpxModalService,
    private readonly warningChecker: WarningCheckerService,
    private readonly datePipe: DatePipe,
    private readonly timerService: TimerService,
    private readonly ipxNotificationService: IpxNotificationService
  ) { }

  private readonly emitTimerDetailsClosed = (timerStarted: boolean): void => {
    this.timerDetailsClosedSubject.next(timerStarted);
  };

  private readonly startTimer = (caseKey: number): void => {
    this.timerService.startTimerFor(caseKey)
      .subscribe((timerInfo: any) => {
        if (!!timerInfo.stoppedTimer && !!timerInfo.stoppedTimer.start) {
          this.notificationService.success('accounting.time.recording.timerStoppedAndNewStarted', { startTime: this.datePipe.transform(timerInfo.stoppedTimer.start, this.timerService.timeFormat) });
        } else {
          this.notificationService.success('accounting.time.recording.timerStarted');
        }

        const modalRef = this.modalService.openModal(TimerModalComponent, { animated: false, ignoreBackdropClick: true, class: 'use-default-if-hosted', initialState: { timerDetails: timerInfo.startedTimer } });
        modalRef.content.onClose$
          .pipe(take(1))
          .subscribe(() => {
            this.emitTimerDetailsClosed(true);
          });
      });
  };

  startTimerForCase = (caseKey: number): void => {
    if (!caseKey && caseKey !== 0) {
      this.emitTimerDetailsClosed(false);

      return;
    }

    this.warningChecker.performCaseWarningsCheck(caseKey, new Date())
      .pipe(take(1))
      .subscribe((proceed) => {
        if (!!proceed) {
          this.startTimer(caseKey);
        } else {
            this.ipxNotificationService.onHide$.pipe(take(1)).subscribe(() => {
                this.emitTimerDetailsClosed(false);
            });
        }

        return;
      });
  };
}