'use strict';

import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';

export interface IAccountingService {
  currencyCode: string;
  canViewReceivables: boolean;
  canViewWorkInProgress: boolean;
  getCurrencyCode(): any;
  getReceivableBalance(nameKey, cache): any;
  getViewReceivablesPermission(): boolean;
  getViewWipPermission(): boolean;
}

@Injectable()
export class AccountingService implements IAccountingService {
  currencyCode: string;
  canViewReceivables: boolean;
  canViewWorkInProgress: boolean;
  constructor(private readonly http: HttpClient) {}

  getCurrencyCode(): string {
    return this.currencyCode;
  }
  getViewReceivablesPermission(): boolean {
    return this.canViewReceivables;
  }

  getViewWipPermission(): boolean {
    return this.canViewWorkInProgress;
  }

  getReceivableBalance(nameKey: number, cache = false): any {
    let headers: HttpHeaders;
    if (cache) {
      headers = new HttpHeaders({ 'cache-response': 'true' });
    }

    return this.http.get(
      'api/accounting/name/' + nameKey.toString() + '/receivables',
      { headers }
    );
  }
}
