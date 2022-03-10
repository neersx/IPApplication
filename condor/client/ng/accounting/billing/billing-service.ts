import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { EntityOldNewValue } from './billing.model';

@Injectable()
export class BillingService {
    constructor(private readonly http: HttpClient) { }
    url = 'api/accounting/billing';
    openItemData$ = new BehaviorSubject<any>(null);
    reasonList$ = new BehaviorSubject<any>(null);
    currentAction$ = new BehaviorSubject<any>(null);
    currentLanguage$ = new BehaviorSubject<any>(null);
    revertChanges$ = new BehaviorSubject<EntityOldNewValue>(null);
    copiesToCount$ = new BehaviorSubject<any>(null);
    originalDebtorList$ = new BehaviorSubject<any>(null);
    billSettings$ = new BehaviorSubject<any>(null);
    entityChange$ = new BehaviorSubject<any>(null);

    getSettings$ = (): Observable<any> => {
        return this.http.get<any>(this.url + '/settings?scope=site,user');
    };

    getBillSettings$ = (debtorId?: number, caseId?: number, entityId: number = null, action: string = null): Observable<any> => {
        return this.http.get<any>(`${this.url}/settings`, {
            params: {
                scope: 'bill',
                debtorId: JSON.stringify(debtorId),
                caseId: JSON.stringify(caseId),
                entityId: JSON.stringify(entityId),
                action
            }
        });
    };

    getOpenItem$ = (itemType: number, entityId: number, openItemNo: string) => {
        if (entityId && openItemNo) {
            return this.http.get<any>(this.url + '/open-item?itemEntityId=' + entityId + '&openItemNo=' + openItemNo);
        }

        return this.http.get<any>(this.url + '/open-item?itemType=' + itemType);
    };

    setValidAction = (dataRow: any) => {
        if (!dataRow.OpenAction) { return; }
        this.http.post<any>(this.url + '/valid-action', {
            caseTypeCode: dataRow.CaseTypeCode,
            countryCode: dataRow.CountryCode,
            propertyTypeCode: dataRow.PropertyType,
            actionCode: dataRow.OpenAction
        }).subscribe((response) => {
            const validCombinationForm = {
                caseType: { code: dataRow.CaseTypeCode, value: dataRow.CaseTypeDescription },
                jurisdiction: { code: dataRow.CountryCode, value: dataRow.Country },
                propertyType: { code: dataRow.PropertyType, value: dataRow.PropertyTypeDescription },
                openAction: response !== null ? { key: response.Key, code: response.Code, value: response.Value } : {}
            };
            this.currentAction$.next(validCombinationForm);
        });
    };

    clearValidAction = () => {
        this.currentAction$.next(null);
    };
}