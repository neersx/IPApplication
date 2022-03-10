import { BillingType } from 'accounting/billing/billing.model';
import { NotificationServiceMock } from 'mocks';
import { WindowParentMessagingServiceMock } from 'mocks/window-parent-messaging.service.mock';
import { Observable } from 'rxjs';
import { BillReversalType } from 'search/results/search-results.data';
import { BillSearchProvider, BillSearchTaskMenuItemOperationType } from './bill-search.provider';

describe('BillSearchProvider', () => {

    let service: BillSearchProvider;
    const billSearchService = { deleteDraftBill: jest.fn().mockReturnValue(new Observable()) };
    let notificationService: NotificationServiceMock;
    let windowParentMessagingService: WindowParentMessagingServiceMock;
    let dataItem: any;

    beforeEach(() => {
        notificationService = new NotificationServiceMock();
        windowParentMessagingService = new WindowParentMessagingServiceMock();
        service = new BillSearchProvider(billSearchService as any, notificationService as any, {} as any, windowParentMessagingService as any);
        service.permissions = {
            canDeleteCreditNote: true,
            canDeleteDebitNote: true,
            canCreditBill: true,
            canMaintainCreditNote: true,
            canMaintainDebitNote: true,
            canReverseBill: BillReversalType.ReversalAllowed
        };
        service.isHosted = true;
        dataItem = {
            itemEntityNo: 12,
            itemTransNo: 98,
            acctEntityNo: 12,
            debtorKey: 34,
            itemno: { value: 'D1233' },
            itemdate: new Date(),
            itemTypeKey: BillingType.debit,
            billstatus: 'DRAFT',
            localValue: 123,
            localBalance: 566,
            relatedItemNo: 334
        };
    });

    it('should create the service', () => {
        expect(service).toBeTruthy();
    });

    it('verify initializeContext', () => {
        service.initializeContext({
            canDeleteCreditNote: true,
            canDeleteDebitNote: false,
            canCreditBill: true,
            canMaintainCreditNote: true,
            canMaintainDebitNote: true,
            canReverseBill: BillReversalType.CurrentPeriodReversalAllowed
        }, false);
        expect(service.isHosted).toBeFalsy();
        expect(service.permissions.canDeleteCreditNote).toBeTruthy();
        expect(service.permissions.canDeleteDebitNote).toBeFalsy();
        expect(service.permissions.canReverseBill).toBe(BillReversalType.CurrentPeriodReversalAllowed);
    });

    describe('Verify manageTaskOperation', () => {

        it('should call delete Draft Bill', () => {
            const event = { item: { id: BillSearchTaskMenuItemOperationType.deleteDraftBill } };
            service.manageTaskOperation(dataItem, event);
            expect(notificationService.confirmDelete).toHaveBeenCalledWith({
                message: 'billSearch.inlineTaskMenu.deleteConfirmationText'
            });
        });

        it('should call reverse Bill', () => {
            const event = { item: { id: BillSearchTaskMenuItemOperationType.reverse } };
            service.manageTaskOperation(dataItem, event);
            expect(windowParentMessagingService.postNavigationMessage).toHaveBeenCalledWith({
                args: [
                    event.item.id,
                    dataItem.itemEntityNo,
                    dataItem.itemTransNo,
                    dataItem.acctEntityNo,
                    dataItem.debtorKey,
                    dataItem.itemno.value,
                    dataItem.itemdate
                ]
            });
        });

        it('should call credit Bill', () => {
            const event = { item: { id: BillSearchTaskMenuItemOperationType.credit } };
            service.manageTaskOperation(dataItem, event);
            expect(windowParentMessagingService.postNavigationMessage).toHaveBeenCalledWith({
                args: [
                    event.item.id,
                    dataItem.itemEntityNo,
                    dataItem.itemTransNo,
                    dataItem.itemno.value,
                    dataItem.itemdate,
                    dataItem.localValue,
                    dataItem.localBalance,
                    dataItem.relatedItemNo
                ]
            });
        });
    });

    describe('Verify canAccessTask method', () => {
        it('Should return true when delete draft Bill', () => {
            const result = service.canAccessTask(dataItem, BillSearchTaskMenuItemOperationType.deleteDraftBill);
            expect(result).toBeTruthy();
        });

        it('Should return false when delete draft Bill without permission', () => {
            service.permissions.canDeleteCreditNote = false;
            const result = service.canAccessTask(dataItem, BillSearchTaskMenuItemOperationType.deleteDraftBill);
            expect(result).toBeTruthy();
        });

        it('Should return false when delete finalized bill', () => {
            dataItem.billstatus = '';
            dataItem.itemno.value = '124';
            const result = service.canAccessTask(dataItem, BillSearchTaskMenuItemOperationType.deleteDraftBill);
            expect(result).toBeFalsy();
        });

        it('should return true when reverse finalised bill', () => {
            dataItem.billstatus = '';
            dataItem.itemno.value = '124';
            const result = service.canAccessTask(dataItem, BillSearchTaskMenuItemOperationType.reverse);
            expect(result).toBeTruthy();
        });

        it('should return false when reverse finalised bill without permission', () => {
            service.permissions.canReverseBill = BillReversalType.ReversalNotAllowed;
            dataItem.billstatus = '';
            dataItem.itemno.value = '124';
            const result = service.canAccessTask(dataItem, BillSearchTaskMenuItemOperationType.reverse);
            expect(result).toBeFalsy();
        });

        it('should return false when reverse draft bill', () => {
            const result = service.canAccessTask(dataItem, BillSearchTaskMenuItemOperationType.reverse);
            expect(result).toBeFalsy();
        });

        it('should return true when credit finalised bill', () => {
            dataItem.billstatus = '';
            dataItem.itemno.value = '124';
            const result = service.canAccessTask(dataItem, BillSearchTaskMenuItemOperationType.credit);
            expect(result).toBeTruthy();
        });

        it('should return false when credit draft bill', () => {
            const result = service.canAccessTask(dataItem, BillSearchTaskMenuItemOperationType.credit);
            expect(result).toBeFalsy();
        });

    });

});
