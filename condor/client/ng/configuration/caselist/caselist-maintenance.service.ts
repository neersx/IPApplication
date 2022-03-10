import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { CaseListViewData } from './caselist-data';

@Injectable()
export class CaselistMaintenanceService {

  constructor(private readonly http: HttpClient) { }

  getViewdata(): Observable<CaseListViewData> {

    return this.http.get<CaseListViewData>('api/picklists/CaseLists/viewdata');
  }

  deleteList(caseListIds: Array<number>): Observable<any> {

    return this.http.post<any>('api/picklists/CaseLists/deleteList', caseListIds);
  }

}
