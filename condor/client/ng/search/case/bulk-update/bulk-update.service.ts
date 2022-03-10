import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { BulkUpdateData, BulkUpdateReasonData, BulkUpdateViewData } from './bulk-update.data';

export interface IBulkUpdateService {
  getBulkUpdateViewData(): Observable<BulkUpdateViewData>;
  applyBulkUpdateChanges(caseIds: Array<number>, saveData: BulkUpdateData, reasonData: BulkUpdateReasonData): void;
  hasRestrictedCasesForStatus(cases: Array<number>, statusCode: string): Observable<boolean>;
  checkStatusPassword(password: string): Observable<boolean>;
}

@Injectable()
export class BulkUpdateService implements IBulkUpdateService {
  constructor(private readonly http: HttpClient) { }

  getBulkUpdateViewData(): Observable<BulkUpdateViewData> {
    return this.http.get('api/search/case/bulkupdate/viewdata').pipe(
      map((response: BulkUpdateViewData) => {

        return response;
      })
    );
  }

  applyBulkUpdateChanges(caseIds: Array<number>, saveData: BulkUpdateData, reasonData: BulkUpdateReasonData): Observable<any> {
    return this.http.post('api/search/case/bulkupdate/save', {
      caseIds,
      saveData,
      reasonData
    });
  }

  hasRestrictedCasesForStatus(cases: Array<number>, statusCode: string): Observable<boolean> {
    return this.http.post<boolean>('api/search/case/bulkupdate/hasRestrictedCasesForStatus',
      { cases, statusCode });
  }

  checkStatusPassword(password: string): Observable<boolean> {
    return this.http.post<boolean>('api/search/case/bulkupdate/checkStatusPassword/' + password, null);
  }
}
