import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, Renderer2, TemplateRef, ViewChild } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { BillingService } from 'accounting/billing/billing-service';
import { BillingStepsPersistanceService } from 'accounting/billing/billing-steps-persistance.service';
import { BillingType } from 'accounting/billing/billing.model';
import { AppContextService } from 'core/app-context.service';
import { LocalSettings } from 'core/local-settings';
import { BehaviorSubject, of } from 'rxjs';
import { delay, map } from 'rxjs/operators';
import { SingleBillViewData } from 'search/wip-overview/wip-overview.data';
import { slideInOutVisible } from 'shared/animations/common-animations';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DefaultColumnTemplateType, GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, scrollableMode } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import * as _ from 'underscore';
import { MaintainBilledAmountComponent, TransactionType } from './maintain-billed-amount.component';
import { DraftItemColorEnum, WipSelectionHelper } from './wip-selection.helper';
import { WipSelectionService } from './wip-selection.service';

@Component({
    selector: 'ipx-wip-selection',
    templateUrl: './wip-selection.component.html',
    animations: [
        slideInOutVisible
    ],
    changeDetection: ChangeDetectionStrategy.OnPush,
    styleUrls: ['./wip-selection.component.scss']
})
export class WipSelectionComponent implements OnInit, AfterViewInit {
    @Input() siteControls: any;
    @Input() entities: any;
    @Input() singleBillViewData: SingleBillViewData;
    @Input() reasons: any;
    @Input() writeDownLimit: number;
    get draftItemColorEnum(): typeof DraftItemColorEnum {
        return DraftItemColorEnum;
    }
    openItemData: any;
    existingOpenItem: boolean;
    caseList: Array<number>;
    debtorData: Array<number>;
    isFinalised: boolean;
    allAvailableWip: BehaviorSubject<any>;
    availableWipData: BehaviorSubject<any>;
    gridOptions: any;
    @ViewChild('wipGrid', { static: true }) resultsGrid: IpxKendoGridComponent;
    @ViewChild('headerPopupTemplate', { static: true }) headerPopupTemplate: any;
    maintainFormGroup$ = new BehaviorSubject<FormGroup>(null);
    rowClicked = false;
    clickRowId: number;
    originalDataItem: any;
    transactionType: string;
    entityId: number;
    itemDate: Date;
    displaySeconds: boolean;
    showWebLink: boolean;
    hasCaseChanged: boolean;
    hasDebtorChanged: boolean;
    pageSize = 12;
    showSearchBar = false;
    totalHours: any;
    totalBalance: number;
    totalBilled: number;
    totalVariation: number;
    filterByRenewal: any;
    showAmountColumn: ShowAmountColumn;
    selectAllEnabled = false;
    deselectAllEnabled = false;
    localCurrency: string;
    localDecimalPlaces = 2;
    wipSelectionHelper: WipSelectionHelper;
    billCurrency: string;
    billSettings: any;
    get filterByRenewalEnum(): typeof FilterByRenewal {
        return FilterByRenewal;
    }

    get transactionTypeEnum(): typeof TransactionType {
        return TransactionType;
    }

    get showAmountColumnEnum(): typeof ShowAmountColumn {
        return ShowAmountColumn;
    }

    constructor(private readonly billingService: BillingService,
        private readonly service: WipSelectionService,
        private readonly billingStepsService: BillingStepsPersistanceService,
        private readonly cdRef: ChangeDetectorRef,
        private readonly modalService: IpxModalService,
        private readonly renderer: Renderer2,
        private readonly appContextService: AppContextService,
        private readonly localSettings: LocalSettings) {
        this.allAvailableWip = new BehaviorSubject<any>([]);
        this.availableWipData = new BehaviorSubject<any>([]);
    }

