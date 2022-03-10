import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class CriticalDatesService {

  constructor(readonly http: HttpClient) { }
  getDates = (caseKey: number, queryParams: any): Observable<Array<any>> => {
    return this.http.get<Array<any>>('api/case/' + caseKey + '/critical-dates', {
      params: {
        params: JSON.stringify(queryParams)
      }
    });
  };
}
