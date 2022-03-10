import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import * as _ from 'underscore';
@Injectable()
export class BillSearchService {
  baseApiRoute = 'api/accounting/billing';

  constructor(private readonly http: HttpClient) { }

  deleteDraftBill = (itemEntityId: number, openItemNo: string): Observable<any> => {

    return this.http
      .delete<any>(`${this.baseApiRoute}/open-item/${itemEntityId}/${openItemNo}`);
  };

}
