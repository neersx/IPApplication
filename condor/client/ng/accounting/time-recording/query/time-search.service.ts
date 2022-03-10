import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, of, Subject } from 'rxjs';
import { map } from 'rxjs/internal/operators/map';
import { GridPagableData } from 'shared/component/grid/ipx-grid.models';
import { LocaleDatePipe } from 'shared/pipes/locale-date.pipe';
import { DateFunctions } from 'shared/utilities/date-functions';
import * as  _ from 'underscore';
import { ContinuedTimeHelper } from '../helpers/continued-time-helper';
import { TimeEntry, TimeEntryEx } from '../time-recording-model';
import { BatchSelectionDetails, TimeRecordingQueryData } from './time-recording-query-model';

@Injectable()
export class TimeSearchService {
    timeSummary$: Subject<any> = new Subject<any>();
    private _currentTotal = { total: 0 };
    private _lastSearch;
    private readonly _baseApi = 'api/accounting/time/search';

    constructor(private readonly http: HttpClient,
        private readonly continuedTimeHelper: ContinuedTimeHelper,
        private readonly localDatePipe: LocaleDatePipe) { }

    recentEntries$ = (staffNameId: number, queryParams: any): Observable<Array<TimeEntry>> => {
        const criteria = new TimeRecordingQueryData({ staff: { key: staffNameId } });
        const searchParams = {
            q: JSON.stringify(criteria.getServerReady()),
            params: JSON.stringify(this.processFilters(queryParams))
        };

        return this.http.get<Array<TimeEntry>>(`${this._baseApi}/recent-entries`, {
            params: { ...searchParams }
        }).pipe(map((res: any) => {
            if (!res.data || !res.data.data) {

                return [];
            }

            return _.map(res.data.data, (r) => {
                return new TimeEntry(r);
            });
        }));
    };

    runSearch$ = (criteria: TimeRecordingQueryData, queryParams: any): Observable<GridPagableData> => {
        const searchParams = {
            q: JSON.stringify(criteria.getServerReady()),
            params: JSON.stringify(this.processFilters(queryParams))
        };

        return this.http.get<GridPagableData>('api/accounting/time/search', {
            params: { ...searchParams }
        })
            .pipe(map((res: any) => {
                this._lastSearch = searchParams;
                const considerSummary = queryParams.skip === 0;
                if (considerSummary) {
                    this.timeSummary$.next(res.summary);
                    this._currentTotal = res.data.pagination;
                }
                let timeList: Array<TimeEntryEx>;
                timeList = _.map(res.data.data, (item: any) => {

                    return new TimeEntryEx(item);
                });
                this.continuedTimeHelper.updateContinuedFlag(timeList);

                return {
                    data: timeList,
                    pagination: this._currentTotal
                };
            }));
    };

    runFilterMetaSearch$ = (columnField: string): Observable<any> => {
        return this.http.get<Array<any>>(`api/accounting/time/search/filterData/${columnField}`, {
            params: { ...this._lastSearch }
        }).pipe(map((res) => {
            switch (columnField) {
                case 'entryDate':
                    return _.map(res, (r) => {
                        if (!r.description) {
                            return { description: '', code: 'null' };
                        }
                        const key = new Date(r.description);

                        return { description: this.localDatePipe.transform(key, null), code: DateFunctions.toLocalDate(key, true).toISOString() };
                    });
                case 'caseReference':
                case 'name':
                case 'activity':
                    return _.map(res, (r) => {
                        if (!r.code) {
                            r.code = 'null';
                        }

                        return r;
                    });

                default: return res;
            }
        }));
    };

    searchParamData$ = (): Observable<any> => {
        return this.http.get<any>('api/accounting/time/search/view');
    };

    exportSearch$ = (criteria: TimeRecordingQueryData, queryParams: any, exportFormat: string, columns: any, contentId: number): Observable<any> => {
        const searchParams = {
            searchParams: criteria.getServerReady(),
            queryParams: this.processFilters(queryParams),
            exportFormat,
            columns,
            contentId
        };

        return this.http.post('api/accounting/time/search/export', { ...searchParams });
    };

    getSearchParams = (criteria: TimeRecordingQueryData, queryParams: any): any => {
        return { criteria: criteria.getServerReady(), queryParams: this.processFilters(queryParams) };
    };

    deleteEntries = (details: BatchSelectionDetails): any => {
        return this.http.request('delete', 'api/accounting/time/batch/delete', { body: details });
    };

    updateNarrative = (details: BatchSelectionDetails, newNarrative: any): any => {
        return this.http.request('put', 'api/accounting/time/batch/update-narrative', { body: { selectiondetails: details, newNarrative } });
    };

    private readonly processFilters = (queryParams: any): any => {
        _.each(queryParams.filters, (f: any) => {
            if (!!f.value) {
                const values = f.value.split(',');
                if (_.contains(values, 'null')) {
                    f.value = _.without(values, 'null').concat(['']).join(',');
                }
            }
        });

        return queryParams;
    };
}
