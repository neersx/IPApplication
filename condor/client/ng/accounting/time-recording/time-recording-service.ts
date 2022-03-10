import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, OnDestroy } from '@angular/core';
import { TimerSeed } from 'accounting/time-recording-widget/time-recording-timer-model';
import { KeepOnTopNotesViewService, KotViewProgramEnum } from 'rightbarnav/keep-on-top-notes-view.service';
import { RightBarNavService } from 'rightbarnav/rightbarnav.service';
import { BehaviorSubject, merge, Observable, of, Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged, map, switchMap } from 'rxjs/operators';
import * as _ from 'underscore';
import { ContinuedTimeHelper } from './helpers/continued-time-helper';
import { TimeOverlapsHelper } from './helpers/time-overlaps-helper';
import { Period, TimeEntry, TimeEntryEx, TimeRecordingPermissions, TimerEntries, WipStatusEnum } from './time-recording-model';

export interface ITimeRecordingService {
    getTimeList(data: any, queryParams: any): any;
    saveTimeEntry(data: TimeEntry): any;
    updateTimeEntry(data: TimeEntry): any;
    evaluateTime(entryDate: Date, entryNo: number, inputValues: TimeEntry): void;
    getUserPermissions(staffId: number): Observable<TimeRecordingPermissions>;
    startTimer(timerSeed: TimerSeed): Observable<TimerEntries>;
    stopTimer(data: TimeEntry): Observable<TimeEntryEx>;
    saveTimer(data: TimeEntry): Observable<TimeEntryEx>;
    getRowIdFor(entryNo: number): number;
    getTimeEntryFromList(entryNo: number): TimeEntryEx;
    getOpenPeriods(): Observable<Array<Period>>;
}

@Injectable()
export class TimeRecordingService implements ITimeRecordingService, OnDestroy {
    viewData: { displaySeconds: boolean; localCurrencyCode: string };
    rowSelected = new BehaviorSubject(null);
    rowSelectedForKot = new BehaviorSubject(null);
    rowSelectedInTimeSearch = new BehaviorSubject(null);
    timeList: Array<TimeEntryEx>;
    localCurrencyCode: string;
    viewTotals: any;
    rateMandatory: boolean;

    private readonly recordUpdated = new Subject<void>();

    private readonly baseTimeUrl = 'api/accounting/time';
    private readonly baseTimerUrl = 'api/accounting/timer';
    private readonly basePostedUrl = 'api/accounting/posted-time';
    timeValuationRequest: Subject<TimeEntry>;

    constructor(readonly http: HttpClient, readonly continuedTimeHelper: ContinuedTimeHelper,
        private readonly rightBarNavService: RightBarNavService,
        private readonly kotViewService: KeepOnTopNotesViewService,
        private readonly timeOverlapsHelper: TimeOverlapsHelper) {
        this._configuretimeValuationRequest();
    }

    ngOnDestroy(): void {
        this.recordUpdated.complete();
        this.timeValuationRequest.complete();
    }

    onRecordUpdated(): Observable<void> {
        return this.recordUpdated.asObservable();
    }

    getUserPermissions(staffId: number): Observable<TimeRecordingPermissions> {
        if (staffId == null) {
            return of(new TimeRecordingPermissions());
        }

        return this.http.get<TimeRecordingPermissions>(`${this.baseTimeUrl}/permissions/${staffId.toString()}`);
    }

    getRowIdFor(entryNo: number): number {
        return _.findIndex(this.timeList, { entryNo });
    }

    getTimeList(data: any, queryParams: any): any {
        return this.http.get(`${this.baseTimeUrl}/list`, {
            params: new HttpParams().set('q', JSON.stringify(data)).set('params',
                JSON.stringify(queryParams))
        })
            .pipe(map((res: any) => {
                this.viewTotals = res.totals;
                let i = 0;
                this.timeList = _.map(res.data.data, (item: any) => {
                    item.localCurrencyCode = this.localCurrencyCode;
                    item.rowId = i;
                    item.isUpdated = item.entryNo === data.updatedEntryNo;
                    item.durationOnly = (!item.start && !item.finish);
                    i++;

                    return new TimeEntryEx(item);
                });
                this.continuedTimeHelper.updateContinuedFlag(this.timeList);
                this.timeOverlapsHelper.updateOverlapStatus(this.timeList);

                return this.timeList;
            }));
    }

