
'use strict';

export class BillingCaseItems {
  /* tslint:disable:variable-name */
  ItemEntityNo: number;
  /* tslint:disable:variable-name */
  IsMainCase?: Boolean;
  /* tslint:disable:variable-name */
  CaseReference: string;
  /* tslint:disable:variable-name */
  Title: string;
  /* tslint:disable:variable-name */
  CaseTypeCode: string;
  /* tslint:disable:variable-name */
  CaseTypeDescription: string;
  /* tslint:disable:variable-name */
  CountryCode: string;
  /* tslint:disable:variable-name */
  PropertyType: string;
  /* tslint:disable:variable-name */
  TotalCredits?: number;
  /* tslint:disable:variable-name */
  UnlockedWip?: number;
  /* tslint:disable:variable-name */
  TotalWip?: number;
  /* tslint:disable:variable-name */
  UnpostedTimeList?: Array<CaseUnpostedTime>;
  hasUnpostedTime: boolean;
}

export class CaseUnpostedTime {
  /* tslint:disable:variable-name */
  NameId: number;
  /* tslint:disable:variable-name */
  Name: string;
  /* tslint:disable:variable-name */
  StartTime: Date;
  /* tslint:disable:variable-name */
  TotalTime: Date;
  /* tslint:disable:variable-name */
  TimeValue: number;
}

export class CaseRequest {
  caseListId?: number;
  caseIds: string;
  entityId?: number;
  raisedByStaffId: number;
}

export enum ActivityEnum {
  onLoaded = 'L',
  onMainCaseChanged = 'M',
  onDebtorChanged = 'D',
  onActionChanged = 'A',
  onRenewalFlagChanged = 'R',
  onOpenItemLoaded = 'O',
  OnCaseDeleted = 'E'
}

export class BillingActivity {
  onLoaded: boolean;
  onActionChanged?: any;
  onRenewalFlagChanged?: any;
  onOpenItemLoaded?: any;
  onMainCaseChanged?: any;
  onDebtorChanged?: any;

  constructor(onLoad = false) {
    this.onLoaded = onLoad;
  }
}

export enum HeaderEntityType {
  ActionPicklist = 'Action',
  RenewalCheckBox = 'Renewal'
}

export enum CaseDebtorActivity {
  onLoaded = 'L',
  onMainCaseChanged = 'M',
  onDebtorChanged = 'D',
  onActionChanged = 'A',
  onRenewalFlagChanged = 'R',
  onOpenItemLoaded = 'O',
  OnCaseDeleted = 'E'
}