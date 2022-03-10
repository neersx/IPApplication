import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import * as _ from 'underscore';

@Injectable()
export class ProvideInstructionsService {
  baseApiRoute = 'api/provideInstructions';

  constructor(private readonly http: HttpClient) { }

  getProvideInstructions = (taskPlannerRowKey: string): Observable<any> => {

    return this.http.get<any>(`${this.baseApiRoute}/get/${taskPlannerRowKey}`);
  };

  save = (request: any): Observable<any> => {

    return this.http.post<any>(`${this.baseApiRoute}/instruct/`, request);
  };
}