    ngOnInit(): void {
        this.billSettings = this.billingService.billSettings$.getValue();
        this.openItemData = this.billingService.openItemData$.getValue();
        this.existingOpenItem = this.openItemData.ItemTransactionId && this.openItemData.OpenItemNo;
        this.getStepData();
        this.appContextService.appContext$.subscribe(v => {
            this.showWebLink = (v.user ? v.user.permissions.canShowLinkforInprotechWeb === true : false);
            this.localDecimalPlaces = v.user.preferences.currencyFormat.localDecimalPlaces || 2;
            this.localCurrency = v.user.preferences.currencyFormat.localCurrencyCode;
            this.wipSelectionHelper = new WipSelectionHelper(this.localDecimalPlaces, this.siteControls, this.billCurrency, this.openItemData.ItemType, this.billSettings);
        });
        this.isFinalised = this.openItemData.Status === 1;
        this.showAmountColumn = this.isFinalised ? this.showAmountColumnEnum.both : this.localSettings.keys.accounting.billing.showAmountColumn.getSession;

        const availableWipData = this.billingStepsService.getStepData(3);
        const isFirstVisit = (!availableWipData.stepData || !availableWipData.stepData.allAvailableItems);
        if (isFirstVisit && this.singleBillViewData && this.singleBillViewData.billPreparationData) {
            const billPreparationData = this.singleBillViewData.billPreparationData;
            this.filterByRenewal = (billPreparationData.includeRenewal && billPreparationData.includeNonRenewal)
                || (!billPreparationData.includeRenewal && !billPreparationData.includeNonRenewal)
                ? this.filterByRenewalEnum.both
                : billPreparationData.includeRenewal ? this.filterByRenewalEnum.renewal : this.filterByRenewalEnum.nonRenewal;

            this.localSettings.keys.accounting.billing.wipFilterRenewal.setSession(this.filterByRenewal);
        } else {
            this.filterByRenewal = this.existingOpenItem ? this.filterByRenewalEnum.both : this.localSettings.keys.accounting.billing.wipFilterRenewal.getSession;
        }

        if (availableWipData.stepData) {
            this.allAvailableWip.next(availableWipData.stepData.allAvailableItems);
            this.availableWipData.next(availableWipData.stepData.availableItems);
        }
        this.gridOptions = this.buildGridOptions();
    }

    ngAfterViewInit(): void {
        setTimeout(() => {
            this.calcScrollableDivWidth();
        }, 200);
    }

    calcScrollableDivWidth = (): void => {
        if (this.resultsGrid) {
            const element = this.resultsGrid.wrapper.wrapper.nativeElement;
            let gridEle = element.getElementsByTagName('kendo-grid-list')[0];

            if (gridEle && gridEle.clientWidth === 0) {
                gridEle = element.getElementsByClassName('k-grid-header')[0];
            }
            const scrollableElement = element.getElementsByClassName(
                'k-grid-content'
            )[0];
            this.renderer.setStyle(scrollableElement, 'height', 420 + 'px');
        }
    };

    getStepData = () => {
        const data = this.billingStepsService.getStepData(1);
        if (data) {
            const caseData = data.stepData.caseData;
            if (caseData) {
                this.caseList = _.pluck(caseData, 'CaseId');
            }
            const debtorData = data.stepData.debtorData;
            if (debtorData) {
                const debtors = _.filter(debtorData, (dd: any) => {
                    return dd.DebtorCheckbox === true;
                });
                this.debtorData = _.pluck(debtors, 'NameId');
                const currencyArray = _.pluck(debtors, 'Currency');
                const uniqueArray = Array.from(new Set(currencyArray));
                this.billCurrency = uniqueArray.length > 1 ? null : debtors[0].Currency;
            }
            this.hasDebtorChanged = data.stepData.isDebtorChanged;
            this.hasCaseChanged = data.stepData.isCaseChanged;
            this.entityId = data.stepData.entity;
            this.itemDate = data.stepData.itemDate;
        }
    };

    updateStepData = () => {
        const data = this.billingStepsService.getStepData(3);
        if (data) {
            data.stepData.availableItems = [...this.availableWipData.getValue()];
            data.stepData.allAvailableItems = [...this.allAvailableWip.getValue()];
        }
    };

    setTotalColumns = () => {
        const availableWips = [...this.availableWipData.getValue()];
        this.totalBalance = availableWips.reduce((sum, current) => sum + current.Balance, 0);
        this.totalBilled = availableWips.reduce((sum, current) => sum + current.LocalBilled ?? 0, 0);
        this.totalVariation = availableWips.reduce((sum, current) => sum + current.LocalVariation ?? 0, 0);

        const totalMinutes = availableWips.reduce((sum, current) => sum + (current.TotalTime ? new Date(current.TotalTime).getMinutes() + new Date(current.TotalTime).getHours() * 60 : 0), 0);
        const hours = Math.floor(totalMinutes / 60);
        const minutes = totalMinutes % 60;
        const sMins = '' + ((minutes > 9) ? minutes : '0' + minutes);
        const sHrs = '' + ((hours > 9) ? hours : '0' + hours);
        this.totalHours = sHrs + ':' + sMins;
    };

