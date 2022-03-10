import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

export interface IAgedTotalsService {
    getWipData(caseKey): any;
    getAgedReceivables(nameKey): any;
}

@Injectable()
export class AgedTotalsService implements IAgedTotalsService {
    constructor(private readonly http: HttpClient) { }

    getWipData(caseKey: number): any {
        return this.http
            .get('api/accounting/' + caseKey.toString() + '/agedWipBalances');
    }

    getAgedReceivables(nameKey: number): any {
        return this.http
            .get('api/accounting/name/' + nameKey.toString() + '/agedReceivableBalances');
    }
}
