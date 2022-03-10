import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Observable } from 'rxjs';
import { NotificationType } from 'shared/component/notification/notification/ipx-notification.config';
import * as _ from 'underscore';
import { AdHocDate, BulkFinaliseRequestModel, FinaliseRequestModel } from './adhoc-date.model';

@Injectable()
export class AdhocDateService {
  baseApiRoute = 'api/adhocdates';
  constructor(private readonly http: HttpClient) { }

  adhocDate(id: number): Observable<AdHocDate> {

    return this.http.get<AdHocDate>(`${this.baseApiRoute}/` + id);
  }

  finalise(finaliseModel: FinaliseRequestModel): Observable<any> {

    return this.http.post<any>(`${this.baseApiRoute}/` + 'finalise', finaliseModel);
  }

  bulkFinalise(bulkFinaliseModel: BulkFinaliseRequestModel): Observable<any> {

    return this.http.post<any>(`${this.baseApiRoute}/` + 'bulkfinalise', bulkFinaliseModel);
  }

  saveAdhocDate(saveAdhocDetails: any): Observable<any> {

    return this.http.post<any>(`${this.baseApiRoute}`, saveAdhocDetails);
  }

  viewData(alertId?: number): Observable<any> {

    const uri = `${this.baseApiRoute}/viewdata` + (_.isNumber(alertId) ? `/${alertId}` : '');

    return this.http.get<any>(uri);
  }

  maintainAdhocDate(alertId: number, maintainAdhocDetails: any): Observable<any> {

    return this.http.put<any>(`${this.baseApiRoute}/` + alertId, maintainAdhocDetails);
  }

  delete(alertId: number): Observable<any> {

    return this.http.delete(`${this.baseApiRoute}/` + alertId);
  }

  caseEventDetails(caseEventId: number): Observable<any> {

    return this.http.get<any>(`${this.baseApiRoute}/caseeventdetails/` + caseEventId);
  }

  nameDetails(caseId: number): Observable<any> {

    return this.http.get<any>(`${this.baseApiRoute}/namedetails/` + caseId);
  }

  nameTypeRelationShip(caseId: number, nameTypeCode: string, relationshipCode: string): Observable<any> {

    return this.http.get<any>(`${this.baseApiRoute}/relationshipDetails/` + caseId + '/' + nameTypeCode + '/' + relationshipCode);
  }

  getPeriodTypes(): Array<any> {
    return [{
      key: 'D',
      value: 'periodTypes.days'
    }, {
      key: 'M',
      value: 'periodTypes.months'
    }];
  }
}

export enum adhocType {
  staff = 'EMP',
  myself = 'loggedInUser',
  signatory = 'SIG',
  criticalList = 'CriticalList',
  adhocResponsibleName = 'AdhocResponsibleName',
  nameType = 'NameType',
  relationShip = 'Relationship'
}
export enum adhocTypeMode {
  maintain = 'maintain'
}