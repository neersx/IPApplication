// tslint:disable: only-arrow-functions
import { Ng2StateDeclaration } from '@uirouter/angular';
import { Observable, of } from 'rxjs';
import { concatMap, map, tap } from 'rxjs/operators';
import { WipOverviewService } from 'search/wip-overview/wip-overview.service';
import * as _ from 'underscore';
import { CaseRequest } from './billing-maintenance/case-debtor.model';
import { CaseDebtorService } from './billing-maintenance/case-debtor/case-debtor.service';
import { BillingService } from './billing-service';
import { BillingComponent } from './billing.component';
import { BillingType } from './billing.model';

// tslint:disable-next-line: variable-name
export function getViewData(service: BillingService): Promise<any> {
    return service.getSettings$().toPromise();
}

// tslint:disable-next-line: variable-name
export function getSingleBillViewData(wipOverviewService: WipOverviewService, billingService: BillingService, caseDebtorService: CaseDebtorService): Promise<any> {

    if (!wipOverviewService.singleBillViewData) {
        return billingService.getSettings$().toPromise();
    }
    const caseKeys = [];
    wipOverviewService.singleBillViewData.selectedItems.forEach(item => {
        if (item.caseKey) {
            caseKeys.push(item.caseKey);
        }
    });
    const debtorItem = wipOverviewService.singleBillViewData.selectedItems.find((item) => { return item.debtorKey !== null; });
    let settings;

    return billingService.getSettings$().pipe(
        tap(res => {
            settings = res;
        }),
        concatMap(() =>
            getCaseList(wipOverviewService, caseDebtorService, caseKeys)
                .pipe(
                    map((response: any) => {
                        if (response.CaseList && response.CaseList.length > 0 && !_.any(response.CaseList, (c: any) => { return c.IsMainCase; })) {
                            response.CaseList[0].IsMainCase = true;
                        }

                        return {
                            Site: settings.Site,
                            User: settings.User,
                            Bill: settings.Bill,
                            singleBillData: {
                                billPreparationData: wipOverviewService.singleBillViewData.billPreparationData,
                                selectedItems: wipOverviewService.singleBillViewData.selectedItems,
                                itemType: wipOverviewService.singleBillViewData.itemType,
                                selectedCases: response.CaseList,
                                debtorKey: debtorItem.debtorKey
                            }
                        };
                    })
                )
        )
    ).toPromise();
}

// tslint:disable-next-line: variable-name
export function getCaseList(wipOverviewService: WipOverviewService, caseDebtorService: CaseDebtorService, caseKeys: Array<number>): Observable<any> {
    if (caseKeys.length === 0) {
        return of({ CaseList: [] });
    }
    const caseRequest: CaseRequest = {
        caseIds: caseKeys.join(', '),
        entityId: wipOverviewService.singleBillViewData.billPreparationData.entityId,
        raisedByStaffId: wipOverviewService.singleBillViewData.billPreparationData.raisedBy.key
    };

    return caseDebtorService.getCases(caseRequest);
}

// tslint:disable-next-line: variable-name
export const DebitNoteState: Ng2StateDeclaration = {
    name: 'debit-note',
    url: '/accounting/billing/debit-note?openItemNo&entityId',
    params: {
        type: BillingType.debit
    },
    component: BillingComponent,
    data: {
        pageTitle: 'accounting.billing.pageTitle'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [BillingService],
                resolveFn: getViewData
            }
        ]
};

// tslint:disable-next-line: variable-name
export const CreateSingleBill: Ng2StateDeclaration = {
    name: 'create-single-bill',
    url: '/accounting/billing/create-single-bill',
    component: BillingComponent,
    params: {
        type: 510
    },
    data: {
        pageTitle: 'accounting.billing.pageTitle'
    },
    resolve:
        [
            {
                token: 'viewData',
                deps: [WipOverviewService, BillingService, CaseDebtorService],
                resolveFn: getSingleBillViewData
            }
        ]
};