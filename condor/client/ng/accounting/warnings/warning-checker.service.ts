import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, of, race } from 'rxjs';
import { concatMap, filter, map, mergeMap, take } from 'rxjs/operators';
import { HideEvent, IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { CasenamesWarningsComponent } from './case-names-warning/casenames-warnings.component';
import { NameOnlyWarningsComponent } from './name-only-warnings/name-only-warnings.component';
import { WarningService } from './warning-service';
import { WipWarningData } from './warnings-model';

@Injectable()
export class WarningCheckerService {
  restrictOnWip = false;

  constructor(
    private readonly http: HttpClient,
    private readonly modalService: IpxModalService,
    private readonly notificationService: IpxNotificationService,
    private readonly warningService: WarningService) { }

  private readonly _checkCaseStatus = (caseKey: number): Observable<any> => {
    return this.http.get(`api/accounting/time/checkstatus/${caseKey}`);
  };

  readonly performCaseWarningsCheck = (caseKey?: number, date?: Date): Observable<boolean> => {
    this.warningService.restrictOnWip = this.restrictOnWip;

    if (_.isNumber(caseKey)) {
      return this._checkCaseStatus(caseKey)
        .pipe(concatMap((result: boolean) => {
          return this._handleCaseStatusCheckResult(result) ? this._checkCaseNameWarnings(caseKey, date) : of(false);
        }));
    }

    return of(true);
  };

  readonly performNameWarningsCheck = (nameKey?: number, displayName?: string, currentDate?: Date): Observable<boolean> => {
    if (_.isNumber(nameKey)) {
      return this._checkNameWarnings(nameKey, displayName, currentDate);
    }

    return of(true);
  };

  private readonly _handleCaseStatusCheckResult = (result: boolean): boolean => {
    if (!result) {
      this.notificationService.openAlertModal(null, 'accounting.wip.caseStatusRestrictedFor');

      return false;
    }

    return true;
  };

  private readonly _checkCaseNameWarnings = (caseKey: number, currentDate?: Date): Observable<boolean> => {
    return this.warningService.getCasenamesWarnings(caseKey, currentDate)
      .pipe(mergeMap((response: WipWarningData) => {
        if (!response) {
          return of(true);
        }

        const caseNamesRes = response.caseWipWarnings;
        if (!!response.budgetCheckResult || (!!response.prepaymentCheckResult && response.prepaymentCheckResult.exceeded) || !!response.billingCapCheckResult && response.billingCapCheckResult.length > 0 || caseNamesRes.length && _.any(caseNamesRes, cn => {
          return (cn.caseName.debtorStatusActionFlag !== null && cn.caseName.enforceNameRestriction) || (cn.creditLimitCheckResult && cn.creditLimitCheckResult.exceeded);
        })) {
          const data = { caseNames: caseNamesRes, budgetCheckResult: response.budgetCheckResult, selectedEntryDate: currentDate, prepaymentCheckResult: response.prepaymentCheckResult, billingCapCheckResults: response.billingCapCheckResult };
          const modalRef = this.modalService.openModal(CasenamesWarningsComponent, { animated: false, ignoreBackdropClick: true, class: 'modal-lg', initialState: data });

          const cancelled$ = this.modalService.onHide$
            .pipe(filter((e: HideEvent) => e.isCancelOrEscape), take(1), map(() => false));

          const proceed$ = modalRef.content.btnClicked
            .pipe(take(1)) as Observable<boolean>;

          const blockedStatus$ = modalRef.content.onBlocked
            .pipe(take(1), map((isBlockedState: boolean) => !isBlockedState)) as Observable<boolean>;

          return race(cancelled$, proceed$, blockedStatus$);
        }

        return of(true);

      }));
  };

  private readonly _checkNameWarnings = (nameKey: number, displayName: string, currentDate: Date): Observable<boolean> => {
    return this.warningService.getWarningsForNames(nameKey, currentDate)
      .pipe(mergeMap((nameResponse: any) => {
        if (nameResponse && (nameResponse.restriction || (nameResponse.creditLimitCheckResult && nameResponse.creditLimitCheckResult.exceeded) || (nameResponse.prepaymentCheckResult && nameResponse.prepaymentCheckResult.exceeded) || nameResponse.billingCapCheckResult)) {
          const modalRef = this.modalService.openModal(NameOnlyWarningsComponent,
            { animated: false, ignoreBackdropClick: true, class: 'modal-lg', initialState: { name: _.extend(nameResponse, { displayName }) } });

          const cancelled$ = this.modalService.onHide$
            .pipe(filter((e: HideEvent) => e.isCancelOrEscape), take(1), map(() => false));

          const proceed$ = modalRef.content.btnClicked
            .pipe(take(1)) as Observable<boolean>;

          const blockedState$ = modalRef.content.onBlocked
            .pipe(take(1), map((isBlocked: boolean) => !isBlocked)) as Observable<boolean>;

          return race(cancelled$, proceed$, blockedState$);
        }

        return of(true);
      }));
  };
}
