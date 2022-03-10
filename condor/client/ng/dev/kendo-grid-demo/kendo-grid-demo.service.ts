
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class KendoGridDemoService extends BehaviorSubject<any> {
    constructor(private readonly httpClient: HttpClient) {
        super(undefined);
    }

    defaultDataSubScribe = (queryParams?): void => {
        this.getData$(queryParams)
            .subscribe(json => super.next(json));
    };

    defaultDataPromise = (queryParams?): Promise<any> =>
        this.getData$(queryParams)
            .toPromise()
            .then((response: any) =>
                response);

    getData$ = (queryParams?): Observable<any> => {
        const q = queryParams || {
            skip: 0,
            take: 5
        };

        return this.httpClient
            .get('api/configuration/jurisdictions/search', {
                params: {
                    params: JSON.stringify(q),
                    q: JSON.stringify({ text: '' })
                }
            });
    };

    getPagedData$ = (queryParams?): Observable<any> => {
        const q = queryParams || {
            skip: 0,
            take: 5
        };

        return this.httpClient
            .get('api/configuration/search', {
                params: {
                    params: JSON.stringify(q),
                    q: JSON.stringify({ text: '', componentIds: [], tagIds: [] })
                }
            });
    };

    getPolicingQueue$ = (queryParams?): Observable<any> => {
        const q = queryParams || {
            skip: 0,
            take: 5
        };

        return this.httpClient
            .get('api/policing/queue/all', {
                params: {
                    params: JSON.stringify(q)
                }
            })
            .pipe(
                map((data: any) => {
                    return data.items;
                })
            );
    };

    getColumnFilterData$ = (column, filtersForColumn, otherFilters): Observable<any> => {

        return this.httpClient
            .get('api/policing/queue/filterData/' + column.field + '/all', {
                params: {
                    columnFilters: JSON.stringify(otherFilters)
                }
            });
        // .pipe(
        //     map((data: any) => {
        //         if (column.field === 'status' || column.field === 'typeOfRequest') {
        //             return data;
        //         }
        //     })
        // );
    };
}