    saveTimeEntry(data: TimeEntry): any {
        return this.http.post(`${this.baseTimeUrl}/save`, data);
    }

    deleteTimeEntry(dataItem: TimeEntryEx): any {
        const isContinued = !!dataItem.parentEntryNo || !!dataItem.childEntryNo;

        return this.http.request('delete', `${dataItem.isPosted ? this.basePostedUrl : this.baseTimeUrl}/${isContinued ? 'delete-from-chain' : 'delete'}`, { body: dataItem });
    }

    deleteContinuedChain(dataItem: TimeEntryEx): any {
        return this.http.request('delete', `${dataItem.isPosted ? this.basePostedUrl : this.baseTimeUrl}/delete-chain`, { body: dataItem });
    }

    getViewTotals(): any {
        return this.viewTotals;
    }

    toLocalDate(dateTime: Date, dateOnly?: boolean): Date {
        if (dateTime instanceof Date) {
            return new Date(Date.UTC(dateTime.getFullYear(), dateTime.getMonth(), dateTime.getDate(), dateOnly ? 0 : dateTime.getHours(), dateOnly ? 0 : dateTime.getMinutes(), dateOnly ? 0 : dateTime.getSeconds()));
        }

        return null;
    }

    getDefaultActivityFromCase(caseKey: number): Observable<any> {
        return this.http.get(`${this.baseTimeUrl}/activities/${caseKey}`);
    }

    getDefaultNarrativeFromActivity(activityKey: string, caseKey?: number, debtorKey?: number, staffNameId?: number): Observable<any> {
        return this.http.get(`${this.baseTimeUrl}/narrative`,
            {
                params:
                {
                    activityKey,
                    caseKey: caseKey != null ? caseKey.toString() : null,
                    debtorKey: (caseKey == null && debtorKey != null ? debtorKey.toString() : null),
                    staffNameId: staffNameId != null ? staffNameId.toString() : null
                }
            });
    }

    updateTimeEntry(data: TimeEntry): any {
        const currentEntry = _.findWhere(this.timeList, { entryNo: data.entryNo });
        data.parentEntryNo = !!currentEntry ? currentEntry.parentEntryNo : null;

        return this.http.put(data.isPosted ? `${this.basePostedUrl}/update` : `${this.baseTimeUrl}/update`, data);
    }

    updateDate(newDate: Date, entry: TimeEntryEx): Observable<any> {
        const data = { ...entry.makeServerReady() };
        data.entryDate = this.toLocalDate(newDate, true);

        return this.http.put(`${entry.isPosted ? this.basePostedUrl : this.baseTimeUrl}/updateDate`, data);
    }

    evaluateTime(entryDate: Date, entryNo: number, inputValues: TimeEntry): void {
        const entry = this.getTimeEntryFromList(entryNo);
        const input = new TimeEntry({ ...entry, ...inputValues, entryDate: this.toLocalDate(entryDate, true), timeCarriedForward: !!entry.timeCarriedForward ? this.toLocalDate(entry.timeCarriedForward) : null });
        this.timeValuationRequest.next(input);
    }

    _configuretimeValuationRequest(): void {
        this.timeValuationRequest = new Subject<TimeEntry>();
        this.timeValuationRequest
            .pipe(debounceTime(100), switchMap((entry) => {
                if ((!entry.nameKey && !entry.caseKey) || !entry.elapsedTimeInSeconds || (entry.activity == null)) {
                    const emptyValuation = {
                        localValue: null,
                        localDiscount: null,
                        foreignValue: null,
                        foreignDiscount: null,
                        chargeOutRate: null,
                        entryNo: entry.entryNo
                    };

                    return of(emptyValuation);
                }

                return this.http.get<TimeEntry>(`${this.baseTimeUrl}/evaluateTime`, {
                    params: {
                        timeEntry: JSON.stringify(entry)
                    }
                });
            }))
            .subscribe((updatedValues: TimeEntry) => {
                this._applyNewData(updatedValues.entryNo, _.pick(updatedValues, 'localValue', 'localDiscount', 'foreignValue', 'foreignDiscount', 'chargeOutRate', 'debtorSplits'));
                this.recordUpdated.next(null);
            });
    }

