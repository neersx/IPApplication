import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

@Injectable()
export class CaseSummaryService {
    constructor(private readonly http: HttpClient) { }
    getCaseSummary(caseKey: number): any {
        return this.http.get(
            'api/search/case/' + caseKey.toString() + '/searchsummary'
        );
    }

    getTaskDetailsSummary(key: string): any {
        return this.http.get(
            'api/search/case/' + key + '/taskDetails'
        );
    }
}
