import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { iif, Observable, of, Subject } from 'rxjs';
import { delay, distinctUntilChanged, map, shareReplay, switchMap, tap, withLatestFrom } from 'rxjs/operators';
import { DateFunctions } from 'shared/utilities/date-functions';
import * as _ from 'underscore';
import { TimeCalculationService } from '../time-calculation.service';
import { TimeGap } from '../time-recording-model';

export interface ITimeGapsService {
  getGaps(userNameId: number, selectedDate: Date, timeRange: any): Observable<any>;
  addEntries(request: any): void;
}
@Injectable()
export class TimeGapsService implements ITimeGapsService {
  baseTimeUrl = 'api/accounting/time';
  gapsDataCache$: Observable<Array<TimeGap>>;
  workingHoursCache$: Observable<WorkingHours>;
  saveWorkingHoursPreference = new Subject<WorkingHours>();

  constructor(private readonly http: HttpClient, private readonly timeCalculationService: TimeCalculationService) {
  }

  private readonly _getGapsFromServer = (userNameId: number, selectedDate: Date): Observable<Array<TimeGap>> => {
    if (!this.gapsDataCache$) {
      this.gapsDataCache$ = this.http.get<Array<TimeGap>>(`${this.baseTimeUrl}/gaps`, {
        params: new HttpParams().set('q', JSON.stringify({ staffNameId: userNameId, selectedDate: this.timeCalculationService.toLocalDate(selectedDate, true) }))
      }).pipe(shareReplay(1));
    }

    return this.gapsDataCache$.pipe(map((res: any) => res.map(data => new TimeGap(data))));
  };

  getWorkingHoursFromServer = (selectedDate: Date): Observable<WorkingHours> => {
    if (!this.workingHoursCache$) {
      this.workingHoursCache$ = this.http.get('api/accounting/time/settings/working-hours')
        .pipe(map((data: any) => new WorkingHours(selectedDate, data)), shareReplay(1));
    }

    return this.workingHoursCache$;
  };

  private readonly _getTimeRange = (timeRange: WorkingHours, selectedDate: Date): Observable<WorkingHours> => {
    return iif(() => !!timeRange && !!timeRange.from && !!timeRange.to, of(timeRange), this.getWorkingHoursFromServer(selectedDate));
  };

  getGaps(userNameId: number, selectedDate: Date, timeRange: WorkingHours): Observable<Array<TimeGap>> {
    return this._getGapsFromServer(userNameId, selectedDate)
      .pipe(withLatestFrom(this._getTimeRange(timeRange, selectedDate)))
      .pipe(map(([data, timeRangeVal]) => {
        const defaultStart = timeRangeVal.from;
        const defaultFinish = timeRangeVal.to;

        const filteredList = [];
        _.each(data, (gap: TimeGap) => {
          if (gap.startTime.getTime() < defaultStart.getTime() && gap.finishTime.getTime() >= defaultStart.getTime()) {
            gap.startTime = new Date(defaultStart);
            if (gap.finishTime.getTime() > defaultFinish.getTime()) {
              gap.finishTime = new Date(defaultFinish);
            }

            gap.recalculateDurationInSeconds();
            if (gap.durationInSeconds > 60) {
              filteredList.push(gap);
            }

            return;
          }

          if (gap.startTime.getTime() >= defaultStart.getTime() && gap.finishTime.getTime() <= defaultFinish.getTime()) {
            filteredList.push(gap);

            return;
          }

          if (gap.startTime.getTime() < defaultFinish.getTime() && gap.finishTime.getTime() > defaultFinish.getTime()) {
            gap.finishTime = new Date(defaultFinish);

            gap.recalculateDurationInSeconds();
            if (gap.durationInSeconds > 60) {
              filteredList.push(gap);
            }
          }
        });

        return filteredList;
      }));
  }

  addEntries(request: Array<any>): Observable<any> {
    let data = JSON.parse(JSON.stringify(request));
    data = data.map((gap: any) => {
      gap.startTime = DateFunctions.toLocalDate(new Date(gap.startTime));
      gap.finishTime = DateFunctions.toLocalDate(new Date(gap.finishTime));

      return gap;
    });

    return this.http.post(`${this.baseTimeUrl}/save-gaps`, data).pipe(tap(() => { this.gapsDataCache$ = null; }));
  }

  preferenceSaved$ = (): Observable<boolean> => {
    return this.saveWorkingHoursPreference.pipe(
      distinctUntilChanged(),
      delay(5000),
      switchMap((range: WorkingHours) => { return this.http.post('api/accounting/time/settings/update/working-hours', range.getServerReadyString()); }),
      map(() => true));
  };

  saveWorkingHours = (timeRange: WorkingHours) => {
    this.saveWorkingHoursPreference.next(timeRange);
  };
}

export class WorkingHours {
  from: Date;
  to: Date;

  constructor(selectedDate: Date, data: any) {
    const fromTime = DateFunctions.convertSecondsToTime(!!data && !!data.fromSeconds ? data.fromSeconds : 0);
    this.from = DateFunctions.setTimeOnDate(new Date(selectedDate), fromTime.hours, fromTime.mins, fromTime.secs);

    const toTime = DateFunctions.convertSecondsToTime(!!data && !!data.toSeconds ? data.toSeconds : 24 * 60 * 60 - 1);
    this.to = DateFunctions.setTimeOnDate(new Date(selectedDate), toTime.hours, toTime.mins, toTime.secs);
  }

  getServerReadyString = (): any => {
    return {
      fromSeconds: DateFunctions.getSeconds(this.from),
      toSeconds: DateFunctions.getSeconds(this.to)
    };
  };
}