import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { BillingCaseItems, CaseRequest } from '../case-debtor.model';

@Injectable()
export class CaseDebtorService {

    constructor(private readonly http: HttpClient) {
    }
    url = 'api/accounting/billing';

    getOpenItemCases = (itemEntityId: number, itemTransactionId: number): Observable<Array<BillingCaseItems>> => {

        return this.http.get<Array<BillingCaseItems>>(`${this.url}/open-item/cases`, {
            params: {
                itemEntityId: JSON.stringify(itemEntityId),
                itemTransactionId: JSON.stringify(itemTransactionId ? itemTransactionId : 0)
            }
        }).pipe(map((res: any) => {
            if (res.CaseList) {

                return res.CaseList;
            }
        }));
    };

    getCases = (req: CaseRequest): Observable<any> => {

        return this.http.post<any>(`${this.url}/cases/`, req);
    };

    getCaseDebtors(caseId: number): Observable<any> {
        return this.http.get(`${this.url}/cases/case-debtors`, {
            params: {
                caseId: JSON.stringify(caseId)
            }
        });
    }

    getDebtors(type?: string, caseId?: number, caseListId?: number, caseIds?: string, action?: string, entityId?: number, raisedByStaffId: number = null, debtorNameId: number = null, useSendBillsTo = false, useRenewalDebtor = false, billDate: any = null): Observable<any> {
        let params: any = {
            type,
            caseId: JSON.stringify(caseId),
            entityId: JSON.stringify(entityId),
            action,
            raisedByStaffId: JSON.stringify(raisedByStaffId),
            debtorNameId: JSON.stringify(debtorNameId),
            useSendBillsTo: JSON.stringify(useSendBillsTo),
            useRenewalDebtor: JSON.stringify(useRenewalDebtor),
            billDate: JSON.stringify(billDate)
        };
        if (caseListId !== null) {
            params = {
                ...params, ...{
                    caseListId: JSON.stringify(caseListId)
                }
            };

            return this.getCaseListDebtors(params);
        }
        if (caseIds) {
            params.caseIds = caseIds;
        }

        return this.http.get(`${this.url}/debtors/`, {
            params
        });
    }

    getOpenItemDebtors(entityId: number, transactionId: number, raisedByStaffId?: boolean): Observable<any> {
        return this.http.get(`${this.url}/open-item/debtors/`, {
            params: {
                entityId: JSON.stringify(entityId),
                transactionId: JSON.stringify(transactionId),
                raisedByStaffId: JSON.stringify(raisedByStaffId)
            }
        });
    }

    getCaseListDebtors(obj: any): any {
        return this.http.get(`${this.url}/debtors/`, {
            params: obj
        });
    }

    getChangedDebtors = (req: any, request: any): Observable<any> => {

        return this.http.post<any>(`${this.url}/debtors/`, req, {
            params: {
                caseId: JSON.stringify(request.caseId),
                entityId: JSON.stringify(request.entityId),
                action: request.action,
                billDate: request.billDate,
                useRenewalDebtor: JSON.stringify(request.useRenewalDebtor)
            }
        });
    };

    getDebtorCopiesToDetails = (debtorNameId: number, copyToNameId: number): Observable<any> => {

        return this.http.get<any>(`${this.url}/debtor/copies`, {
            params: {
                debtorNameId: JSON.stringify(debtorNameId),
                copyToNameId: JSON.stringify(copyToNameId)
            }
        });
    };
}
