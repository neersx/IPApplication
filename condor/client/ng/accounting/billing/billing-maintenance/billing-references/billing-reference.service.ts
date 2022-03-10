import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class BillingReferenceService {

  constructor(private readonly http: HttpClient) {
  }
  url = 'api/accounting/billing/bill-presentation';

  getDefaultReferences(caseIds: string, languageId?: number, debtorId: number = null, useRenewalDebtor = false, openItemNo: string = null): Observable<any> {
    const params = {
      caseIds,
      languageId: JSON.stringify(languageId),
      useRenewalDebtor: JSON.stringify(useRenewalDebtor),
      debtorId: JSON.stringify(debtorId)
    };
    if (openItemNo) {
      Object.assign(params, { openItemNo });
    }

    return this.http.get(`${this.url}/references`, {
      params
    });
  }

}
