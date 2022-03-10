import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { shareReplay } from 'rxjs/operators';

@Injectable()
export class IpxQuestionPicklistService {
    viewData$: Observable<any>;

    constructor(private readonly http: HttpClient) {}

    getViewData = () => {
        this.viewData$ = this.http.get('api/picklists/questions/view').pipe(
            shareReplay(1)
        );
    };
}