    setSelected = (row: any) => {
        if (((!row.IsDiscount && row.Balance > 0) || (row.IsDiscount && row.Balance < 0))
            && (!this.singleBillViewData
                || ((!this.singleBillViewData.billPreparationData.fromDate || new Date(row.TransactionDate) >= this.getDateWithoutTime(this.singleBillViewData.billPreparationData.fromDate))
                    && (!this.singleBillViewData.billPreparationData.toDate || new Date(row.TransactionDate) <= this.getDateWithoutTime(this.singleBillViewData.billPreparationData.toDate))))) {
            row.LocalBilled = row.Balance;
            if (row.ForeignBalance) {
                row.ForeignBilled = row.ForeignBalance;
            }
        }
    };

    private readonly getDateWithoutTime = (inputDate: any): Date => {
        if (inputDate) {
            const date = new Date(inputDate);

            return new Date(date.getFullYear(), date.getMonth(), date.getDate());
        }

        return null;
    };

    showEntityColumns = () => {
        if (this.siteControls.InterEntityBilling) {
            const availableItems = this.allAvailableWip.getValue();
            availableItems.forEach(row => {
                if (row.EntityId) {
                    row.EntityName = _.first(_.filter(this.entities, (entity: any) => {
                        return entity.EntityKey === row.EntityId;
                    })).EntityName;
                }
            });
            this.allAvailableWip.next(availableItems);
        }
    };

    encodeLinkData = (data: any) => {
        return 'api/search/redirect?linkData=' + encodeURIComponent(JSON.stringify({ nameKey: data }));
    };

    openBilledModal = (dataItem: any): void => {
        const rowIndex = _.findIndex(this.resultsGrid.wrapper.data as _.List<any>, { UniqueReferenceId: dataItem.UniqueReferenceId });
        this.resultsGrid.rowEditHandler(null, rowIndex, dataItem);
    };

    handleCellClick(event: any): any {
        this.resetSelectDeselectAll();
        if (this.isFinalised) {

            return;
        }

        if (!event.dataItem.LocalBilled) {
            event.dataItem.LocalBilled = event.dataItem.Balance;
            if (event.dataItem.ForeignBalance) {
                event.dataItem.ForeignBilled = event.dataItem.ForeignBalance;
            }
        } else {
            this.clearBilledValues(event.dataItem);
        }
        this.refreshGrid();
    }

    clearBilledValues = (el: any) => {
        if (el.LocalVariation) {
            const rowIndex = _.findIndex(this.resultsGrid.wrapper.data as _.List<any>, { UniqueReferenceId: el.UniqueReferenceId });
            this.resultsGrid.rowCancelHandler(null, rowIndex, el);
        }
        el.LocalBilled = null;
        el.ForeignBilled = null;
        el.LocalVariation = null;
        el.ForeignVariation = null;
        el.ReasonCode = null;
        el.TransactionType = this.transactionTypeEnum.none;
        if (el.IsUsedInWriteUpCalc && el.VariableFeeType !== 1) {
            el.IsUsedInWriteUpCalc = false;
            el.DraftItemColor = null;
        }
        if (el.IsAutoWriteUp) {
            el.IsAutoWriteUp = false;
            el.DraftItemColor = null;
        }
    };

    resetSelectDeselectAll = (): void => {
        this.deselectAllEnabled = false;
        this.selectAllEnabled = false;
    };

    onSelectAll(): any {
        this.deselectAllEnabled = false;
        this.selectAllEnabled = true;
        const dataItems: any = [...this.allAvailableWip.getValue()];
        dataItems.forEach(el => {
            if (!el.LocalBilled) {
                el.LocalBilled = el.Balance;
                if (el.ForeignBalance) {
                    el.ForeignBilled = el.ForeignBalance;
                }
            }
        });
        this.availableWipData.next(dataItems);
        this.refreshGrid();
    }

    onDeSelectAll(): any {
        this.deselectAllEnabled = true;
        this.selectAllEnabled = false;
        const dataItems: any = this.allAvailableWip.getValue();
        dataItems.forEach((el) => {
            if (el.LocalBilled) {
                this.clearBilledValues(el);
            }
        });
        this.availableWipData.next(dataItems);
        this.refreshGrid();
    }

