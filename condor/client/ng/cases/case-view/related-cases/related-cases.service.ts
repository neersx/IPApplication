import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';

@Injectable({
  providedIn: 'root'
})
export class RelatedCasesService {
  constructor(private readonly http: HttpClient) { }

  getRelatedCases = (caseKey: number, queryParams: GridQueryParameters): Observable<Array<any>> => {
    return this.http.get<Array<any>>(`api/case/${caseKey}/relatedcases`, {
        params: {
          params: JSON.stringify(queryParams)
        }
      });
  };
}
