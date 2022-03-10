import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map, tap } from 'rxjs/operators';
import { DateFunctions } from 'shared/utilities/date-functions';
import { TimerSeed } from './time-recording-timer-model';

@Injectable()
export class TimerService {
    private readonly baseTimerUrl = 'api/accounting/timer';
    private readonly baseTimeUrl = 'api/accounting/time';
    private _timeFormat = 'HH:mm:ss';

    get timeFormat(): string {
        return this._timeFormat;
    }

    constructor(private readonly http: HttpClient) { }

    private readonly setTimeFormat = (timeFormat12Hours: boolean, displaySeconds: boolean): void => {
        this._timeFormat = (timeFormat12Hours ? 'hh' : 'HH') + ':mm' + (displaySeconds ? ':ss' : '') + (timeFormat12Hours ? ' a' : '');
    };

    checkCurrentRunningTimers = (): Observable<any> => {
        return this.http.get(`${this.baseTimerUrl}/currentRunningTimer`)
            .pipe(tap((data: any) => this.setTimeFormat(data.timeFormat12Hours, data.displaySeconds)));
    };

    startTimerFor = (caseKey: number): Observable<any> => {
        const timerSeed = new TimerSeed({ startDateTime: new Date(), caseKey });
        timerSeed.startDateTime = DateFunctions.toLocalDate(timerSeed.startDateTime, false);

        return this.http.post(`${this.baseTimerUrl}/start`, timerSeed);
    };

    saveTimer = (timeEntry: any): Observable<any> => {
        return this.saveTimerDetails(timeEntry);
    };

    stopTimer = (timeEntry: any, totalTimeInseconds: number): Observable<any> => {
        timeEntry.totalTime = new Date(1899, 0, 1);
        timeEntry.totalTime.setSeconds(totalTimeInseconds);

        return this.http.put(`${this.baseTimerUrl}/stop`, TimerService.makeServerReady(timeEntry));
    };

    stopAndSaveTimer = (timeEntry: any, totalTimeInseconds: number): Observable<any> => {
        timeEntry.totalTime = new Date(1899, 0, 1);
        timeEntry.totalTime.setSeconds(totalTimeInseconds);

        return this.saveTimerDetails(timeEntry, true);
    };

    private readonly saveTimerDetails = (timeEntry: any, stopTimer = false): Observable<any> => {
        return this.http.put(`${this.baseTimerUrl}/save`, {
            timeEntry: TimerService.makeServerReady(timeEntry),
            stopTimer
        });
    };

    resetTimer = (timeEntry: any): Observable<any> => {
        timeEntry.start = new Date();

        return this.http.put(`${this.baseTimerUrl}/reset`, TimerService.makeServerReady(timeEntry))
            .pipe((map((res: any) => res.response)));
    };

    deleteTimer = (entry: any): Observable<any> => {
        return this.http.request('delete', `${this.baseTimeUrl}/delete`, { body: TimerService.makeServerReady(entry) });
    };

    private static readonly makeServerReady = (timeEntry: any): any => {
        const startDate = timeEntry.start;
        timeEntry.start = DateFunctions.toLocalDate(startDate, false);
        timeEntry.entryDate = DateFunctions.toLocalDate(startDate, true);

        timeEntry.totalTime = !!timeEntry.totalTime ? DateFunctions.toLocalDate(timeEntry.totalTime, false) : null;

        return timeEntry;
    };
}