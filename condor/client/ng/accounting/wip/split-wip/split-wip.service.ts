import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { SplitWipData } from './split-wip.model';

@Injectable()
export class SplitWipService {
  constructor(private readonly http: HttpClient) { }
  url = 'api/accounting/wip-adjustments';

  getItemForSplitWip$ = (entityKey: number, transKey: number, wipSeqKey: number): Observable<SplitWipData> => {
    return this.http.get<SplitWipData>(`${this.url}/split-item`, {
      params: {
        entityKey: entityKey.toString(),
        transKey: transKey.toString(),
        wipSeqKey: wipSeqKey.toString()
      }
    });
  };

  getWipSupportData$ = (): Observable<any> => {
    return this.http.get<any>(this.url + '/view-support');
  };

  hasMultipleDebtors$ = (caseKey: number): Observable<boolean> => {
    return this.http.get<boolean>(`${this.url}/case-has-multiple-debtors`, {
      params: {
        caseId: caseKey.toString()
      }
    });
  };

  getDefaultWipItems$ = (caseKey?: number, activityKey?: string): Observable<any> => {
    return this.http.get<any>(`${this.url}/wip-defaults/`, {
      params: {
        caseKey: caseKey.toString(),
        activityKey
      }
    });
  };

  getStaffProfitCenter(nameKey: number): any {
    return this.http.get<any>(`${this.url}/staff-profit-centre/`, {
      params: {
        nameKey: nameKey.toString()
      }
    });

  }

  requestForSplitItem$ = (request: any): Observable<any> => {
    return this.http.post<any>(`${this.url}/split-item`, request);
  };

  validateItemDate(date: any): any {
    return this.http.get(`${this.url}/validate`, {
      params: {
        itemDate: date.toString()
      }
    });
  }

  submitSplitWip = (wipEntries: any): Observable<any> => {
    return this.http.post(`${this.url}/split-item`, wipEntries);
  };
}
