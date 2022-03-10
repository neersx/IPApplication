import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { AbstractControl, FormControl, FormGroup, Validators } from '@angular/forms';
import { BehaviorSubject, Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged, distinctUntilKeyChanged, map, take, takeLast, takeUntil } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { TimeSettingsService } from '../settings/time-settings.service';
import { UserInfoService } from '../settings/user-info.service';
import { UserIdAndPermissions } from '../time-recording-model';
import { TimeRecordingHeader, TimeRecordingPermissions, TimeRecordingService } from '../time-recording.namespace';

@Component({
    selector: 'time-recording-header',
    templateUrl: 'time-recording-header.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class TimeRecordingHeaderComponent implements OnInit, AfterViewInit, OnDestroy {
    private readonly _unsubscribe$ = new Subject<void>();
    private readonly staffDetails = { staffId: null, displayName: null, isStaff: null };
    displaySeconds: boolean;
    form: FormGroup;
    staffName: string;
    canFunctionAsOtherStaff?: boolean;
    private readonly _isUserAuthorised = new BehaviorSubject<boolean>(true);

    @Input() headerInfo: TimeRecordingHeader;
    @Input() defaultedStaff?: { key: number, displayName: string };

    get selectedName(): AbstractControl {
        return this.form.get('selectedName');
    }

    constructor(
        private readonly settingsService: TimeSettingsService,
        private readonly cdRef: ChangeDetectorRef,
        private readonly userInfo: UserInfoService,
        private readonly notificationService: IpxNotificationService,
        private readonly timeService: TimeRecordingService) {
    }

    ngOnDestroy(): void {
        this._unsubscribe$.next();
        this._unsubscribe$.complete();
    }

    ngAfterViewInit(): void {
        this._isUserAuthorised
            .pipe(takeUntil(this._unsubscribe$), distinctUntilChanged())
            .subscribe(this.onUserAuthorizationChange.bind(this));

        this.settingsService.displaySecondsOnChange
            .pipe(takeUntil(this._unsubscribe$))
            .subscribe((value) => {
                this.displaySeconds = value;
                this.cdRef.detectChanges();
            });
    }

    ngOnInit(): void {
        this.form = new FormGroup({
            selectedName: new FormControl({ key: null }, { validators: Validators.required, updateOn: 'change' })
        });

        this.settingsService.canFunctionAsOtherStaff
            .pipe(takeUntil(this._unsubscribe$))
            .subscribe((value) => {
                this.canFunctionAsOtherStaff = value;
                this.cdRef.detectChanges();
                this.userInfo.userDetails$
                    .pipe(take(1))
                    .subscribe(this.initLoggedInUser.bind(this));
            });
    }

    initLoggedInUser(user: UserIdAndPermissions): void {
        this.staffName = user.displayName;
        const selectedName = user ? { key: user.staffId, displayName: user.displayName } : { key: null };
        if (!!user.isStaff) {
            this.selectedName.setValue(selectedName, { emitEvent: false });
            this.selectedName.markAsPristine();
            this.cdRef.detectChanges();
            this.handleSelectedNameValueChange();

            if (this.canFunctionAsOtherStaff && !!this.defaultedStaff && this.defaultedStaff.key !== selectedName.key) {
                this.selectedName.setValue(this.defaultedStaff);
            }
        } else {
            this.timeService.getUserPermissions(user.staffId)
                .pipe(takeLast(1))
                .subscribe(this.onPermissionsRecieved.bind(this));
            this.handleSelectedNameValueChange();
        }
    }

    handleSelectedNameValueChange(): void {
        this.selectedName.valueChanges
            .pipe(takeUntil(this._unsubscribe$),
                debounceTime(100),
                map((v) => {
                    if (!!v) { return v; }

                    this._isUserAuthorised.next(true);
                    this.staffDetails.staffId = null;
                    this.staffDetails.displayName = null;
                    this.userInfo.setUserDetails({ ...this.staffDetails, permissions: null });

                    return { key: null, displayName: null };
                }),
                distinctUntilKeyChanged('key'))
            .subscribe((newVal) => {
                if (_.isNumber(newVal.key)) {
                    this.staffDetails.staffId = newVal.key;
                    this.staffDetails.displayName = newVal.displayName;
                    this.timeService.getUserPermissions(newVal.key)
                        .pipe(takeLast(1))
                        .subscribe(this.onPermissionsRecieved.bind(this));
                }
            });
    }

    onPermissionsRecieved(permissions: TimeRecordingPermissions): void {
        this._isUserAuthorised.next(true);
        if (!permissions || !permissions.canRead) {
            this._isUserAuthorised.next(false);
        }

        this.userInfo.setUserDetails({ ...this.staffDetails, permissions });
    }

    onUserAuthorizationChange(newValue: boolean): void {
        if (!!newValue) {
            this.selectedName.updateValueAndValidity({ onlySelf: true, emitEvent: false });

            return;
        }
        this.notificationService.openAlertModal('', '', [!!this.staffDetails.isStaff ? 'accounting.time.recording.accessDeniedForSelectedStaff' : 'accounting.time.recording.accessDeniedForNonStaff']);
        this.selectedName.setErrors({ 'timeRecording.accessDeniedForNonStaff': true });
        this.cdRef.detectChanges();
    }
}