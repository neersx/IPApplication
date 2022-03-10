import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class OfficialNumbersService {
  constructor(private readonly http: HttpClient) {
  }

  getCaseViewIpOfficeNumbers = (caseKey: number, queryParams: any): Observable<Array<any>> => {
    return this.http.get<Array<any>>(`api/case/${caseKey}/officialnumbers/ipoffice`, {
      params: {
        params: JSON.stringify(queryParams)
      }
    });
  };

  getCaseViewOtherNumbers = (caseKey: number, queryParams: any): Observable<Array<any>> => {
    return this.http.get<Array<any>>(`api/case/${caseKey}/officialnumbers/other`, {
      params: {
        params: JSON.stringify(queryParams)
      }
    });
  };
}
