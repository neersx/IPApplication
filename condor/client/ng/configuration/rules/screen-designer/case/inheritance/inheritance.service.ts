import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class InheritanceService {

  constructor(readonly http: HttpClient) { }

  getInheritance = (criteriaIds: Array<number>): Promise<any> => {
    return this.http.get<any>('api/configuration/rules/screen-designer/case/inheritance', {
      params: {
        criteriaIds: criteriaIds.join(',')
      }
    }).toPromise();
  };
}
