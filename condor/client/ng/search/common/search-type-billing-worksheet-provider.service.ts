import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable()
export class SearchTypeBillingWorksheetProviderService {

  constructor(readonly http: HttpClient) { }

  getReportProviderInfo = (): Observable<any> => {
    return this.http.get('api/reports/provider');
  };

  genrateBillingWorkSheet = (request: any): Observable<any> => {
    return this.http.post('api/reports/billingworksheet', request);
  };
}
