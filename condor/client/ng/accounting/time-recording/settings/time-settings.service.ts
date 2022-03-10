import { HttpClient } from '@angular/common/http';
import { Injectable, OnDestroy } from '@angular/core';
import { Observable, Subject } from 'rxjs';
import { tap } from 'rxjs/operators';
import * as _ from 'underscore';
import { EnquiryViewData, TimeRecordingPermissions, TimeRecordingSettings, UserTaskSecurity } from '../time-recording-model';
import { UserInfoService } from './user-info.service';

export interface ITimeSettingsService {
    getViewData$(): Observable<any>;
}

@Injectable()
export class TimeSettingsService implements ITimeSettingsService, OnDestroy {
    localCurrencyCode: string;
    baseTimeUrl = 'api/accounting/time';
    displaySeconds = false;
    is12HourFormat = false;
    continueFromCurrentTime = false;
    unitsPerHour = 10;
    roundUpUnits: boolean;
    considerSecsInUnitsCalc: boolean;
    enabledUnitsForContinuedTime: boolean;
    timeFormat = 'HH:mm:ss';
    timeEmptyForNewEntries: boolean;
    valueTimeOnEntry: boolean;
    timePickerInterval?: number;
    durationPickerInterval?: number;
    wipSplitMultiDebtor: boolean;
    displaySecondsOnChange: Subject<boolean> = new Subject<boolean>();
    canFunctionAsOtherStaff: Subject<boolean> = new Subject<boolean>();
    userTaskSecurity: UserTaskSecurity;

    constructor(readonly http: HttpClient, readonly userInfo: UserInfoService) {
    }

    ngOnDestroy(): void {
        this.displaySecondsOnChange.complete();
    }

    changeSettings(displaySeconds: boolean, is12HourFormat: boolean): void {
        this.displaySeconds = displaySeconds;
        this.is12HourFormat = is12HourFormat;
        this.evaluateTimeFormat(this.displaySeconds, this.is12HourFormat);
        this.displaySecondsOnChange.next(this.displaySeconds);
    }

    getViewData$(caseId?: number, staffId?: number): Observable<EnquiryViewData> {
        return this.http.get(`${this.baseTimeUrl}/view` + (caseId != null ? `/${caseId}` : '' + (staffId != null ? `/staff/${staffId}` : '')))
            .pipe(tap((response: EnquiryViewData) => {
                this._initializeProperties(response.settings);
                this.localCurrencyCode = response.settings.localCurrencyCode;

                const permissions: TimeRecordingPermissions = {
                    canRead: response.userInfo.isStaff,
                    canInsert: response.userInfo.isStaff,
                    canUpdate: response.userInfo.isStaff,
                    canDelete: response.userInfo.isStaff,
                    canPost: response.userInfo.isStaff,
                    canAdjustValue: response.userInfo.isStaff && response.userInfo.canAdjustValues,
                    canAddTimer: response.userInfo.isStaff
                };
                this.userInfo.setUserDetails({ staffId: response.userInfo.nameId, displayName: response.userInfo.displayName, isStaff: response.userInfo.isStaff, permissions });
                this.canFunctionAsOtherStaff.next(response.userInfo.canFunctionAsOtherStaff);

                this.userTaskSecurity = new UserTaskSecurity({ maintainPostedTime: { edit: response.userInfo.maintainPostedTimeEdit, delete: response.userInfo.maintainPostedTimeDelete } });
            }));
    }

    private readonly _initializeProperties = (timeRecordingSettings: TimeRecordingSettings): void => {
        this.changeSettings(timeRecordingSettings.displaySeconds, timeRecordingSettings.timeFormat12Hours);
        this.continueFromCurrentTime = timeRecordingSettings.continueFromCurrentTime;
        this.unitsPerHour = timeRecordingSettings.unitsPerHour;
        this.roundUpUnits = timeRecordingSettings.roundUpUnits;
        this.considerSecsInUnitsCalc = timeRecordingSettings.considerSecsInUnitsCalc;
        this.enabledUnitsForContinuedTime = timeRecordingSettings.enableUnitsForContinuedTime;
        this.wipSplitMultiDebtor = timeRecordingSettings.wipSplitMultiDebtor;
        this.timeEmptyForNewEntries = timeRecordingSettings.timeEmptyForNewEntries;
        this.valueTimeOnEntry = timeRecordingSettings.valueTimeOnEntry;
        this.timePickerInterval = timeRecordingSettings.timePickerInterval;
        this.durationPickerInterval = timeRecordingSettings.durationPickerInterval;
    };

    evaluateTimeFormat(showSeconds: boolean, is12Hours: boolean): void {
        let hours = 'HH';
        let amPm = '';
        if (is12Hours) {
            hours = 'hh';
            amPm = ' a';
        }

        let seconds = '';
        if (showSeconds) {
            seconds = ':ss';
        }

        this.timeFormat = hours + ':mm' + seconds + amPm;
    }
}