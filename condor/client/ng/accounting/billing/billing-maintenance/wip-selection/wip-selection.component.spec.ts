import { BillingStepsPersistanceService } from 'accounting/billing/billing-steps-persistance.service';
import { AppContextServiceMock } from 'core/app-context.service.mock';
import { ChangeDetectorRefMock, LocalSettingsMocks, Renderer2Mock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { of } from 'rxjs';
import { MaintainBilledAmountComponent } from './maintain-billed-amount.component';
import { FilterByRenewal, WipSelectionComponent } from './wip-selection.component';

describe('WipSelectionComponent', () => {
    let component: WipSelectionComponent;
    let cdr: ChangeDetectorRefMock;
    let modalService: ModalServiceMock;
    let renderer: Renderer2Mock;
    let appContextService: AppContextServiceMock;
    let service: {
        getAvailableWip: any;
        getBillAvailableWip: any;
    };
    let billingService: {
        openItemData$: any;
        setValidAction: any;
        billSettings$: any;
    };
    let billingStepsService: BillingStepsPersistanceService;
    let localSettings: LocalSettingsMocks;

    beforeEach(() => {
        renderer = new Renderer2Mock();
        appContextService = new AppContextServiceMock();
        billingStepsService = new BillingStepsPersistanceService();
        localSettings = new LocalSettingsMocks();
        service = {
            getAvailableWip: jest.fn().mockReturnValue(of([{ CaseId: 123, Balance: 50 }, { CaseId: 976, Balance: 200 }])),
            getBillAvailableWip: jest.fn().mockReturnValue(of([{ CaseId: 22, Balance: 100, LocalBilled: 100 }]))
        };

        billingService = {
            openItemData$: { getValue: jest.fn().mockReturnValue(true), next: jest.fn() } as any,
            setValidAction: jest.fn(),
            billSettings$: {
                getValue: jest.fn().mockReturnValue({
                    MinimumWipReasonCode: 'R',
                    MinimumWipValues: [{ WipCode: 'CORR' }, { WipCode: 'CER' }]
                }), next: jest.fn()
            } as any
        };
        cdr = new ChangeDetectorRefMock();
        modalService = new ModalServiceMock();
        component = new WipSelectionComponent(billingService as any, service as any, billingStepsService as any, cdr as any, modalService as any, renderer as any, appContextService as any, localSettings as any);
        component.openItemData = {
            ItemType: 510,
            ItemTransactionId: null,
            ItemEntityId: 64,
            LocalCurrencyCode: 'AU',
            Status: 0,
            OpenItemNo: null,
            StaffId: 1
        };
        component.siteControls = {
            InterEntityBilling: true,
            BillAllWIP: true,
            WIPSplitMultiDebtor: false,
            SellRateOnlyforNewWIP: false
        };
        component.resultsGrid = {
            resetColumns: jest.fn(),
            rowDeleteHandler: jest.fn(),
            rowCancelHandler: jest.fn(),
            checkChanges: jest.fn(),
            isValid: jest.fn(),
            isDirty: jest.fn(),
            search: jest.fn(),
            rowEditHandler: jest.fn(),
            wrapper: {
                closeRow: jest.fn(),
                data: [
                    {
                        UniqueReferenceId: 1,
                        CaseId: 100,
                        Balance: 100,
                        ForeignBalance: 200,
                        IsRenewal: false
                    }, {
                        UniqueReferenceId: 2,
                        CaseId: 130,
                        Balance: 100,
                        IsRenewal: true
                    },
                    {
                        UniqueReferenceId: 3,
                        CaseId: 234,
                        Balance: 120,
                        IsRenewal: false
                    }
                ]
            }
        } as any;
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    describe('ngOnInit', () => {
        it('should call ngOnInit', () => {
            billingService.openItemData$.getValue = jest.fn().mockReturnValue(component.openItemData);
            component.ngOnInit();
            expect(component.gridOptions.columns.length).toEqual(20);
            expect(component.existingOpenItem).toEqual(null);
            expect(component.isFinalised).toEqual(false);
        });

        it('should set filterByRenewal as renewal for single bill', () => {
            component.singleBillViewData = {
                itemType: 1,
                selectedItems: [],
                billPreparationData: {
                    entityId: 22,
                    includeRenewal: true,
                    includeNonRenewal: false,
                    useRenewalDebtor: false,
                    raisedBy: {}
                }
            };
            component.ngOnInit();
            expect(component.filterByRenewal).toEqual(FilterByRenewal.renewal);
        });

        it('should set filterByRenewal as both for single bill', () => {
            component.singleBillViewData = {
                itemType: 1,
                selectedItems: [],
                billPreparationData: {
                    entityId: 22,
                    includeRenewal: true,
                    includeNonRenewal: true,
                    useRenewalDebtor: false,
                    raisedBy: {}
                }
            };
            component.ngOnInit();
            expect(component.filterByRenewal).toEqual(FilterByRenewal.both);
        });
    });

    it('should set variables based on persistence service data', () => {
        const date = new Date();
        billingStepsService.billingSteps[0].stepData.isDebtorChanged = false;
        billingStepsService.billingSteps[0].stepData.isCaseChanged = false;
        billingStepsService.billingSteps[0].stepData.entity = 1;
        billingStepsService.billingSteps[0].stepData.itemDate = date;
        component.getStepData();
        expect(component.hasDebtorChanged).toEqual(false);
        expect(component.hasCaseChanged).toEqual(false);
        expect(component.entityId).toEqual(1);
        expect(component.itemDate).toEqual(date);
    });

    describe('setSelected', () => {
        it('should set row as selected for all debit rows', () => {
            const row = {
                IsDiscount: false,
                Balance: 100,
                ForeignBalance: 50,
                LocalBilled: null,
                ForeignBilled: null
            };
            component.setSelected(row);
            expect(row.LocalBilled).toBe(100);
            expect(row.ForeignBilled).toBe(50);
        });
        it('should set row as selected for discount rows', () => {
            const row = {
                IsDiscount: true,
                Balance: -100,
                LocalBilled: null,
                ForeignBalance: null
            };
            component.setSelected(row);
            expect(row.LocalBilled).toBe(-100);
        });
        it('should not set row as selected for credit rows', () => {
            const row = {
                IsDiscount: false,
                Balance: -100,
                LocalBilled: null,
                ForeignBalance: null
            };
            component.setSelected(row);
            expect(row.LocalBilled).toBe(null);
        });

        it('should set row as selected for creating single bill', () => {
            const row = {
                IsDiscount: true,
                Balance: -100,
                LocalBilled: null,
                ForeignBalance: null,
                TransactionDate: new Date()
            };
            component.singleBillViewData = {
                itemType: 1,
                selectedItems: [],
                billPreparationData: {
                    entityId: 22,
                    includeRenewal: true,
                    raisedBy: {},
                    useRenewalDebtor: true,
                    fromDate: row.TransactionDate,
                    includeNonRenewal: false
                }
            };
            component.setSelected(row);
            expect(row.LocalBilled).toBe(-100);
        });

        it('should not set row as selected if TransactionDate does not lie in between', () => {
            const row = {
                IsDiscount: true,
                Balance: -100,
                LocalBilled: null,
                ForeignBalance: null,
                TransactionDate: new Date()
            };
            component.singleBillViewData = {
                itemType: 1,
                selectedItems: [],
                billPreparationData: {
                    entityId: 22,
                    includeRenewal: true,
                    raisedBy: {},
                    useRenewalDebtor: true,
                    fromDate: new Date(row.TransactionDate.getFullYear(), row.TransactionDate.getMonth(), row.TransactionDate.getDate() + 1),
                    toDate: new Date(row.TransactionDate.getFullYear(), row.TransactionDate.getMonth(), row.TransactionDate.getDate() + 2),
                    includeNonRenewal: false
                }
            };
            component.setSelected(row);
            expect(row.LocalBilled).toBeNull();
        });

    });
    describe('showEntityColumns', () => {
        beforeEach(() => {
            component.entities = [{ EntityKey: 1, EntityName: 'ABC' }, { EntityKey: 2, EntityName: 'DEF' }];
            component.allAvailableWip.next([{ caseId: 1, Balance: 100, EntityId: 1, EntityName: null }]);
        });
        it('should set Entity column value', () => {
            component.siteControls.InterEntityBilling = true;
            component.showEntityColumns();
            expect(component.allAvailableWip.getValue()[0].EntityName).toBe('ABC');
        });
        it('should not set Entity column value', () => {
            component.siteControls.InterEntityBilling = false;
            component.showEntityColumns();
            expect(component.allAvailableWip.getValue()[0].EntityName).toBe(null);
        });
    });
    describe('handleCellClick', () => {
        it('should set LocalBilled if not set', () => {
            const resultData = {
                dataItem: {
                    UniqueReferenceId: 1,
                    Balance: 100,
                    LocalBilled: null,
                    ForeignBalance: 200,
                    ForeignBilled: null
                }
            };
            const gridData: any = component.resultsGrid.wrapper.data;
            billingStepsService.billingSteps[2].stepData.allAvailableItems = [...gridData];
            billingStepsService.billingSteps[2].stepData.availableItems = [...gridData];
            component.ngOnInit();
            component.handleCellClick(resultData);
            expect(resultData.dataItem.LocalBilled).toBe(100);
            expect(resultData.dataItem.ForeignBilled).toBe(200);
            expect(component.resultsGrid.resetColumns).toBeCalled();
        });
        it('should set clear LocalBilled if already set', () => {
            const resultData = {
                dataItem: {
                    UniqueReferenceId: 1,
                    Balance: 100,
                    LocalBilled: 100,
                    ForeignBalance: 200,
                    ForeignBilled: 200
                }
            };
            const gridData: any = component.resultsGrid.wrapper.data;
            billingStepsService.billingSteps[2].stepData.allAvailableItems = [...gridData];
            billingStepsService.billingSteps[2].stepData.availableItems = [...gridData];
            component.ngOnInit();
            component.handleCellClick(resultData);
            expect(resultData.dataItem.LocalBilled).toBe(null);
            expect(resultData.dataItem.ForeignBilled).toBe(null);
            expect(component.resultsGrid.resetColumns).toBeCalled();
        });
    });
    describe('getAvailableWips', () => {
        it('should call service method to get records', () => {
            const date = new Date();
            component.entityId = 1;
            component.itemDate = date;
            component.caseList = [1];
            component.getAvailableWips();
            expect(service.getAvailableWip).toHaveBeenCalledWith(1, date, null, [1], 1, 510);
        });
    });
    describe('applyFilters', () => {
        it('should filter records based on renewal / non-renewal selected', () => {
            const resultData: any = component.resultsGrid.wrapper.data;
            component.allAvailableWip.next(resultData);
            component.filterByRenewal = component.filterByRenewalEnum.renewal;
            component.changeFilterByRenewal();
            expect(component.availableWipData.getValue().length).toBe(1);

            component.filterByRenewal = component.filterByRenewalEnum.nonRenewal;
            component.changeFilterByRenewal();
            expect(component.availableWipData.getValue().length).toBe(2);
            expect(component.resultsGrid.search).toBeCalled();
            expect(localSettings.keys.accounting.billing.wipFilterRenewal.setSession).toBeCalled();
        });
    });
    describe('showHideAmountColumns', () => {
        it('should hide foreign columns', () => {
            component.ngOnInit();
            component.showAmountColumn = component.showAmountColumnEnum.local;
            component.changeAmountColumns();
            expect(component.gridOptions.columns[9].hidden).toBe(true);
            expect(component.gridOptions.columns[10].hidden).toBe(true);
            expect(component.gridOptions.columns[11].hidden).toBe(true);
            expect(component.gridOptions.columns[12].hidden).toBe(true);
            expect(localSettings.keys.accounting.billing.showAmountColumn.setSession).toHaveBeenCalledWith(component.showAmountColumnEnum.local);
            expect(component.resultsGrid.resetColumns).toHaveBeenCalled();
        });
        it('should hide local columns', () => {
            component.ngOnInit();
            component.showAmountColumn = component.showAmountColumnEnum.foreign;
            component.changeAmountColumns();
            expect(component.gridOptions.columns[6].hidden).toBe(true);
            expect(component.gridOptions.columns[7].hidden).toBe(true);
            expect(component.gridOptions.columns[8].hidden).toBe(true);
            expect(component.gridOptions.columns[9].hidden).toBe(false);
            expect(localSettings.keys.accounting.billing.showAmountColumn.setSession).toHaveBeenCalledWith(component.showAmountColumnEnum.foreign);
            expect(component.resultsGrid.resetColumns).toHaveBeenCalled();
        });
        it('should show both local and foreign columns', () => {
            component.ngOnInit();
            component.showAmountColumn = component.showAmountColumnEnum.both;
            component.changeAmountColumns();
            expect(component.gridOptions.columns[6].hidden).toBe(false);
            expect(component.gridOptions.columns[7].hidden).toBe(false);
            expect(component.gridOptions.columns[8].hidden).toBe(false);
            expect(component.gridOptions.columns[9].hidden).toBe(false);
            expect(component.gridOptions.columns[10].hidden).toBe(false);
            expect(component.gridOptions.columns[11].hidden).toBe(false);
            expect(component.gridOptions.columns[12].hidden).toBe(false);
            expect(localSettings.keys.accounting.billing.showAmountColumn.setSession).toHaveBeenCalledWith(component.showAmountColumnEnum.both);
            expect(component.resultsGrid.resetColumns).toHaveBeenCalled();
        });
    });
    describe('get total amounts', () => {
        it('should calcualte proper total amounts', () => {
            const date1 = new Date('2000-01-01 00:00:00');
            const data = [
                {
                    id: 1,
                    CaseId: 100,
                    Balance: 100,
                    ForeignBalance: 200,
                    IsRenewal: false,
                    LocalBilled: 110,
                    LocalVariation: 10,
                    TotalTime: date1.setHours(10)
                }, {
                    id: 2,
                    CaseId: 130,
                    Balance: 100,
                    IsRenewal: true,
                    LocalBilled: 100,
                    LocalVariation: 0,
                    TotalTime: date1.setHours(2)
                },
                {
                    id: 3,
                    CaseId: 234,
                    Balance: 120,
                    IsRenewal: false,
                    LocalBilled: 120,
                    LocalVariation: 0,
                    TotalTime: null
                }
            ];
            component.availableWipData.next(data);
            component.setTotalColumns();
            expect(component.totalHours).toBe('12:00');
            expect(component.totalBalance).toBe(320);
            expect(component.totalBilled).toBe(330);
            expect(component.totalVariation).toBe(10);
        });
    });

    describe('select all and deselect all', () => {
        it('should select all', () => {

            jest.spyOn(component.resultsGrid, 'resetColumns');
            jest.spyOn(component, 'refreshGrid');
            jest.spyOn(component, 'updateStepData');
            jest.spyOn(component, 'setTotalColumns');
            component.gridOptions = {
                columns: []
            };
            component.onSelectAll();
            expect(component.resultsGrid.resetColumns).toBeCalled();
            expect(component.refreshGrid).toBeCalled();
        });

        it('should deSelect all', () => {
            jest.spyOn(component, 'refreshGrid');
            jest.spyOn(component, 'updateStepData');
            jest.spyOn(component, 'setTotalColumns');

            component.gridOptions = {
                columns: []
            };
            component.allAvailableWip.next([{ caseId: 1, Balance: 100, EntityId: 1, EntityName: null, LocalBilled: 100 }]);
            component.onDeSelectAll();
            expect(component.refreshGrid).toBeCalled();
        });

        it('should call refreshGrid ', () => {
            jest.spyOn(component.resultsGrid, 'resetColumns');
            jest.spyOn(component, 'updateStepData');
            jest.spyOn(component, 'setTotalColumns');
            component.gridOptions = {
                columns: []
            };
            component.refreshGrid();
            expect(component.resultsGrid.resetColumns).toBeCalled();
            expect(component.updateStepData).toBeCalled();
            expect(component.setTotalColumns).toBeCalled();
        });
    });
    describe('Open Billed Modal', () => {
        it('should call rowEditHandler', () => {
            const dataItem = {
                UniqueReferenceId: 1,
                Balance: 100,
                LocalBilled: 100,
                ForeignBalance: 200,
                ForeignBilled: 200
            };
            component.openBilledModal(dataItem);
            expect(component.resultsGrid.rowEditHandler).toHaveBeenCalledWith(null, 0, dataItem);
        });
        it('should open modal window', () => {
            const resultData = {
                dataItem: {
                    UniqueReferenceId: 1,
                    Balance: 100,
                    LocalBilled: 100,
                    ForeignBalance: 200,
                    ForeignBilled: 200
                }
            };
            component.localDecimalPlaces = 2;
            component.localCurrency = 'AUD';
            component.onRowAddedOrEdited(resultData);
            expect(modalService.openModal).toHaveBeenCalledWith(MaintainBilledAmountComponent, {
                animated: false,
                backdrop: 'static',
                class: 'modal-lg',
                initialState: {
                    dataItem: resultData.dataItem,
                    reasons: component.reasons,
                    isWipWriteDownRestricted: component.siteControls.WipWriteDownRestricted,
                    writeDownLimit: component.writeDownLimit,
                    isCreditNote: false,
                    localDecimalPlaces: 2,
                    localCurrency: 'AUD',
                    sellRateOnlyForNewWip: component.siteControls.SellRateOnlyforNewWIP
                }
            });
        });
    });
});