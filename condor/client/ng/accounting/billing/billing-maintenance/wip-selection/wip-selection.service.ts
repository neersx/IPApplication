import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable()
export class WipSelectionService {

    constructor(private readonly http: HttpClient) { }
    url = 'api/accounting/billing';

    getAvailableWip = (itemEntityId: number, itemDate: Date, debtorKey: number, caseIds: Array<number>, staffId: number, itemType: number): Observable<Array<any>> => {

        return this.http.post<Array<any>>(`${this.url}/wip-selection`, {
            itemEntityId,
            debtorId: debtorKey,
            caseIds,
            raisedByStaffId: staffId,
            itemType,
            itemDate
        });
    };

    getBillAvailableWip = (itemEntityId: number, itemDate: Date, itemType: number, itemTransactionId: number): Observable<Array<any>> => {

        return this.http.post<Array<any>>(`${this.url}/wip-selection`, {
            itemEntityId,
            itemTransactionId,
            itemType,
            itemDate
        });
    };
}
