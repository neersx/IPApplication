import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class CaseHeaderService {

  constructor(readonly http: HttpClient) { }

  getHeader = (caseKey: number): Promise<any> => {
    return this.http.get(`api/case/${caseKey}/header`).toPromise();
  };
}
