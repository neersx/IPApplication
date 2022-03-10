import { Injectable } from '@angular/core';
import { BillingType } from 'accounting/billing/billing.model';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import { SearchHelperService } from 'search/common/search-helper.service';
import { BillReversalType, BillSearchPermissions } from 'search/results/search-results.data';
import * as _ from 'underscore';
import { BillSearchService } from './bill-search.service';

@Injectable()
export class BillSearchProvider {

    isHosted: boolean;
    permissions: BillSearchPermissions;

    constructor(
        private readonly billSearchService: BillSearchService,
        private readonly notificationService: NotificationService,
        private readonly searchHelperService: SearchHelperService,
        private readonly windowParentMessagingService: WindowParentMessagingService
    ) { }

    initializeContext = (permissions: BillSearchPermissions, isHosted): void => {
        this.permissions = permissions;
        this.isHosted = isHosted;
    };

    manageTaskOperation = (dataItem: any, event: any): void => {
        if (!dataItem || !event || !event.item) { return; }
        switch (event.item.id) {
            case BillSearchTaskMenuItemOperationType.deleteDraftBill:
                this.deleteDraftBill(dataItem);
                break;
            case BillSearchTaskMenuItemOperationType.reverse:
                this.windowParentMessagingService.postNavigationMessage(
                    {
                        args: [
                            event.item.id,
                            dataItem.itemEntityNo ? dataItem.itemEntityNo : '',
                            dataItem.itemTransNo ? dataItem.itemTransNo : '',
                            dataItem.acctEntityNo ? dataItem.acctEntityNo : '',
                            dataItem.debtorKey ? dataItem.debtorKey : '',
                            dataItem.itemno.value,
                            dataItem.itemdate ? dataItem.itemdate : ''
                        ]
                    }
                );
                break;
            case BillSearchTaskMenuItemOperationType.credit:
                this.windowParentMessagingService.postNavigationMessage(
                    {
                        args: [
                            event.item.id,
                            dataItem.itemEntityNo ? dataItem.itemEntityNo : '',
                            dataItem.itemTransNo ? dataItem.itemTransNo : '',
                            dataItem.itemno.value,
                            dataItem.itemdate ? dataItem.itemdate : '',
                            dataItem.localValue ? dataItem.localValue : '',
                            dataItem.localBalance ? dataItem.localBalance : '',
                            dataItem.relatedItemNo
                        ]
                    }
                );
                break;
            default:
                break;
        }
    };

    canAccessTask = (dataItem: any, task: BillSearchTaskMenuItemOperationType): boolean => {
        switch (task) {
            case BillSearchTaskMenuItemOperationType.deleteDraftBill:
                return this.isDraftBill(dataItem)
                    && ((dataItem.itemTypeKey === BillingType.credit && this.permissions.canDeleteCreditNote)
                        || (dataItem.itemTypeKey === BillingType.debit && this.permissions.canDeleteDebitNote));

            case BillSearchTaskMenuItemOperationType.reverse:
                return this.isHosted
                    && this.canAccessReverseTask(dataItem);

            case BillSearchTaskMenuItemOperationType.credit:
                return this.isHosted
                    && !this.isDraftBill(dataItem)
                    && dataItem.itemTypeKey === BillingType.debit
                    && this.permissions.canCreditBill;
            default:
                break;
        }

        return false;
    };

    private readonly isDraftBill = (dataItem: any): boolean => {
        return dataItem.billstatus && dataItem.billstatus.toUpperCase() === 'DRAFT';
    };

    private readonly deleteDraftBill = (dataItem: any): void => {
        this.notificationService.confirmDelete({
            message: 'billSearch.inlineTaskMenu.deleteConfirmationText'
        }).then(() => {
            this.billSearchService.deleteDraftBill(dataItem.itemEntityNo, dataItem.itemno.value).subscribe(() => {
                this.notificationService.success('billSearch.inlineTaskMenu.deleteSuccess');
                this.searchHelperService.onActionComplete$.next({ reloadGrid: true });
            });
        });
    };

    private readonly canAccessReverseTask = (dataItem: any): boolean => {
        if (!dataItem || dataItem.billReversalNotAllowed) {
            return false;
        }

        if ((dataItem.itemTypeKey === BillingType.credit && !this.permissions.canMaintainCreditNote)
            || dataItem.itemTypeKey === BillingType.debit && !this.permissions.canMaintainDebitNote) {
            return false;
        }

        if (this.permissions.canReverseBill === BillReversalType.ReversalNotAllowed) {
            return false;
        }

        if (this.permissions.canReverseBill === BillReversalType.CurrentPeriodReversalAllowed
            && dataItem.closedForBilling) {
            return false;
        }

        return !this.isDraftBill(dataItem) && (dataItem.itemTypeKey === BillingType.credit || dataItem.itemTypeKey === BillingType.debit);
    };
}

export enum BillSearchTaskMenuItemOperationType {
    deleteDraftBill = 'DeleteDraftBill',
    reverse = 'ReverseFinalisedBill',
    credit = 'CreditFinalisedBill'
}