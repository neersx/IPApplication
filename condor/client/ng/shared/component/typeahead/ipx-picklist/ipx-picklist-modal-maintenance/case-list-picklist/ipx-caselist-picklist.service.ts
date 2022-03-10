import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { CaseList } from './case-list-picklist.model';

@Injectable()
export class IpxCaselistPicklistService {

  constructor(private readonly http: HttpClient) { }

  getCasesListItems$(caseKeys: Array<number>, primeCaseKey: number, queryParams: GridQueryParameters, newlyAddedCaseKeys: Array<number>): Observable<any> {
    if (caseKeys.length <= 0) { return of([]); }

    return this.http.post('api/picklists/CaseLists/cases/', {
      caseKeys,
      newlyAddedCaseKeys,
      queryParameters: queryParams,
      primeCaseKey
    });
  }

  updateCasesListItems$(id: number, caseList: CaseList): Observable<any> {
    return this.http.put('api/picklists/CaseLists/' + id, caseList);
  }
}
