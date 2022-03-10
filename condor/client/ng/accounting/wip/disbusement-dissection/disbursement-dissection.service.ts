import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class DisbursementDissectionService {
    constructor(private readonly http: HttpClient) { }
    url = 'api/accounting/wip-disbursements';
    isAddAnotherChecked = new BehaviorSubject<boolean>(false);
    allDefaultWips: Array<any> = [];

    getSupportData$ = (): Observable<any> => {
        return this.http.get<any>(this.url + '/view-support');
    };

    validateItemDate(date: any): any {
        return this.http.get(`${this.url}/validate`, {
            params: {
                itemDate: date.toString()
            }
        });
    }

    getDefaultWipItems$ = (caseKey?: number): Observable<any> => {
        return this.http.get<any>(`${this.url}/wip-defaults/`, {
            params: {
                caseKey: caseKey.toString()
            }
        });
    };

    getDefaultWipCost$ = (wipCostParams: any): Observable<any> => {
        return this.http.post<any>(`${this.url}/wip-costing/`, wipCostParams).pipe(map(res => {
            res.nameKey = res.caseKey != null ? null : res.nameKey;
            res.useSuppliedValues = !res.CurrencyCode && res.localValueBeforeMargin != null && res.foreignValueBeforeMargin != null;
            res.localValue = res.localValueBeforeMargin;
            res.foreignValue = res.foreignValueBeforeMargin;

            return res;
        }));
    };

    getDefaultNarrativeFromActivity(activityKey: string, caseKey?: number, debtorKey?: number, staffNameId?: number): Observable<any> {
        return this.http.get(`${this.url}/narrative`,
            {
                params:
                {
                    activityKey,
                    caseKey: caseKey != null ? caseKey.toString() : null,
                    debtorKey: (caseKey == null && debtorKey != null ? debtorKey.toString() : null),
                    staffNameId: staffNameId != null ? staffNameId.toString() : null
                }
            });
    }

    submitDisbursement = (request: any): Observable<any> => {
        return this.http.post<any>(`${this.url}/`, request);
    };
}