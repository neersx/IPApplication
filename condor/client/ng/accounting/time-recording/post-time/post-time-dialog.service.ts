import { Injectable, OnDestroy } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { Observable, race, ReplaySubject, Subject } from 'rxjs';
import { last, map, take, takeUntil, tap } from 'rxjs/operators';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { LocaleDatePipe } from 'shared/pipes/locale-date.pipe';
import { PostEntryDetails } from '../time-recording-model';
import { PostTimeResponseDlgComponent } from './post-time-response-dlg/post-time-response-dlg.component';
import { PostTimeComponent } from './post-time.component';
import { PostResult } from './post-time.model';
import { PostTimeService } from './post-time.service';

@Injectable()
export class PostTimeDialogService implements OnDestroy {
  private modalRef: any;
  private postPerformed: Subject<boolean>;
  private postPerformed$: Observable<boolean>;
  destroy$: ReplaySubject<any> = new ReplaySubject<any>(1);

  constructor(private readonly modalService: IpxModalService,
    private readonly postTimeService: PostTimeService,
    private readonly ipxNotificationService: IpxNotificationService,
    readonly translate: TranslateService,
    readonly localDatePipe: LocaleDatePipe,
    readonly notificationService: NotificationService
    ) {

    this.postTimeService.postResult$
      .pipe(takeUntil(this.destroy$))
      .subscribe((result: PostResult) => {
        if (result.hasOfficeEntityError && result.rowsPosted === 0) {
          this.ipxNotificationService.openAlertModal('accounting.time.postTime.officeEntityError.title', 'accounting.time.postTime.officeEntityError.message');

          return;
        }
          if (result.hasError && result.rowsPosted === 0) {
            const dateParam = result.error.contextArguments.length > 0 ? new Date(result.error.contextArguments[0]) : null;
            const alert = this.translate.instant(`accounting.errors.${result.error.alertID}`, {value: !!dateParam ? this.localDatePipe.transform(dateParam, null) : null});
            this.ipxNotificationService.openAlertModal('accounting.time.postTime.officeEntityError.title', alert);

            return;
        }
        if (!!result.isBackground) {
            this.notificationService.success(translate.instant('accounting.time.postTime.postInBackground'));

            return;
        }
        this.modalService.openModal(PostTimeResponseDlgComponent, {
          animated: false, ignoreBackdropClick: true, initialState: result
        });
        this.modalService.onHide$
          .pipe(take(1), takeUntil(this.destroy$))
          .subscribe(() => { this.postPerformed.next(true); this.postPerformed.complete(); });
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next(null);
    this.destroy$.complete();
  }

  showDialog = (postEntryDetails: PostEntryDetails = null, canPostForAllStaff: boolean, currentDate: Date): Observable<boolean> => {
    this.modalRef = this.modalService.openModal(PostTimeComponent, { animated: false, ignoreBackdropClick: true, class: 'modal-lg', focus: true, initialState: { postEntryDetails, canPostForAllStaff, currentDate } });

    this.postPerformed = new Subject<boolean>();
    this.postPerformed$ = this.postPerformed.asObservable();

    race(
      this.modalRef.content.postInitiated.pipe(map(() => true)),
      this.modalService.onHide$.pipe(map(() => false)))
      .pipe(take(1), takeUntil(this.destroy$))
      .subscribe((r: any) => {
        if (!r) {
          this.postPerformed.complete();
        }
      });

    return this.postPerformed$.pipe(takeUntil(this.destroy$), last(r => r, false));
  };
}