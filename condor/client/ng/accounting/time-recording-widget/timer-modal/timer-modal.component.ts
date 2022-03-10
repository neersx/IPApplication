import { ChangeDetectionStrategy, Component, EventEmitter, Input, OnInit, Self, ViewChild } from '@angular/core';
import { AbstractControl, FormBuilder, FormGroup } from '@angular/forms';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { race } from 'rxjs';
import { debounceTime, filter, map, take, takeUntil } from 'rxjs/operators';
import { IpxClockComponent } from 'shared/component/forms/ipx-clock/ipx-clock.component';
import { HideEvent } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { TimerService } from '../timer.service';
import { TimerModalService } from './timer-modal.service';

@Component({
  selector: 'timer-modal',
  templateUrl: './timer-modal.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [IpxDestroy]
})
export class TimerModalComponent implements OnInit {
  @Input() timerDetails: any;
  form: FormGroup;
  activityExtendQuery: any;

  @ViewChild('timerClock', { static: false }) timerClock: IpxClockComponent;
  readonly onClose$ = new EventEmitter<boolean>();

  get activity(): AbstractControl {
    return this.form.get('activity');
  }

  get narrativeNo(): AbstractControl {
    return this.form.get('narrativeNo');
  }

  get narrativeText(): AbstractControl {
    return this.form.get('narrativeText');
  }

  get notes(): AbstractControl {
    return this.form.get('notes');
  }

  get timeFormat(): string {
    return this.service.timeFormat;
  }

  constructor(
    readonly bsModalRef: BsModalRef,
    @Self() private readonly destroy$: IpxDestroy,
    private readonly formBuilder: FormBuilder,
    private readonly service: TimerService,
    private readonly modalService: TimerModalService,
    private readonly notificationService: NotificationService,
    private readonly ipxNotificationService: IpxNotificationService) {
    this.activityExtendQuery = this.activitiesFor;
  }

  ngOnInit(): void {
    this.timerDetails = this.makeUiReady(this.timerDetails);
    this.createFormGroup();
  }

  private readonly makeUiReady = (data: any): any => {
    if (!!data) {
      data.start = !!data.start ? new Date(data.start) : null;
    }

    return data;
  };

  private readonly createFormGroup = (): void => {
    const data = this.timerDetails;
    this.form = this.formBuilder.group({
      activity: [!data.activity ? null : { key: data.activityKey, value: data.activity }],
      narrativeNo: [!_.isNumber(data.narrativeNo) ? null : { key: data.narrativeNo, value: data.narrativeTitle, text: data.narrativeText }],
      narrativeText: [!data.narrativeText ? null : data.narrativeText],
      notes: [!data.notes ? null : data.notes]
    });

    this.configureValueChanges();
  };

  private readonly configureValueChanges = (): void => {
    this.activity.valueChanges
      .pipe(debounceTime(400), takeUntil(this.destroy$))
      .subscribe(this.defaultNarrativeFromActivity);

    this.narrativeNo.valueChanges
      .pipe(debounceTime(400), takeUntil(this.destroy$))
      .subscribe(this.defaultNarrativeTextFromNarrativeNo);

    this.narrativeText.valueChanges
      .pipe(debounceTime(400), takeUntil(this.destroy$))
      .subscribe(this.eraseNarrativeNo);
  };

  private readonly defaultNarrativeFromActivity = (selectedActivity: any): void => {
    if (!selectedActivity || !selectedActivity.key) {
      if (!!this.narrativeNo.value) {
        this.narrativeNo.setValue(null, { emitEvent: false });
        this.narrativeText.setValue(null, { emitEvent: false });
        this.narrativeNo.enable();

        return;
      }

      return;
    }

    if (!this.narrativeNo.value && !!this.narrativeText.value) {
      return;
    }

    const activityKey = this.activity.value ? this.activity.value.key : '';
    this.narrativeNo.disable();
    const entryCase = this.timerDetails.caseId;
    const entryDebtor = this.timerDetails.nameId;
    this.modalService.getDefaultNarrativeFromActivity(activityKey, !!entryCase ? entryCase.key : null, !!entryDebtor ? entryDebtor.key : null, _.isNumber(this.timerDetails.staffNameId) ? this.timerDetails.staffNameId : null)
      .subscribe((narrative: any) => {
        this.narrativeNo.setValue(narrative, { emitEvent: false });
        this.narrativeNo.enable();

        if (!!narrative) {
          this.narrativeText.setValue(narrative.text, { emitEvent: false });
        }
      });
  };

  private readonly defaultNarrativeTextFromNarrativeNo = (narrative: any): void => {
    if (!!narrative) {
      this.narrativeText.setValue(narrative.text, { emitEvent: false });
    }
  };

  private readonly eraseNarrativeNo = (): void => {
    this.narrativeNo.setValue(null, { emitValue: false });
  };

  cancel = (): void => {
    this.closeDialog(true);
  };

  saveData = (): void => {
    const data = { ...this.timerDetails, ...this.getData() };

    this.service.saveTimer(data)
      .pipe(take(1), takeUntil(this.destroy$))
      .subscribe(() => {
        this.notificationService.success(null, null, 500);
        this.closeDialog(true);
      });
  };

  private readonly getData = (): any => {
    return {
      entryNo: this.timerDetails.entryNo,
      activity: this.activity.value ? this.activity.value.key : null,
      narrativeText: this.narrativeText.value,
      notes: this.notes.value,
      narrativeNo: this.narrativeNo.value ? this.narrativeNo.value.key : null
    };
  };

  activitiesFor = (query: any): void => {
    const extended = _.extend({}, query, {
      caseId: this.timerDetails ? this.timerDetails.caseKey : null
    });

    return extended;
  };

  deleteTimer = (): void => {
    const deleteConfirmRef = this.ipxNotificationService.openDeleteConfirmModal('accounting.time.recording.deleteTimer', null, false, null);

    const deleteConfirmed$ = deleteConfirmRef.content.confirmed$.pipe(map(() => true));
    const deleteCancelled$ = this.ipxNotificationService.onHide$.pipe(filter((e: HideEvent) => e.isCancelOrEscape), map(() => false));

    race(deleteConfirmed$, deleteCancelled$)
      .pipe(take(1), takeUntil(this.destroy$))
      .subscribe((proceed: boolean) => {
        if (!!proceed) {
          this.service.deleteTimer(this.timerDetails)
            .pipe(take(1), takeUntil(this.destroy$))
            .subscribe(() => {
              this.notificationService.success(null, null, 500);
              this.closeDialog(false);
            });
        }
      });
  };

  stopTimer = (): void => {
    this.service.stopTimer({ ...this.timerDetails, ...this.getData() }, this.timerClock.time)
      .pipe(take(1), takeUntil(this.destroy$))
      .subscribe(() => {
        this.notificationService.success(null, null, 500);
        this.closeDialog(false);
      });
  };

  resetTimer = (): void => {
    this.service.resetTimer({ ...this.timerDetails })
      .pipe(take(1), takeUntil(this.destroy$))
      .subscribe((res: any) => {
        this.notificationService.success();
        const data = this.makeUiReady(res.timeEntry);
        this.timerDetails.start = data.start;
        this.timerClock.resetTimer(data.start);
      });
  };

  private readonly closeDialog = (isTimerRunning?: boolean): void => {
    this.bsModalRef.hide();
    this.onClose$.emit(isTimerRunning);
  };
}