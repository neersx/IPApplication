import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { BillingService } from 'accounting/billing/billing-service';
import { BillingStepsPersistanceService } from 'accounting/billing/billing-steps-persistance.service';
import { BillingType, EntityOldNewValue } from 'accounting/billing/billing.model';
import { CaseBillNarrativeComponent } from 'accounting/time-recording/case-bill-narrative/case-bill-narrative.component';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { LocalSettings } from 'core/local-settings';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { BehaviorSubject, of } from 'rxjs';
import { delay, map, takeWhile } from 'rxjs/operators';
import { SingleBillViewData } from 'search/wip-overview/wip-overview.data';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition, TaskMenuItem } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { ActivityEnum, BillingActivity, HeaderEntityType } from '../case-debtor.model';
import { CaseDebtorService } from './case-debtor.service';
import { MaintainCaseDebtorComponent } from './maintain-case-debtor/maintain-case-debtor.component';
import { UnpostedTimeListComponent } from './unposted-time-list/unposted-time-list.component';

@Component({
    selector: 'ipx-case-debtor',
    templateUrl: './case-debtor.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseDebtorComponent implements OnInit, AfterViewInit {
    @Input() entities: any;
    @Input() draftBillSiteControl: boolean;
    @Input() siteControls: any;
    @Input() singleBillViewData: SingleBillViewData;
    @ViewChild('caseGrid', { static: false }) grid: IpxKendoGridComponent;
    @ViewChild('debtorsComponent', { static: false }) debtorsComponent: any;
    gridOptions: IpxGridOptions;
    billingType: number;
    billingTypeEnum = BillingType;
    showSearchBar = true;
    itemTransactionId: number;
    entityNo: number;
    modalRef: BsModalRef;
    openItemData: any;
    currency: string;
    records: any = [];
    oldRecords: any;
    existingOpenItem: boolean;
    selectedCase: number;
    isFinalised: boolean;
    oldDebtorRequest: any;
    maintainFormGroup$ = new BehaviorSubject<FormGroup>(null);
    allowedActions: Array<string>;
    taskItemsForCaseDebtors: any;
    taskItems: Array<TaskMenuItem>;
    loadDebtors = false;
    canSkipWarning: { differentDebtor?: boolean, changedDebtor?: boolean, draftBills?: boolean };
    isNewCase: boolean;
    activity: BillingActivity;

    constructor(private readonly billingService: BillingService,
        private readonly service: CaseDebtorService,
        readonly cdRef: ChangeDetectorRef,
        private readonly modalService: IpxModalService,
        readonly localSettings: LocalSettings,
        private readonly ipxNotificationService: IpxNotificationService,
        private readonly notificationService: NotificationService,
        private readonly billingStepsService: BillingStepsPersistanceService) { }

    // tslint:disable-next-line: cyclomatic-complexity
    ngOnInit(): void {
        this.resetActivity(true);
        this.openItemData = this.billingService.openItemData$.getValue();
        this.billingType = this.openItemData.ItemType;
        this.itemTransactionId = this.openItemData.ItemTransactionId;
        this.existingOpenItem = this.openItemData.ItemTransactionId && this.openItemData.OpenItemNo;
        if (this.existingOpenItem) {
            this.canSkipWarning = { differentDebtor: true, draftBills: true, changedDebtor: true };
            this.changeActivity(ActivityEnum.onOpenItemLoaded);
        }
        this.entityNo = this.openItemData.ItemEntityId;
        this.currency = this.openItemData.LocalCurrencyCode;
        this.isFinalised = this.openItemData.Status === 1;
        if (this.singleBillViewData) {
            this.records = this.singleBillViewData.selectedCases;
            this.updateStepData(this.records, this.openItemData);
            this.getOpenItemCaseDebtors(this.records, this.singleBillViewData.debtorKey);
            this.setMainCaseRow(this.records);
        }
        this.cdRef.markForCheck();
        this.gridOptions = this.buildGridOptions();
        this.cdRef.detectChanges();
    }

    ngAfterViewInit(): void {
        this.loadDebtors = true;
    }

    resetActivity(onLoad = false): void {
        this.activity = { onLoaded: onLoad, onActionChanged: false, onMainCaseChanged: false, onDebtorChanged: false, onRenewalFlagChanged: false, onOpenItemLoaded: false };
    }

    changeActivity(activity: ActivityEnum, value: any = null): void {
        this.resetActivity();
        if (activity === ActivityEnum.onActionChanged) {
            this.activity.onActionChanged = value;
        }
        if (activity === ActivityEnum.onDebtorChanged) {
            this.activity.onDebtorChanged = value ? value : true;
        }
        if (activity === ActivityEnum.onMainCaseChanged) {
            this.activity.onMainCaseChanged = value ? value : true;
        }
        if (activity === ActivityEnum.onRenewalFlagChanged) {
            this.activity.onRenewalFlagChanged = value ? value : true;
        }
    }

    displayTaskItems = (dataItem: any): void => {
        this.taskItems = [];
        this.taskItems.push({
            id: 'mainCase',
            text: 'accounting.billing.step1.taskMenu.mainCase',
            icon: 'cpa-icon cpa-icon-check',
            action: this.setAsMainCase,
            disabled: (dataItem && dataItem.IsMainCase) || this.isFinalised
        });

        this.taskItems.push({
            id: 'caseNarrative',
            text: 'accounting.billing.step1.taskMenu.caseNarrative',
            icon: 'cpa-icon cpa-icon-items-o',
            action: this.maintainCaseBillNarrative

        });

        this.taskItems.push({
            id: 'delete',
            text: 'accounting.billing.step1.taskMenu.removeCase',
            icon: 'cpa-icon cpa-icon-trash',
            action: this.onCaseRowDelete,
            disabled: this.isFinalised
        });
    };

    onMenuItemSelected = (menuEventDataItem: any): void => {
        menuEventDataItem.event.item.action(menuEventDataItem.dataItem);
    };

    setAsMainCase = (dataItem: any): void => {
        this.canSkipWarning = { differentDebtor: true, draftBills: true, changedDebtor: false };
        this.changeActivity(ActivityEnum.onMainCaseChanged);
        this.toggleMainCase(dataItem.CaseId, true);
    };

    onCaseRowDelete = (data: any): void => {
        const originalDebtorList: any = this.billingService.originalDebtorList$.getValue();
        if (originalDebtorList) {
            const debtorList = originalDebtorList.filter(x => x.CaseId !== data.CaseId);
            this.billingService.originalDebtorList$.next(debtorList);
        }
        let mainCaseDeleted = false;
        this.records = this.getValidRows();
        this.records = _.filter(this.records, (item: any) => {
            return data.CaseId !== item.CaseId;
        });
        this.grid.removeRow(data._rowIndex);
        this.changeActivity(ActivityEnum.OnCaseDeleted);
        if (data.IsMainCase && this.records.length > 0) {
            const firstCase = this.records[0];
            if (firstCase) {
                mainCaseDeleted = true;
                this.changeActivity(ActivityEnum.onMainCaseChanged);
                this.toggleMainCase(firstCase.CaseId, true);
            }
        }
        this.existingOpenItem = false;
        this.oldRecords = this.records;
        this.updateStepData(this.records);
        this.billingStepsService.getStepData(1).stepData.isCaseChanged = true;
        this.grid.search();
        if (this.records.length === 0) {
            this.billingService.clearValidAction();
            this.resetWarnings();
            this.debtorsComponent.selectDebtors.next(null);
        } else {
            this.canSkipWarning = { differentDebtor: true, draftBills: true, changedDebtor: !mainCaseDeleted };
            const request = {
                mainCaseId: this.getMainCaseId(),
                entityId: this.entityNo,
                action: this.openItemData.Action,
                useRenewalDebtor: this.openItemData.ShouldUseRenewalDebtor,
                billDate: this.openItemData.ItemDate,
                raisedByStaffId: this.openItemData.raisedByStaffId,
                newCaseId: this.getMainCaseId(),
                newCases: null,
                isMainCaseChanged: mainCaseDeleted
            };
            this.displayCaseDebtors(request);
        }
    };

    resetWarnings = (): void => {
        this.canSkipWarning = { differentDebtor: false, draftBills: false, changedDebtor: false };
    };

    maintainCaseBillNarrative = (dataItem: any): void => {
        const initialState = {
            caseKey: dataItem.CaseId
        };
        this.modalRef = this.modalService.openModal(CaseBillNarrativeComponent, {
            focus: true,
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState
        });
        this.modalRef.content.onClose$.pipe(takeWhile(() => !!this.modalRef)).subscribe(value => {
            if (value) {
                this.notificationService.success('accounting.time.caseNarrative.success');
            }
        });
    };

    buildGridOptions(): IpxGridOptions {

        return {
            autobind: true,
            navigable: true,
            sortable: false,
            reorderable: false,
            showContextMenu: true,
            pageable: {
                pageSizes: [5, 10, 20, 50],
                pageSizeSetting: this.localSettings.keys.currencies.pageSize
            },
            read$: () => {
                if (this.records.length === 0 && this.existingOpenItem) {
                    const data = this.service.getOpenItemCases(this.entityNo, this.itemTransactionId)
                        .pipe(map((res: any) => {
                            if (res) {
                                this.records = res;
                                this.updateStepData(this.records, this.openItemData);
                                this.getOpenItemCaseDebtors(res);
                                this.setMainCaseRow(res);

                                return res;
                            }
                        }));

                    this.updateStepData(this.records);

                    return data;
                }
                this.updateStepData(this.records);

                return of(this.records).pipe(delay(200));
            },
            maintainFormGroup$: this.maintainFormGroup$,
            rowMaintenance: {
                canEdit: false,
                canDelete: false,
                rowEditKeyField: 'id'
            },
            enableGridAdd: !this.isFinalised,
            canAdd: !this.isFinalised,
            columns: this.getColumns()
        };
    }

    getMainCaseId = (res?: any): number => {
        const mainCase = this.getMainCase(res);

        return mainCase ? mainCase.CaseId : null;
    };

    getMainCase = (res?: any): any => {
        let mainCase: any;
        if (!res) {
            if (this.records) {
                const mainCaseRecords = this.records.filter(x => x.IsMainCase);
                mainCase = mainCaseRecords.length > 0 ? mainCaseRecords[0] : this.records[0];
            }

            return mainCase ? mainCase : null;
        }
        const mainCaseRecords = res.filter(x => x.IsMainCase);
        mainCase = mainCaseRecords ? mainCaseRecords[0] : res[0];

        return mainCase;
    };

    getOpenItemCaseDebtors(res, debtorKey: number = null): void {
        const mainCase = this.getMainCase();
        this.selectedCase = mainCase ? mainCase.CaseId : null;
        const request = {
            mainCaseId: this.getMainCaseId(),
            entityId: this.entityNo,
            action: this.openItemData.Action,
            useRenewalDebtor: this.openItemData.ShouldUseRenewalDebtor,
            billDate: this.openItemData.ItemDate,
            raisedByStaffId: this.openItemData.raisedByStaffId,
            newCaseId: this.selectedCase,
            newCases: null,
            isMainCaseChanged: undefined,
            debtorKey
        };
        this.displayCaseDebtors(request);
    }

    updateStepData = (gridData: any, openItem: any = null): void => {
        const data = this.billingStepsService.getStepData(1);
        if (data) {
            data.stepData.caseData = [...gridData];
            data.stepData.openItem = openItem;
        }
    };

    onRowAddedOrEdited = (data: any): void => {
        const rows: any = this.grid.wrapper.data;
        this.oldRecords = rows.filter(x => x && x.CaseId);
        this.isNewCase = this.oldRecords.length === 0;
        const modal = this.modalService.openModal(MaintainCaseDebtorComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                dataItem: data.dataItem ? data.dataItem : data,
                isAdding: data.dataItem.status === rowStatus.Adding && !data.dataItem.CaseId,
                rowIndex: data.rowIndex,
                entityNo: this.entityNo,
                raisedByStaffId: this.openItemData.StaffId,
                draftBillSiteControl: this.draftBillSiteControl,
                grid: this.grid
            }
        });
        modal.content.onClose$.subscribe(
            (event: any) => {
                this.onCloseModal(event, data);
            }
        );
    };

    toggleMainCase(caseId?, mainCaseChanged = false): void {
        const rows: any = this.grid.wrapper.data;
        if (caseId) {
            this.selectedCase = caseId;
            rows.forEach(item => {
                item.IsMainCase = item.CaseId === caseId;
            });
            const data = {
                mainCaseId: caseId,
                entityId: this.entityNo,
                action: this.openItemData.Action,
                useRenewalDebtor: this.openItemData.ShouldUseRenewalDebtor,
                raisedByStaffId: this.openItemData.raisedByStaffId,
                billDate: this.openItemData.ItemDate,
                newCaseId: caseId,
                newCases: null,
                isMainCaseChanged: mainCaseChanged
            };
            this.displayCaseDebtors(data);
        } else {
            const hasMainCase = rows.some(x => x && x.IsMainCase);
            if (!hasMainCase && rows.length > 0) {
                rows[0].IsMainCase = true;
                this.records = rows;
                this.selectedCase = rows[0].IsMainCase;
                this.grid.search();
            }
        }
        this.oldRecords = this.records;
        this.cdRef.detectChanges();
    }

    onCloseModal(event, data): void {
        if (event.success) {
            const stepData = this.billingStepsService.getStepData(1).stepData;
            if (stepData && (stepData.caseData && stepData.caseData.length > 0) || (stepData.debtorData && stepData.debtorData.length > 0)) {
                stepData.isCaseChanged = true;
            }
            this.canSkipWarning = { differentDebtor: false, changedDebtor: false };
            this.existingOpenItem = false;
            this.grid.wrapper.data = event.rows;
            this.records = [...event.rows];
            event.newCases = event.newCases === '' ? event.rows.map(x => x.CaseId) : event.newCases.split(', ');
            this.grid.search();
            this.selectedCase = event.mainCase;
            event.isMainCaseChanged = event.isFirstCaseAdded ? undefined : false;
            this.displayCaseDebtors(event);
            this.grid.wrapper.closeRow(data.rowIndex);
            if (this.modalService && this.modalService.modalRef) {
                this.modalService.modalRef.hide();
            }
            this.showWarnings(event.warnings);
            if (this.isNewCase) {
                this.setMainCaseRow();
            }
        } else {
            this.removeAddedEmptyRow();
        }
        this.cdRef.detectChanges();
    }

    setMainCaseRow = (data: any = null) => {
        const dataRows = data != null ? data : this.grid.wrapper.data;
        const mainCaseRow = _.first(_.filter(dataRows, (row: any) => {
            return row.IsMainCase;
        }));
        if (mainCaseRow) {
            this.billingService.setValidAction(mainCaseRow);
        }
    };

    onCaseHeaderChange = (header): void => {
        const headerForm = header.form;
        const values: EntityOldNewValue = header.values;
        this.openItemData.Action = headerForm.currentAction ? headerForm.currentAction.code : null;
        this.entityNo = headerForm.entity;
        this.openItemData.raisedByStaffId = headerForm.raisedBy ? headerForm.raisedBy.key : null;
        this.openItemData.ShouldUseRenewalDebtor = headerForm.useRenewalDebtor;
        if (this.openItemData.Action && (values.entity === HeaderEntityType.RenewalCheckBox || values.entity === HeaderEntityType.ActionPicklist) && this.getValidRows().length > 0) {
            this.loadDebtorsOnHeaderChange(values);
        }
    };

    loadDebtorsOnHeaderChange(value: any): void {
        if (value.entity === HeaderEntityType.RenewalCheckBox) {
            this.loadDebtorsOnRenewalDebtorCheckBox(value);
        } else if (value.entity === HeaderEntityType.ActionPicklist) {
            this.loadDebtorsOnActionChange(value);
        }
    }

    private loadDebtorsOnRenewalDebtorCheckBox(value): void {
        this.canSkipWarning = { differentDebtor: false, draftBills: true };
        this.changeActivity(ActivityEnum.onRenewalFlagChanged, value);
        this.displayCaseDebtors(this.oldDebtorRequest);
    }

    private loadDebtorsOnActionChange(value): void {
        this.canSkipWarning = { differentDebtor: true, changedDebtor: true, draftBills: true };
        this.changeActivity(ActivityEnum.onActionChanged, value);
        this.oldDebtorRequest.action = value.value.code;
        this.displayCaseDebtors(this.oldDebtorRequest);
    }

    displayCaseDebtors = (modalData: any): void => {
        const casesCount = this.getValidRows().length;
        const mainCase = this.getMainCase();
        modalData.action = modalData.action ?? mainCase ? mainCase.OpenAction : null;
        setTimeout(() => {
            const request = {
                mainCaseId: modalData.mainCaseId,
                entityId: this.entityNo,
                action: this.existingOpenItem ? this.openItemData.Action : modalData.action,
                useRenewalDebtor: this.openItemData.ShouldUseRenewalDebtor,
                billDate: this.openItemData.ItemDate,
                raisedByStaffId: this.openItemData.raisedByStaffId,
                newCaseId: modalData.newCaseId,
                caseListId: modalData.caseListId,
                newCases: modalData.newCases,
                isMainCaseChanged: modalData.isMainCaseChanged,
                canSkipWarning: this.canSkipWarning,
                activity: this.activity,
                casesCount,
                debtorKey: modalData.debtorKey
            };
            this.debtorsComponent.selectDebtors.next(request);
            this.oldDebtorRequest = request;
        }, 200);
    };

    showWarnings(warning: any): any {
        this.draftBillWarning(warning.draftBills);
    }

    removeAddedEmptyRow = (row?: any): any => {
        const rows: any = this.grid.wrapper.data;
        const emptyRowIndex = rows.findIndex(x => x && x !== undefined && !x.CaseId);
        if (emptyRowIndex > -1) {
            this.grid.rowDeleteHandler(this, emptyRowIndex, row.formGroup);
        }
        if (rows.length > 0) {
            this.existingOpenItem = false;
        }
        this.records = this.grid.wrapper.data;
        this.grid.search();
        this.cdRef.detectChanges();
    };

    draftBillWarning = (bills): any => {
        if (this.draftBillSiteControl && bills.length > 0) {
            this.ipxNotificationService.openAlertListModal('Warning', 'accounting.billing.draftBillValidation', 'Ok', '', bills, bills);
        }
    };

    revertNewCaseChange(): any {
        this.records = this.oldRecords;
        this.grid.search();
    }

    getValidRows = (): [] => {
        const rows: any = this.grid ? this.grid.wrapper.data : null;
        if (!rows) { return []; }

        return rows.filter(x => x && x !== undefined && x.status !== rowStatus.deleting);
    };

    openUnpostedTimeList = (unpostedTimeList: any, caseReference: string): any => {
        this.modalService.openModal(UnpostedTimeListComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                unpostedCaseTimeList: unpostedTimeList,
                caseIRN: caseReference,
                total: unpostedTimeList.reduce((sum, current) => sum + current.TimeValue, 0)

            }
        });
    };

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            title: '',
            field: 'UnpostedTimeList',
            template: true,
            sortable: false
        }, {
            title: 'accounting.billing.step1.columns.irn',
            field: 'CaseReference',
            template: true
        }, {
            title: 'accounting.billing.step1.columns.title',
            field: 'Title'
        }, {
            title: 'accounting.billing.step1.columns.caseType',
            field: 'CaseTypeDescription'
        }, {
            title: 'accounting.billing.step1.columns.country',
            field: 'Country'
        }, {
            title: 'accounting.billing.step1.columns.propertyType',
            field: 'PropertyTypeDescription'
        }, {
            title: 'accounting.billing.step1.columns.totalCredits',
            field: 'TotalCredits',
            template: true,
            headerClass: 'k-header-right-aligned'
        }, {
            title: 'accounting.billing.step1.columns.unlockedWIP',
            field: 'UnlockedWip',
            template: true,
            headerClass: 'k-header-right-aligned'
        }, {
            title: 'accounting.billing.step1.columns.totalWIP',
            field: 'TotalWip',
            sortable: true,
            template: true,
            headerClass: 'k-header-right-aligned'
        }];

        return columns;
    };
}
