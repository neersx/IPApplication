import { BillingStepsPersistanceService } from 'accounting/billing/billing-steps-persistance.service';
import { BillingType } from 'accounting/billing/billing.model';
import { CaseBillNarrativeComponent } from 'accounting/time-recording/case-bill-narrative/case-bill-narrative.component';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock, IpxNotificationServiceMock, NotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { of } from 'rxjs';
import { BillingActivity, HeaderEntityType } from '../case-debtor.model';
import { CaseDebtorComponent } from './case-debtor.component';
import { UnpostedTimeListComponent } from './unposted-time-list/unposted-time-list.component';

describe('CaseDebtorComponent', () => {
    let component: CaseDebtorComponent;
    let cdr: ChangeDetectorRefMock;
    let modalService: ModalServiceMock;
    let ipxNotificationService: IpxNotificationServiceMock;
    let localSettings = new LocalSettingsMock();
    let notificationService: any;
    let service: {
        getCases: any;
    };

    let billingService: {
        openItemData$: any;
        setValidAction: any;
        getStepData: any;
    };
    let billingStepsService: BillingStepsPersistanceService;

    beforeEach(() => {
        localSettings = new LocalSettingsMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        billingStepsService = new BillingStepsPersistanceService();
        service = {
            getCases: jest.fn().mockReturnValue(of({ CaseList: [{ CaseId: 123, DraftBills: [22, 34] }, { CaseId: 976, DraftBills: [232, 634] }] }))
        };

        billingService = {
            openItemData$: { getValue: jest.fn().mockReturnValue(true), next: jest.fn() } as any,
            setValidAction: jest.fn(),
            getStepData: jest.fn()
        };
        cdr = new ChangeDetectorRefMock();
        modalService = new ModalServiceMock();
        notificationService = new NotificationServiceMock();
        component = new CaseDebtorComponent(billingService as any, service as any, cdr as any, modalService as any, localSettings as any, ipxNotificationService as any, notificationService, billingStepsService as any);
        component.openItemData = {
            ItemType: 'Billing',
            ItemTransactionId: 233,
            ItemEntityId: 64,
            LocalCurrencyCode: 'AU'
        };
        component.grid = {
            rowDeleteHandler: jest.fn(),
            rowCancelHandler: jest.fn(),
            checkChanges: jest.fn(),
            isValid: jest.fn(),
            isDirty: jest.fn(),
            search: jest.fn(),
            wrapper: {
                closeRow: jest.fn(),
                data: [
                    {
                        CaseId: 100,
                        IsMainCase: true
                    }, {
                        CaseId: 130,
                        IsMainCase: false
                    },
                    {
                        CaseId: 234,
                        IsMainCase: false
                    }
                ]
            }
        } as any;
        component.records = component.grid.wrapper.data;
        component.activity = new BillingActivity(true);
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    describe('initialize component', () => {
        it('set initial parameters', () => {
            jest.spyOn(component, 'buildGridOptions');
            component.ngOnInit();
            expect(component.buildGridOptions).toHaveBeenCalled();
            expect(billingService.openItemData$.getValue).toHaveBeenCalled();
            expect(component.billingType).toBe(component.openItemData.ItemType);
        });

        it('set initial parameters for single bill', () => {
            jest.spyOn(component, 'buildGridOptions');
            component.singleBillViewData = {
                billPreparationData: { entityId: 1, includeNonRenewal: true, includeRenewal: true, raisedBy: { key: 110 }, useRenewalDebtor: false },
                itemType: BillingType.debit,
                selectedItems: [{ key: 1, caseKey: 221 }],
                debtorKey: 3,
                selectedCases: []
            };
            component.ngOnInit();
            expect(component.records).toBe(component.singleBillViewData.selectedCases);
            expect(component.buildGridOptions).toHaveBeenCalled();
            expect(billingService.openItemData$.getValue).toHaveBeenCalled();
        });
    });

    it('should call the onRowAddedOrEdited', () => {

        const data = {
            dataItem: {
                status: 'A',
                disbursement: null
            }
        };

        jest.spyOn(component, 'onCloseModal');
        component.onRowAddedOrEdited(data);
        expect(component.onCloseModal).toHaveBeenCalled();
    });

    it('should call the onCloseModal on successfully case add', () => {
        component.grid = {
            search: jest.fn(),
            wrapper: {
                closeRow: jest.fn(),
                data: [
                    {
                        CaseId: 234,
                        IsMainCase: false
                    }
                ]
            }
        } as any;
        component.gridOptions = { _selectPage: jest.fn(), maintainFormGroup$: { next: jest.fn() } } as any;
        const data = {
            dataItem: {
                status: 'A'
            },
            rowIndex: 0
        };
        const event = {
            success: true,
            warnings: { draftBills: null },
            formGroup: { value: {} },
            rows: [],
            newCases: '234,345'
        };
        jest.spyOn(component, 'draftBillWarning');
        jest.spyOn(component, 'showWarnings');
        jest.spyOn(component, 'displayCaseDebtors').mockReturnValue();
        component.isNewCase = true;
        component.onCloseModal(event, data);
        expect(component.grid.search).toHaveBeenCalled();
        expect(component.records).toEqual(event.rows);
        expect(component.draftBillWarning).toHaveBeenCalled();
        expect(component.displayCaseDebtors).toHaveBeenCalledWith(event);
        expect(component.grid.wrapper.closeRow).toHaveBeenCalledWith(data.rowIndex);
    });

    it('should call the onCloseModal on cancel for add', () => {
        component.gridOptions = { _selectPage: jest.fn(), maintainFormGroup$: { next: jest.fn() } } as any;
        const data = {
            dataItem: {
                status: 'A',
                disbursement: null
            }
        };
        const event = {
            success: false,
            warnings: { draftBills: null }
        };
        jest.spyOn(component, 'removeAddedEmptyRow');
        component.onCloseModal(event, data);
        expect(component.removeAddedEmptyRow).toHaveBeenCalled();
    });
    it('should call draftBillWarning if sitecontrol ON', () => {
        const bills = [123, 343, 21];
        ipxNotificationService.modalRef.content = {
            confirmed$: of('confirm'),
            cancelled$: of()
        };
        component.draftBillSiteControl = true;
        component.draftBillWarning(bills);
        expect(ipxNotificationService.openAlertListModal).toHaveBeenCalled();
    });

    it('should not call draftBillWarning if sitecontrol OFF', () => {
        const bills = [123, 343, 21];
        ipxNotificationService.modalRef.content = {
            confirmed$: of('confirm'),
            cancelled$: of()
        };
        component.draftBillSiteControl = false;
        component.draftBillWarning(bills);
        expect(ipxNotificationService.openAlertListModal).not.toHaveBeenCalled();
    });

    it('should call the openUnpostedTimeList', () => {
        const unpostedTimeList = [{ Name: 'abc', StartTime: '2000-12-12', TotalTime: '8:00', TimeValue: 10 }];
        jest.spyOn(modalService, 'openModal');
        const params = {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                unpostedCaseTimeList: unpostedTimeList,
                caseIRN: '1234/a',
                total: 10
            }
        };
        component.openUnpostedTimeList(unpostedTimeList, '1234/a');
        expect(modalService.openModal).toHaveBeenCalledWith(UnpostedTimeListComponent, params);
    });

    it('should call rever new change', () => {
        component.revertNewCaseChange();
        expect(component.records).toEqual(component.oldRecords);
        expect(component.grid.search).toHaveBeenCalled();
    });

    it('should display case debtors', () => {
        const debtor: any = {
            selectDebtors: {
                next: jest.fn()
            }
        };
        jest.spyOn(component, 'getMainCase').mockReturnValue([{
            CaseId: 234,
            IsMainCase: false
        }]);
        component.debtorsComponent = debtor;
        component.displayCaseDebtors({});

        setTimeout(() => {
            expect(component.debtorsComponent.selectDebtors.next).toHaveBeenCalled();
            expect(component.grid.search).toHaveBeenCalled();
        }, 200);
    });

    it('should call onCaseHeaderChange', () => {
        component.grid.wrapper.data = [{ CaseId: 123 }];
        component.activity = new BillingActivity(true);
        component.openItemData.Action = 'RN';
        jest.spyOn(component, 'loadDebtorsOnHeaderChange');
        const header = {
            form: { raisedBy: 123, useRenewalDebtor: false },
            values: {
                entity: HeaderEntityType.ActionPicklist
            }
        };
        component.onCaseHeaderChange(header);
        expect(component.loadDebtorsOnHeaderChange).not.toHaveBeenCalled();
    });

    describe('toggle maincase', () => {
        it('should change main case with CaseId', () => {
            component.records = component.grid.wrapper.data;
            jest.spyOn(component, 'getMainCase').mockReturnValue({
                CaseId: 234,
                IsMainCase: false
            });
            jest.spyOn(component, 'displayCaseDebtors');
            component.toggleMainCase(123, true);
            expect(component.selectedCase).toBe(123);
            expect(component.displayCaseDebtors).toHaveBeenCalled();
        });
        it('shouldtoggle mainCase without caseId', () => {
            component.grid = {
                search: jest.fn(),
                wrapper: {
                    closeRow: jest.fn(),
                    data: [
                        {
                            CaseId: 234,
                            IsMainCase: false
                        }
                    ]
                }
            } as any;
            const rows: any = component.grid.wrapper.data;
            component.draftBillSiteControl = true;
            component.toggleMainCase(null, true);
            expect(component.records).toEqual(rows);
            expect(component.grid.search).toHaveBeenCalled();
        });
    });

    describe('show warnings', () => {
        const warning = {
            draftBills: [123]
        };
        it('should call show warnings', () => {
            jest.spyOn(component, 'draftBillWarning');
            component.showWarnings(warning);
            expect(component.draftBillWarning).toHaveBeenCalledWith(warning.draftBills);
        });

        it('should call draftbill warning', () => {
            const alert = {
                title: 'Warning',
                message: 'accounting.billing.draftBillValidation',
                confirmText: 'Ok',
                cancelText: '',
                errors: warning.draftBills,
                messageParams: warning.draftBills
            };
            component.draftBillSiteControl = true;
            component.draftBillWarning(warning.draftBills);
            expect(ipxNotificationService.openAlertListModal).toHaveBeenCalledWith(alert.title, alert.message, alert.confirmText, alert.cancelText, alert.errors, alert.messageParams);
        });
    });

    describe('case narrative', () => {
        const data = {
            dataItem: {
                CaseId: 1
            }
        };
        it('displays the maintain case narratives dialog', () => {
            modalService.content = { onClose$: of(true) };
            component.maintainCaseBillNarrative(data.dataItem);

            expect(modalService.openModal).toHaveBeenCalledWith(CaseBillNarrativeComponent, {
                focus: true,
                animated: false,
                backdrop: 'static',
                class: 'modal-lg',
                initialState: { caseKey: 1 }
            });
        });
    });

    describe('context menu', () => {
        const data = {
            dataItem: {
                CaseId: 1,
                IsMainCase: true
            }
        };
        it('displays context menu options', () => {
            component.ngOnInit();
            component.displayTaskItems({});

            expect(component.taskItems.length).toBe(3);
            expect(component.taskItems[0].id).toEqual('mainCase');
            expect(component.taskItems[1].id).toEqual('caseNarrative');
            expect(component.taskItems[2].id).toEqual('delete');
            expect(component.gridOptions.showContextMenu).toBeTruthy();
        });

        it('should disable main case opiton when row is mainCase', () => {
            component.ngOnInit();
            component.displayTaskItems(data.dataItem);

            expect(component.taskItems[0].disabled).toBeTruthy();
            expect(component.taskItems.length).toBe(3);
            expect(component.gridOptions.showContextMenu).toBeTruthy();
        });
    });
});