    _applyNewData(entryNo: number, updates: any): void {
        const e = this.getTimeEntryFromList(entryNo);
        if (e != null) {
            Object.assign(e, updates);
        }
    }

    getTimeEntryFromList(entryNo: number): TimeEntryEx {
        return this.isSavedEntry(entryNo) ?
            _.findWhere(this.timeList, { entryNo })
            : this.timeList[0];
    }

    startTimer(timerSeed: TimerSeed, isContinued?: boolean): Observable<TimerEntries> {
        return this.http.post<TimerEntries>(`${this.baseTimerUrl}/${isContinued ? 'continue' : 'start'}`, timerSeed)
        .pipe(map((res: any) => {
            const timerInfo = new TimerEntries(res);
            this._applyNewData(timerInfo.stoppedTimer.entryNo, { ...res.stoppedTimer, isTimer: false });

            return timerInfo;
        }));
    }

    stopTimer(data: TimeEntry): Observable<TimeEntryEx> {
        return this.http.put<TimeEntryEx>(`${this.baseTimerUrl}/stop`, data)
            .pipe(map((res: any) => {
                const timeEntry = new TimeEntryEx(res.response.timeEntry);
                this._applyNewData(res.response.entryNo, { ...timeEntry, isTimer: false });

                return timeEntry;
            }));
    }

    saveTimer(data: TimeEntry, stopTimer = false): Observable<TimeEntryEx> {
        return this.http.put<TimeEntryEx>(`${this.baseTimerUrl}/save`, {
            timeEntry: data,
            stopTimer
        }).pipe(map((res: any) => {
            const timeEntry = new TimeEntryEx(res.response.timeEntry);
            this._applyNewData(res.response.entryNo, { ...timeEntry });

            return timeEntry;
        }));
    }

    resetTimerEntry(data: TimeEntry): any {
        return this.http.put(`${this.baseTimerUrl}/reset`, data);
    }

    setLastChildStatus(entryNo: number, isLastChild: boolean): void {
        const parentEntry = this.timeList.find((item: TimeEntryEx) => { return item.entryNo === entryNo && this.isSavedEntry(item.parentEntryNo) && item.isLastChild === !isLastChild; });
        if (parentEntry) {
            parentEntry.isLastChild = isLastChild;
        }
    }

    isSavedEntry(entryNo: number): boolean {
        return entryNo === 0 || !!entryNo;
    }

    canPostedEntryBeEdited(entryNo: number, staffId: number): Observable<WipStatusEnum> {
        return this.http.get<WipStatusEnum>(`api/accounting/warnings/editableStatus/${entryNo}/${staffId}`);
    }

    getOpenPeriods(): Observable<Array<Period>> {
        return this.http.get<Array<Period>>(`${this.basePostedUrl}/openPeriods`)
            .pipe(map((res: any) => { return !res ? new Array<Period>() : _.map(res, (p) => { return new Period(p); }); }));
    }

    kot = merge(this.rowSelectedForKot, this.rowSelectedInTimeSearch);

    showKeepOnTopNotes(): any {
        this.kot.pipe(
            debounceTime(300),
            distinctUntilChanged(),
            switchMap(selected => {
                this.rightBarNavService.registerKot(null);
                if (selected && selected.id) {
                    return this.kotViewService.getKotForCaseView(selected.id, KotViewProgramEnum.Time, selected.type);
                }

                return of(null);
            })
        ).subscribe(res => {
            if (res) {
                this.rightBarNavService.registerKot(res.result);
            }
        });
    }
}