import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { LocalSettings } from 'core/local-settings';
import { Observable } from 'rxjs';
import * as _ from 'underscore';
import { SingleBillViewData } from './wip-overview.data';
@Injectable()
export class WipOverviewService {
  baseApiRoute = 'api/search/wipoverview';

  get singleBillViewData(): SingleBillViewData {
    return this.localSettings.keys.wipOverview.singleBillData.getSession;
  }
  set singleBillViewData(value: SingleBillViewData) {
    this.localSettings.keys.wipOverview.singleBillData.setSession(value);
  }

  constructor(private readonly http: HttpClient,
    private readonly localSettings: LocalSettings) { }

  validateSingleBillCreation = (selectedItems: Array<any>): Observable<any> => {

    return this.http
      .post<any>(`${this.baseApiRoute}/validateSingleBillCreation`, selectedItems);
  };

  isEntityRestrictedByCurrency = (entityKey: number): Observable<any> => {

    return this.http
      .get<boolean>(`${this.baseApiRoute}/isEntityRestrictedByCurrency/${entityKey}`);
  };
}
