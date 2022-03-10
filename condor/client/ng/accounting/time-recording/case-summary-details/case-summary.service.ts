import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
export interface ICaseSummaryService {
    getCaseSummary(caseKey): any;
    getCaseFinancials(caseKey): any;
}

@Injectable()
export class CaseSummaryService implements ICaseSummaryService {
    constructor(private readonly http: HttpClient) { }
    getCaseSummary(caseKey: number): any {
        return this.http.get(
            'api/accounting/time/' + caseKey.toString() + '/summary'
        );
    }

    getCaseFinancials(caseKey: number): any {
        return this.http.get(
            'api/accounting/time/' + caseKey.toString() + '/financials'
        );
    }
}
