
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

@Injectable()
export class KendoGridGroupingDemoService extends BehaviorSubject<any> {
    constructor(private readonly httpClient: HttpClient) {
        super(undefined);
    }

    getPagedData$ = (queryParams?): Observable<any> => {
        return this.httpClient
            .get('api/configuration/search/CaseSearch', {
                params: {
                    params: JSON.stringify(queryParams),
                    q: JSON.stringify({ text: '', componentIds: [], tagIds: [] })
                }
            });
    };
}