    refreshGrid(): void {
        this.updateStepData();
        this.setTotalColumns();
        this.resultsGrid.resetColumns(this.gridOptions.columns);
        this.cdRef.detectChanges();
    }

    onRowAddedOrEdited = (data: any): void => {
        data.OriginalLocalBilled = data.LocalBilled;
        const modal = this.modalService.openModal(MaintainBilledAmountComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                dataItem: data.dataItem,
                reasons: this.reasons,
                isWipWriteDownRestricted: this.siteControls.WipWriteDownRestricted,
                writeDownLimit: this.writeDownLimit,
                isCreditNote: this.openItemData.ItemType === BillingType.credit,
                localDecimalPlaces: this.localDecimalPlaces,
                localCurrency: this.localCurrency,
                sellRateOnlyForNewWip: this.siteControls.SellRateOnlyforNewWIP
            }
        });

        modal.content.onClose$.subscribe(
            (event: any) => {
                this.onCloseModal(event, data);
            }
        );
    };

    getDataRows = (): Array<any> => {
        return Array.isArray(this.resultsGrid.wrapper.data) ? this.resultsGrid.wrapper.data : (this.resultsGrid.wrapper.data).data;
    };

    onCloseModal(event, data): void {
        if (event.success) {
            const rowObject = { rowIndex: data.rowIndex, dataItem: data.dataItem, formGroup: event.formGroup } as any;
            this.gridOptions.maintainFormGroup$.next(rowObject);
            this.modalService.modalRef.hide();
            if (data.dataItem.LocalBilled !== null && this.siteControls.AutoDiscountAdjustment && !data.dataItem.IsDiscount) {
                this.wipSelectionHelper.adjustDiscount(data.dataItem, this.getDataRows());
            }
        } else {
            const rowIndex = _.findIndex(this.resultsGrid.wrapper.data as _.List<any>, { UniqueReferenceId: data.dataItem.UniqueReferenceId });
            this.resultsGrid.rowCancelHandler(null, rowIndex, data.dataItem);
        }
    }

    changeFilterByRenewal = () => {
        this.resetSelectDeselectAll();
        this.applyFilters();
        this.resultsGrid.search();
        this.localSettings.keys.accounting.billing.wipFilterRenewal.setSession(this.filterByRenewal);
        this.cdRef.markForCheck();
    };

    applyFilters = () => {
        const allAvailableItems = this.allAvailableWip.getValue();
        const filteredItems = _.filter(allAvailableItems, (wip: any) => {
            return this.filterByRenewal === this.filterByRenewalEnum.renewal ?
                wip.IsRenewal : this.filterByRenewal === this.filterByRenewalEnum.nonRenewal ? !wip.IsRenewal : true;
        });
        this.availableWipData.next(filteredItems);
        this.setTotalColumns();
    };

    changeAmountColumns = () => {
        this.resetSelectDeselectAll();
        const showHideColumn = this.showAmountColumn;
        this.localSettings.keys.accounting.billing.showAmountColumn.setSession(showHideColumn);
        this.gridOptions.columns.forEach(col => {
            if (col.field.startsWith('Local') || col.field === 'Balance') {
                col.hidden = showHideColumn === this.showAmountColumnEnum.foreign;
            }
            if (col.field.startsWith('Foreign')) {
                col.hidden = showHideColumn === this.showAmountColumnEnum.local;
            }
        });
        this.resultsGrid.resetColumns(this.gridOptions.columns);
        this.cdRef.markForCheck();
    };

    assignUniqueReferences = (availableWip: Array<any>) => {
        let i = 1;
        _.each(availableWip.filter(w => w.UniqueReferenceId === 0), (wip: any) => {
            wip.UniqueReferenceId = i;
            i = i + 1;
            this.wipSelectionHelper.setRowColors(wip, this.isFinalised);
        });
    };

    getAvailableWips = (): any => {
        const availableItems = this.allAvailableWip.getValue();
        if (this.entityId && this.itemDate) {
            let debtor = null;
            if (this.debtorData && this.debtorData.length === 1 || this.siteControls.WIPSplitMultiDebtor) {
                debtor = this.debtorData[0];
            }

            return this.service.getAvailableWip(this.entityId, this.itemDate, debtor, this.caseList, this.openItemData.StaffId, this.openItemData.ItemType)
                .pipe(map((wips: Array<any>) => {
                    if (_.any(availableItems)) {
                        wips.forEach(wip => {
                            if (!availableItems.some(s => s.TransactionId === wip.TransactionId && s.WipSeqNo === wip.WipSeqNo && s.EntityId === wip.EntityId)) {
                                if ((this.caseList.length === 0 && !wip.CaseId) || (this.caseList.length > 0 && this.caseList.some(c => c === wip.CaseId))) {
                                    if (this.siteControls.BillAllWIP && this.openItemData.ItemType === BillingType.debit) {
                                        this.setSelected(wip);
                                    }
                                    availableItems.push(wip);
                                }
                            }
                        });
                        this.assignUniqueReferences(availableItems);
                        this.allAvailableWip.next(availableItems);
                    } else {
                        const availableWips = wips.filter(x => (this.caseList.length === 0 && !x.CaseId) || (this.caseList.length > 0 && this.caseList.some(c => c === x.CaseId)));
                        if (this.siteControls.BillAllWIP && this.openItemData.ItemType === BillingType.debit) {
                            availableWips.forEach(row => {
                                this.setSelected(row);
                            });
                        }
                        this.assignUniqueReferences(availableWips);
                        this.allAvailableWip.next(availableWips);
                    }

                    this.showEntityColumns();
                    this.applyFilters();
                    this.wipSelectionHelper.getWipsForAutoWriteUp(this.availableWipData);
                    this.updateStepData();
                    this.setTotalColumns();
                    const paginatedData = {
                        data: this.availableWipData.getValue().slice(this.resultsGrid.wrapper.skip, this.resultsGrid.wrapper.skip + this.pageSize),
                        pagination: {
                            total: this.availableWipData.getValue().length
                        }
                    };

                    return paginatedData;
                }));
        }

        return of([]);
    };

    buildGridOptions(): IpxGridOptions {

        return {
            autobind: true,
            sortable: false,
            pageable: false,
            scrollableOptions: { mode: scrollableMode.virtual, height: 420, rowHeight: 15 },
            gridMessages: {
                noResultsFound: ''
            },
            read$: (queryParams) => {
                if (this.resultsGrid) {
                    this.resultsGrid.wrapper.pageSize = this.pageSize;
                }
                if (this.hasCaseChanged || this.hasDebtorChanged) {
                    if (this.caseList.length > 0) {
                        const newList = _.filter(this.allAvailableWip.getValue(), (wip: any) => {
                            return this.caseList.includes(wip.CaseId);
                        });
                        this.allAvailableWip.next(newList);
                    } else {
                        this.allAvailableWip.next([]);
                    }
                    this.billingStepsService.getStepData(1).stepData.isCaseChanged = false;
                    this.billingStepsService.getStepData(1).stepData.isDebtorChanged = false;

                    return this.getAvailableWips();
                }
                const availableItems = this.availableWipData.getValue();
                if (_.any(availableItems)) {
                    const paginatedData = {
                        data: availableItems.slice(this.resultsGrid.wrapper.skip, this.resultsGrid.wrapper.skip + this.pageSize),
                        pagination: {
                            total: availableItems.length
                        }
                    };
                    this.setTotalColumns();

                    return of(paginatedData).pipe(delay(100));
                }

                if (this.openItemData.ItemTransactionId && this.entityId && this.itemDate) {
                    return this.service.getBillAvailableWip(this.entityId, this.itemDate, this.openItemData.ItemType, this.openItemData.ItemTransactionId)
                        .pipe(map((wips: Array<any>) => {
                            this.assignUniqueReferences(wips);
                            this.allAvailableWip.next(wips);
                            this.showEntityColumns();
                            this.applyFilters();
                            this.updateStepData();
                            this.setTotalColumns();
                            const paginatedData = {
                                data: this.availableWipData.getValue().slice(this.resultsGrid.wrapper.skip, this.resultsGrid.wrapper.skip + this.pageSize),
                                pagination: {
                                    total: this.availableWipData.getValue().length
                                }
                            };

                            return paginatedData;
                        }));
                }

                return this.getAvailableWips();

            },
            columns: this.getColumns(),
            rowMaintenance: {
                rowEditKeyField: 'UniqueReferenceId'
            },
            maintainFormGroup$: this.maintainFormGroup$
        };
    }

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            title: '',
            field: 'DraftItemColor',
            template: true,
            sortable: false,
            width: 30,
            customizeHeaderTemplate: this.headerPopupTemplate
        }, {
            title: 'accounting.billing.step3.columns.caseRef',
            field: 'CaseRef',
            template: true,
            sortable: false,
            width: 150
        }, {
            title: 'accounting.billing.step3.columns.desc',
            field: 'Description',
            sortable: false,
            width: 150
        }, {
            title: 'accounting.billing.step3.columns.date',
            field: 'TransactionDate',
            sortable: false,
            width: 100,
            template: true,
            type: 'date',
            defaultColumnTemplate: DefaultColumnTemplateType.date
        }, {
            title: 'accounting.billing.step3.columns.staff',
            field: 'StaffName',
            template: true,
            sortable: false,
            width: 150
        }, {
            title: 'accounting.billing.step3.columns.hour',
            field: 'TotalTime',
            template: true,
            sortable: false,
            width: 50,
            headerClass: 'k-header-right-aligned'
        }, {
            title: 'accounting.billing.step3.columns.localBalance',
            field: 'Balance',
            template: true,
            sortable: false,
            width: 120,
            headerClass: 'k-header-right-aligned',
            hidden: this.showAmountColumn === this.showAmountColumnEnum.foreign
        }, {
            title: 'accounting.billing.step3.columns.localBilled',
            field: 'LocalBilled',
            template: true,
            sortable: false,
            width: 150,
            headerClass: 'k-header-right-aligned',
            hidden: this.showAmountColumn === this.showAmountColumnEnum.foreign
        }, {
            title: 'accounting.billing.step3.columns.localVariation',
            field: 'LocalVariation',
            template: true,
            sortable: false,
            width: 120,
            headerClass: 'k-header-right-aligned',
            hidden: this.showAmountColumn === this.showAmountColumnEnum.foreign
        }, {
            title: 'accounting.billing.step3.columns.foreignCurrency',
            field: 'ForeignCurrency',
            sortable: false,
            width: 120,
            hidden: this.showAmountColumn === this.showAmountColumnEnum.local
        }, {
            title: 'accounting.billing.step3.columns.foreignBalance',
            field: 'ForeignBalance',
            template: true,
            sortable: false,
            width: 120,
            headerClass: 'k-header-right-aligned',
            hidden: this.showAmountColumn === this.showAmountColumnEnum.local
        }, {
            title: 'accounting.billing.step3.columns.foreignBilled',
            field: 'ForeignBilled',
            template: true,
            sortable: false,
            width: 150,
            headerClass: 'k-header-right-aligned',
            hidden: this.showAmountColumn === this.showAmountColumnEnum.local
        }, {
            title: 'accounting.billing.step3.columns.foreignVariation',
            field: 'ForeignVariation',
            template: true,
            sortable: false,
            width: 120,
            headerClass: 'k-header-right-aligned',
            hidden: this.showAmountColumn === this.showAmountColumnEnum.local
        }, {
            title: 'accounting.billing.step3.columns.reason',
            field: 'ReasonCode',
            sortable: false,
            template: true,
            width: 150
        }, {
            title: 'accounting.billing.step3.columns.narrative',
            field: 'ShortNarrative',
            sortable: false,
            width: 250
        }, {
            title: 'accounting.billing.step3.columns.wipCategory',
            field: 'WipCategoryDescription',
            sortable: false,
            width: 150
        }, {
            title: 'accounting.billing.step3.columns.wipType',
            field: 'WipTypeDescription',
            sortable: false,
            width: 150
        }, {
            title: 'accounting.billing.step3.columns.wipCode',
            field: 'WipCode',
            sortable: false,
            width: 100
        }, {
            title: 'accounting.billing.step3.columns.entity',
            field: 'EntityName',
            sortable: false,
            width: 150,
            hidden: !this.siteControls.InterEntityBilling
        }, {
            title: 'accounting.billing.step3.columns.profiCentre',
            field: 'ProfitCentreDescription',
            sortable: false,
            width: 150
        }];

        return columns;
    };
}

export enum FilterByRenewal {
    renewal,
    nonRenewal,
    both
}

export enum ShowAmountColumn {
    local,
    foreign,
    both
}