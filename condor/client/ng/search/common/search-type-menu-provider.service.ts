import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Params } from '@angular/router';
import { Observable } from 'rxjs';

@Injectable()
export class SearchTypeMenuProviderService {

  private _baseApiRoute: string;
  get baseApiRoute(): string {
    return this._baseApiRoute;
  }
  set baseApiRoute(value: string) {
    this._baseApiRoute = value;
  }
  constructor(readonly http: HttpClient) { }

  getAdditionalViewDataFromFilterCriteria = (request: any): Observable<any> => {
    return this.http.post(`${this.baseApiRoute}additionalviewdata`, request);
  };
}
