import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, TemplateRef, ViewChild } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { BillingService } from 'accounting/billing/billing-service';
import { BillingStepsPersistanceService } from 'accounting/billing/billing-steps-persistance.service';
import { TypeOfDetails } from 'accounting/billing/billing.model';
import { AppContextService } from 'core/app-context.service';
import { LocalSettings } from 'core/local-settings';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { delay, map, take, takeWhile } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { ActivityEnum, BillingActivity } from '../../case-debtor.model';
import { CaseDebtorService } from '../case-debtor.service';
import { AddDebtorsComponent } from './add-debtors/add-debtors.component';
import { DebtorDiscountComponent } from './debtor-discount/debtor-discount.component';
@Component({
  selector: 'ipx-debtors',
  templateUrl: './debtors.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DebtorsComponent implements OnInit, AfterViewInit {
  mainCaseId: number;
  newCaseId: number;
  caseListId: number;
  caseIds: string;
  canFetchExistingRecords = false;
  debtorOnlySearch = false;
  debtors: any;
  preDebtors: any;
  uniqueDebtors: any;
  oldDebtors: any;
  allDebtors: Array<string>;
  gridOptions: any;
  maintainFormGroup$ = new BehaviorSubject<FormGroup>(null);
  selectDebtors$: Observable<number>;
  showWebLink: boolean;
  request: any;
  explicitDebtors = [];
  useSendBillsTo = false;
  isMainCaseChanged = true;
  canFetchOpenItem = false;
  refreshDebtorGrid = false;
  useRenewalDebtor;
  billDate: any;
  hasDebtorChangedManually = false;
  selectedDebtorId: number;
  billSettings: any;
  canSkipWarning: { differentDebtor?: boolean, changedDebtor?: boolean, draftBills?: boolean };
  selectDebtors: BehaviorSubject<number> = new BehaviorSubject<number>(null);
  @Input() siteControls: any;
  @Input() isFinalised: boolean;
  @Input() openItemRequest: any;
  @Input() activity: BillingActivity;
  @Output() readonly onCancelDebtorChange = new EventEmitter();
  @Output() readonly revertActionChange = new EventEmitter();
  @Output() readonly revertRenewalFlagChange = new EventEmitter();
  @ViewChild('debtorGrid', { static: false }) grid: any;
  @ViewChild('detailTemplate', { static: true }) detailTemplate: TemplateRef<any>;

  constructor(private readonly billingService: BillingService,
    private readonly service: CaseDebtorService,
    readonly cdRef: ChangeDetectorRef,
    readonly localSettings: LocalSettings,
    private readonly ipxNotificationService: IpxNotificationService,
    private readonly appContextService: AppContextService,
    private readonly billingStepsService: BillingStepsPersistanceService,
    private readonly modalService: IpxModalService) {
    this.selectDebtors$ = this.selectDebtors.asObservable();
  }

  ngOnInit(): void {
    this.resetActivity(true);
    this.canFetchOpenItem = this.openItemRequest.ItemTransactionId && this.openItemRequest.ItemEntityId;
    this.billDate = this.openItemRequest.billDate;
    this.canSkipWarning = { differentDebtor: true, draftBills: true, changedDebtor: true };
    this.gridOptions = this.buildGridOptions();
    this.appContextService.appContext$.subscribe(v => {
      this.showWebLink = (v.user ? v.user.permissions.canShowLinkforInprotechWeb === true : false);
    });
    this.cdRef.detectChanges();
  }

  ngAfterViewInit(): void {
    this.selectDebtors$.subscribe((res: any) => {
      if (res) {
        this.canSkipWarning = res.canSkipWarning ? res.canSkipWarning : { differentDebtor: false, changedDebtor: false };
        this.useRenewalDebtor = res.useRenewalDebtor;
        this.activity = res.activity;
        this.billDate = res.billDate;
        this.request = {
          caseId: res.mainCaseId,
          entityId: res.entityId,
          action: res.action,
          billDate: res.billDate,
          raisedByStaffId: res.raisedByStaffId,
          useRenewalDebtor: res.useRenewalDebtor,
          casesCount: res.casesCount,
          debtorKey: res.debtorKey
        };
        if (this.debtors && this.newCaseId === res.newCaseId && !res.isMainCaseChanged) {
          this.getCaseDebtorsSummary();

          return;
        }
        this.isMainCaseChanged = res.isMainCaseChanged;
        this.mainCaseId = res.mainCaseId;
        this.newCaseId = res.caseListId || (res.newCases && res.newCases.length > 1) ? null : res.newCaseId;
        this.caseListId = res.newCases ? res.caseListId : null;
        this.oldDebtors = { ...this.debtors };
        this.caseIds = res.newCases ? res.newCases.join(',') : null;
        if (this.activity.onActionChanged) {
          this.request.action = this.activity.onActionChanged.value.code;
          this.getBillSettingDetails();
        }

        this.getCaseDebtorsSummary();
      } else {
        this.clearDebtorsGrid();
      }
    });

    this.billingService.originalDebtorList$.subscribe(res => {
      if (res && this.debtors) {
        this.concateReferenceNo();
      }
    });

    this.billingService.entityChange$.subscribe(res => {
      if (res && this.request) {
        this.request.entityId = res;
        this.getBillSettingDetails();
      }
    });
  }

  buildGridOptions(): IpxGridOptions {

    return {
      autobind: true,
      navigable: true,
      sortable: false,
      reorderable: false,
      pageable: false,
      selectable: {
        mode: 'single'
      },
      read$: () => {

        return this.fetchDebtorsGridData();
      },
      maintainFormGroup$: this.maintainFormGroup$,
      rowMaintenance: {
        rowEditKeyField: 'id',
        canEdit: !this.isFinalised,
        width: '30'
      },
      enableGridAdd: !this.isFinalised,
      canAdd: !this.isFinalised,
      columns: this.getColumns(),
      showExpandCollapse: true,
      detailTemplate: this.detailTemplate,
      onDataBound: (data: any) => {
        _.each(data, (row: any) => {
          const index = data.findIndex(r => r.NameId === row.NameId);
          if (this.hasWarnings(row) || this.hasInstructions(row)) {
            this.grid.wrapper.expandRow(index);
          } else {
            this.grid.wrapper.collapseRow(index);
          }
        });
      }
    };
  }

  hasWarnings = (dataItem): boolean => {
    return dataItem && dataItem.Warnings && (dataItem.Warnings.length > 0 || dataItem.Discounts.length > 0 || this.showMultiCaseWarning(dataItem));
  };

  showMultiCaseWarning = (dataItem): boolean => {
    return !dataItem.IsMultiCaseAllowed && (this.request && this.request.casesCount > 1);
  };

  hasInstructions = (dataItem: any): boolean => {
    return dataItem.Instructions && dataItem.Instructions.length > 0;
  };

  onRowAddedOrEdited = (data: any): void => {
    this.refreshDebtorGrid = data.dataItem.status === rowStatus.Adding;
    const rows: any = this.grid.wrapper.data;
    if (rows.length > 1 && data.dataItem.status === rowStatus.Adding) {
      const notificationRef = this.ipxNotificationService.openConfirmationModal('accounting.billing.step1.confirmTitle', 'accounting.billing.step1.confirmMessage');
      notificationRef.content.confirmed$.pipe(takeWhile(() => !!notificationRef))
        .subscribe(() => {
          this.openModal(data);
        });
      notificationRef.content.cancelled$.pipe(takeWhile(() => !!notificationRef)).subscribe(() => {
        this.removeAddedEmptyRow(data.dataItem.status);
      });
    } else {
      this.openModal(data);
    }
  };

  openModal(data: any): void {
    let newData: any = {};
    newData = data.dataItem;
    if (typeof data.dataItem.FormattedNameWithCode === 'object') {
      newData.NameId = data.dataItem.FormattedNameWithCode.key;
      newData.FormattedNameWithCode = data.dataItem.FormattedNameWithCode.displayName;
    }

    const modal = this.modalService.openModal(AddDebtorsComponent, {
      animated: false,
      backdrop: 'static',
      class: 'modal-lg',
      initialState: {
        isAdding: data.dataItem.status === rowStatus.Adding,
        grid: this.grid,
        dataItem: newData,
        request: this.request,
        openItemRequest: this.openItemRequest,
        rowIndex: data.rowIndex
      }
    });
    modal.content.onClose$.subscribe(
      (event: any) => {
        this.onCloseModal(event, data);
      }
    );
  }

  onCloseModal(event, data): any {
    if (event.success) {
      const stepData = this.billingStepsService.getStepData(1).stepData;
      if (stepData && stepData.debtorData && stepData.debtorData.length > 0) {
        stepData.isDebtorChanged = true;
      }
      this.canFetchExistingRecords = true;
      Object.assign(event.debtorResponse, event.formGroup.value);
      event.formGroup.value = event.debtorResponse;
      const rowObject = { rowIndex: data.rowIndex, dataItem: data.dataItem, formGroup: event.formGroup } as any;
      this.selectedDebtorId = event.formGroup.value.NameId;
      this.changeActivity(ActivityEnum.onDebtorChanged, this.selectedDebtorId);
      this.getBillSettingDetails();
      this.gridOptions.maintainFormGroup$.next(rowObject);
      this.hasDebtorChangedManually = true;
      this.changeActivity(ActivityEnum.onDebtorChanged);
      if (!this.mainCaseId || this.refreshDebtorGrid) {
        this.getExplicitDebtors(data);
      }
      this.updateStepData(this.debtors.DebtorList);
    } else {
      this.hasDebtorChangedManually = false;
      this.removeAddedEmptyRow(data.dataItem.status);
    }
    this.cdRef.detectChanges();
  }

  removeAddedEmptyRow = (status: string): any => {
    const rows: any = this.grid.wrapper.data;
    const emptyRowIndex = rows.findIndex(x => x === undefined);
    if (emptyRowIndex > -1 && status === rowStatus.Adding) {
      this.grid.removeRow(emptyRowIndex);

      return;
    } else if (status === rowStatus.Adding) {
      this.grid.removeRow(0);
    }
  };

  private getExplicitDebtors(data: any): any {
    this.explicitDebtors = [];
    this.explicitDebtors.push(data.dataItem);
    this.debtors = {
      DebtorList: this.explicitDebtors
    };
    this.grid.wrapper.data = null;
    this.grid.search();
  }

  clearDebtorsGrid = () => {
    this.mainCaseId = null;
    this.debtors = null;
    this.grid.search();
    this.billingService.currentLanguage$.next(null);
    this.updateStepData(null);
  };

  private readonly updateStepData = (gridData: any): void => {
    if (gridData && (gridData.length === 1 || !this.siteControls.WIPSplitMultiDebtor)) {
      _.each(gridData, (item: any) => {
        item.DebtorCheckbox = true;
      });
    }
    const data = this.billingStepsService.getStepData(1);
    if (data && data.stepData) {
      data.stepData.debtorData = gridData;
    }
  };

  getCaseDebtorsSummary(): any {
    if (!this.request) { return of([]); }

    if (this.canFetchOpenItem) {
      this.grid.search();

      return;
    }

    this.getDebtorsSummary();
  }

  getDebtorsSummary(): any {
    this.debtorOnlySearch = false;
    if (this.activity.onActionChanged || this.activity.onRenewalFlagChanged) {
      this.service.getDebtors(TypeOfDetails.Summary, this.mainCaseId, null, null, this.request.action, this.canFetchOpenItem ? this.request.entityId : null, null, this.request.debtorKey, null, null, this.useRenewalDebtor)
        .subscribe((res: any) => {
          this.preDebtors = res;
          this.updatedOriginalDebtorList(this.preDebtors.DebtorList);
          this.confirmDebtorChangeAfterUserEnteredDebtor();
        });
    } else if (this.newCaseId || this.caseListId || (this.caseIds && this.caseIds.length > 0)) {
      this.service.getDebtors(TypeOfDetails.Summary, this.newCaseId, this.caseListId, this.caseIds, this.request.action, this.canFetchOpenItem ? this.request.entityId : null, null, this.request.debtorKey, null, this.useRenewalDebtor)
        .subscribe((res: any) => {
          this.preDebtors = res;
          this.updatedOriginalDebtorList(this.preDebtors.DebtorList);
          this.confirmDebtorChangeAfterUserEnteredDebtor();
        });
    } else {
      this.canFetchExistingRecords = false;
      this.debtorOnlySearch = true;
      this.grid.search();
    }
  }

  private updatedOriginalDebtorList(res: any): void {
    const mappedList = res.map(x => ({ CaseId: x.CaseId, DebtorNameId: x.NameId, NameType: x.NameType, ReferenceNo: x.ReferenceNo }));
    const originalDebtorList: any = this.billingService.originalDebtorList$.getValue();
    if (originalDebtorList && mappedList) {
      mappedList.forEach((item, index) => {
        if (!_.any(originalDebtorList, (d: any) => {
          return d.CaseId === item.CaseId && d.NameId === item.NameId && d.NameType === item.NameType;
        })) {
          originalDebtorList.push(item);
        }
      });

      this.billingService.originalDebtorList$.next(originalDebtorList);
    } else {
      this.billingService.originalDebtorList$.next(mappedList);
    }
    this.concateReferenceNo();
  }

  concateReferenceNo(): any {
    if (!this.debtors) { return; }
    const data = this.debtors.DebtorList;
    const allPreDebtors = this.billingService.originalDebtorList$.getValue();
    if (allPreDebtors) {
      for (const debtor of data) {
        const referenceArray = allPreDebtors.filter(x => x.DebtorNameId === debtor.NameId && x.NameType === debtor.NameType && x.ReferenceNo).map(x => x.ReferenceNo);
        debtor.ReferenceNo = referenceArray.length === 0 ? debtor.ReferenceNo : referenceArray.join(', ');
      }
    }
    this.grid.wrapper.data = this.debtors.DebtorList;
    this.grid.resetColumns(this.gridOptions.columns);

    return data;
  }

  getCaseDebtorDetails(): any {
    this.debtors = null;

    return this.service.getDebtors(TypeOfDetails.Details, this.mainCaseId, this.caseListId, this.caseIds, this.request.action, this.request.entityId, this.request.raisedByStaffId, this.request.debtorKey, this.useSendBillsTo, this.useRenewalDebtor, this.billDate)
      .pipe(map((res: any) => {
        this.debtors = res;
        this.concateReferenceNo();
        this.updateStepData(this.debtors.DebtorList);
        if (this.debtors && this.debtors.DebtorList.length > 0) {
          this.selectedDebtorId = this.debtors.DebtorList[0].NameId;
          this.getBillSettingDetails();
          this.billingService.currentLanguage$.next({ id: this.debtors.DebtorList[0].LanguageId, description: this.debtors.DebtorList[0].LanguageDescription });
        }

        return res.DebtorList;
      }));
  }

  getBillSettingDetails(): void {
    if (!this.request) {
      this.billingService.getBillSettings$(this.selectedDebtorId, this.mainCaseId)
        .subscribe(res => {
          this.billRuleResponseHandler(res);
        });
    } else {
      this.billingService.getBillSettings$(this.selectedDebtorId, this.mainCaseId, this.request.entityId, this.request.action)
        .subscribe(res => {
          this.billRuleResponseHandler(res);
        });
    }
  }

  billRuleResponseHandler = (res: any) => {
    this.billSettings = res.Bill;
    this.billingService.billSettings$.next(res.Bill);
    this.populateBillRule(this.activity.onLoaded || this.activity.onMainCaseChanged || this.activity.onActionChanged || this.activity.onDebtorChanged);
  };

  populateBillRule(overrideEntity: boolean): any {
    if (this.siteControls.InterEntityBilling && this.billSettings.DefaultEntityId && overrideEntity
      && (!this.request || this.billSettings.DefaultEntityId !== (this.request && this.request.entityId))) {
      this.openItemRequest.ItemEntityId = this.billSettings.DefaultEntityId;
      this.billingService.openItemData$.next(this.openItemRequest);
    }
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

  getOpenItemDebtorDetails(): any {
    return this.service.getOpenItemDebtors(this.openItemRequest.ItemEntityId, this.openItemRequest.ItemTransactionId, null)
      .pipe(map((res: any) => {
        this.debtors = res;
        this.updatedOriginalDebtorList(res.DebtorList);
        const references = [];
        res.DebtorList.forEach(el => {
          el.References.forEach(ref => {
            references.push(ref);
          });
        });
        this.billingService.originalDebtorList$.next(references);
        this.concateReferenceNo();
        this.canFetchOpenItem = false;
        this.updateStepData(this.debtors.DebtorList);
        this.billingService.currentLanguage$.next({ id: this.openItemRequest.LanguageId, description: this.openItemRequest.LanguageDescription });

        return res.DebtorList;
      }));
  }

  fetchDebtorsGridData(): any {
    if (this.grid && this.grid.wrapper.data) {
      this.grid.closeEditedRows(0);
      this.grid.rowEditFormGroups = null;
    }
    if (this.canFetchOpenItem) {
      return this.getOpenItemDebtorDetails();
    }

    if (!this.mainCaseId && this.explicitDebtors.length === 0 && !this.debtorOnlySearch) { return of([]); }

    if (this.canFetchExistingRecords) {
      const records = this.debtors ? this.debtors.DebtorList : [];
      this.updateStepData(records);

      return of(records).pipe(delay(200));
    }

    return this.getCaseDebtorDetails();
  }

  fetchExistingRecords = (): void => {
    this.canFetchExistingRecords = this.debtors && this.debtors.DebtorList.length > 0;
    this.updateStepData(this.debtors.DebtorList);
    this.grid.search();
  };

  onCheckChanged$(dataItem: any): void {
    const nameId = dataItem.NameId;
    const index = _.findIndex(this.grid.wrapper.data as _.List<any>, (data: any) => {
      return data.NameId === nameId;
    });
    _.each(this.grid.wrapper.data, (item: any) => {
      if (item.DebtorCheckbox) {
        item.DebtorCheckbox = false;
      }
    });
    this.grid.wrapper.data[index].DebtorCheckbox = true;

    const data = this.billingStepsService.getStepData(1);
    if (data && data.stepData) {
      data.stepData.debtorData[index] = this.grid.wrapper.data[index];
    }

    if (this.selectedDebtorId !== nameId) {
      this.selectedDebtorId = nameId;
      this.activity.onDebtorChanged = true;
      this.changeActivity(ActivityEnum.onDebtorChanged);
      this.getBillSettingDetails();
    }
    this.cdRef.detectChanges();
  }

  hasDifferentDebtors(): boolean {
    if (this.canSkipWarning && this.canSkipWarning.differentDebtor) { return false; }
    let showWarning = false;
    showWarning = this.checkDiffDebtorInCaseList();
    if (showWarning) { return true; }

    this.preDebtors.DebtorList.forEach(d => {
      const rows: any = this.grid.wrapper.data;
      const isDifferent = rows ? rows.some(x => x.NameId !== d.NameId) : false;
      if (isDifferent) {
        showWarning = true;

        return true;
      }
    });

    return showWarning;
  }

  hasDifferentBillToDebtor(): boolean {
    let showWarning = false;
    const rows: any = this.grid.wrapper.data;
    showWarning = this.preDebtors.DebtorList.length !== rows.length;
    if (showWarning) { return true; }

    const pendingDebtors = this.preDebtors.DebtorList.filter(x => x.BillToNameId);
    pendingDebtors.forEach(d => {
      const isSame = rows ? rows.some(x => x.NameId === d.BillToNameId) : false;
      if (!isSame) {
        showWarning = true;

        return true;
      }
    });

    return showWarning;
  }

  checkDiffDebtorInCaseList(): boolean {
    if (this.caseListId !== null) {
      let isDifferentDebtor = false;
      const mainCaseDebtors = this.preDebtors.DebtorList.filter(x => x.CaseId === this.mainCaseId).map(d => d.NameId);
      this.preDebtors.DebtorList.forEach(el => {
        isDifferentDebtor = mainCaseDebtors.some(x => x !== el.NameId);
        if (isDifferentDebtor) { return; }
      });

      return isDifferentDebtor;
    }

    return false;
  }

  showActivityWarnings = (): any => {
    if (this.activity.onActionChanged) {
      this.onActionChangeWarning();
    } else if (this.activity.onRenewalFlagChanged) {
      this.onRenewalCheckChangeWarning();
    } else {
      this.differentDebtorsWarning();
    }
  };

  confirmDebtorChangeAfterUserEnteredDebtor = () => {
    let hasDifferentDebtor = false;
    this.preDebtors.DebtorList.forEach(d => {
      const rows: any = this.grid.wrapper.data;
      const isDifferent = rows ? rows.some(x => x.NameId !== d.NameId) : false;
      if (isDifferent) {
        hasDifferentDebtor = true;
      }
    });
    if (this.hasDebtorChangedManually && hasDifferentDebtor) {
      const notificationRef = this.ipxNotificationService.openConfirmationModal('accounting.billing.step1.confirmTitle', 'accounting.billing.confirmDebtorChange');
      notificationRef.content.confirmed$.pipe(takeWhile(() => !!notificationRef))
        .subscribe(() => {
          this.hasDebtorChangedManually = false;
          this.showActivityWarnings();
        });
      notificationRef.content.cancelled$.pipe(takeWhile(() => !!notificationRef)).subscribe(() => {
        this.onCancelDebtorChange.emit(true);
        this.canFetchExistingRecords = true;
      });
    } else {
      this.showActivityWarnings();
    }
  };

  differentDebtorsWarning = (): void => {
    if (this.hasDifferentDebtors()) {
      const confirmationRef = this.ipxNotificationService.openConfirmationModal('Warning', 'accounting.billing.differentDebtorsWarning', 'Ok', 'Cancel');
      confirmationRef.content.confirmed$.pipe(take(1)).subscribe(() => {
        if (!this.debtors || (this.isMainCaseChanged || this.isMainCaseChanged === undefined)) {
          this.updatedOriginalDebtorList(this.preDebtors.DebtorList);
          this.grid.search();
          this.debtorChangedWarning(this.preDebtors.DebtorList);
        }
      });
      confirmationRef.content.cancelled$.pipe(takeWhile(() => !!confirmationRef)).subscribe(() => {
        this.onCancelDebtorChange.emit(true);
        this.canFetchExistingRecords = true;
        this.grid.search();
      });
    } else {
      this.debtorChangedWarning(this.preDebtors.DebtorList);
    }
  };

  debtorChangedWarning = (debtors: any): any => {
    if (this.siteControls.SuppressBillToPrompt) {
      this.canFetchExistingRecords = false;
      this.grid.search();

      return;
    }
    if (!this.canSkipWarning.changedDebtor && this.mainCaseId && (this.isMainCaseChanged === undefined || this.isMainCaseChanged)) {
      this.isMainCaseChanged = false;
      const changedDebtor = debtors.filter(x => x.BillToNameId && x.NameId !== x.BillToNameId)[0];
      if (changedDebtor) {
        this.preDebtors.DebtorList.forEach(e => {
          e.UseSendBillsTo = e.BillToNameId && e.NameId !== e.BillToNameId;
        });
        const requestDebtors = [...this.preDebtors.DebtorList];
        const newDebtor = changedDebtor.BillToFormattedName;
        const oldDebtor = changedDebtor.FormattedName;
        const confirmationRef = this.ipxNotificationService.openConfirmationModal('Warning', 'accounting.billing.debtorChangedWarning', 'Yes', 'No', null, { oldDebtor, newDebtor });
        confirmationRef.content.confirmed$.pipe(take(1)).subscribe(() => {
          this.applyChangedDebtors(requestDebtors);
        });
        confirmationRef.content.cancelled$.pipe(takeWhile(() => !!confirmationRef)).subscribe(() => {
          this.canFetchExistingRecords = false;
          this.grid.search();
        });
      } else {
        this.canFetchExistingRecords = false;
        this.grid.search();
      }
    } else {
      this.canFetchExistingRecords = (this.debtors && this.debtors.DebtorList);
      this.grid.search();
    }
  };

  onActionChangeWarning(): any {
    if (this.hasDifferentBillToDebtor()) {
      const confirmationRef = this.ipxNotificationService.openConfirmationModal('Warning', 'accounting.billing.renewalDetorChangeWarning', 'Yes', 'No');
      confirmationRef.content.confirmed$.pipe(take(1)).subscribe(() => {
        this.loadDebtorsOnActionChange();
      });
      confirmationRef.content.cancelled$.pipe(take(1)).subscribe(() => {
        this.revertActionChangeEvent();
      });
    }
  }

  private revertActionChangeEvent(): void {
    const action = { ...this.activity.onActionChanged };
    this.resetActivity();
    this.billingService.revertChanges$.next(action);
  }

  loadDebtorsOnActionChange(): any {
    this.canSkipWarning = { differentDebtor: true, changedDebtor: true };
    this.canFetchExistingRecords = false;
    this.changeActivity(ActivityEnum.onActionChanged, { ...this.activity.onActionChanged });
    this.grid.search();
  }

  onRenewalCheckChangeWarning(): any {
    if (this.hasDifferentDebtors()) {
      const confirmationRef = this.ipxNotificationService.openConfirmationModal('Warning', 'accounting.billing.renewalDetorChangeWarning', 'Yes', 'No');
      confirmationRef.content.confirmed$.pipe(take(1)).subscribe(() => {
        this.loadDebtorsOnRenewalFlagChange();
      });
      confirmationRef.content.cancelled$.pipe(take(1)).subscribe(() => {
        this.revertRenewalChangeEvent();
      });
    }
  }

  private revertRenewalChangeEvent(): void {
    const action = { ...this.activity.onRenewalFlagChanged };
    this.billingService.revertChanges$.next(action);
    this.resetActivity();
  }

  loadDebtorsOnRenewalFlagChange(): any {
    this.canSkipWarning = { differentDebtor: false, changedDebtor: false };
    this.canFetchExistingRecords = false;
    this.changeActivity(ActivityEnum.onRenewalFlagChanged, { ...this.activity.onRenewalFlagChanged });
    this.grid.search();
  }

  encodeLinkData = (data: any) => {
    return 'api/search/redirect?linkData=' + encodeURIComponent(JSON.stringify({ nameKey: data }));
  };

  applyChangedDebtors(preDebtors): void {
    const debtors = preDebtors.filter(x => x.CaseId === this.mainCaseId).map((x) => ({ DebtorNameId: x.NameId, UseSendBillsTo: x.UseSendBillsTo }));
    this.service.getChangedDebtors(debtors, this.request).subscribe(res => {
      if (!res.HasError) {
        this.debtors = res;
        this.fetchExistingRecords();
      }
    });
  }

  openDebtorDiscounts(debtor): any {
    if (debtor && debtor.Discounts.length > 0) {
      this.modalService.openModal(DebtorDiscountComponent, {
        animated: true,
        backdrop: 'static',
        class: 'modal-xl',
        initialState: {
          discountsList: debtor.Discounts,
          siteControls: this.siteControls
        }
      });
    }
  }

  private readonly getUniqueDebtorsList = (): any => {
    this.uniqueDebtors = this.preDebtors.DebtorList.reduce((a, b) => {
      if (!a.find(d => d.NameId === b.NameId && d.AttentionName === b.AttentionName && d.ReferenceNo === b.ReferenceNo && d.Address === b.Address)) {
        a.push(b);
      }

      return a;
    }, []);
  };

  getActingAsDebtor = (): any => {
    this.getUniqueDebtorsList();
    this.uniqueDebtors.forEach(u => {
      const debtorsData = this.preDebtors.DebtorList.filter(d => d.NameId === u.NameId && d.AttentionName === u.AttentionName && d.ReferenceNo === u.ReferenceNo && d.Address === u.Address);
      const debtorData = debtorsData.length > 0 ? debtorsData[0] : null;
      u.ActingAs = this.getFormatNameTypeBillPercentageDisplay(debtorData);
    });
  };

  getFormatNameTypeBillPercentageDisplay = (debtor: any) => {
    if (!debtor.NameTypeDescription) { return ''; }

    return `${debtor.NameTypeDescription} (${debtor.BillPercentage} %)`;
  };

  getColumns = (): Array<GridColumnDefinition> => {
    const columns: Array<GridColumnDefinition> = [{
      title: '',
      field: 'DebtorCheckbox',
      template: true,
      sortable: false,
      hidden: !this.siteControls.WIPSplitMultiDebtor
    }, {
      title: '',
      field: 'DebtorRestriction',
      template: true,
      sortable: false,
      hidden: false
    }, {
      title: '',
      field: 'Discounts',
      template: true,
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.columns.debtor',
      field: 'FormattedNameWithCode',
      template: true,
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.columns.billPercentage',
      field: 'BillPercentage',
      template: true,
      sortable: false,
      hidden: this.siteControls.WIPSplitMultiDebtor
    }, {
      title: 'accounting.billing.step1.debtors.columns.currency',
      field: 'Currency',
      template: true,
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.columns.reference',
      field: 'ReferenceNo',
      template: true,
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.columns.attention',
      field: 'AttentionName',
      template: true,
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.columns.address',
      field: 'Address',
      template: true,
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.columns.reason',
      field: 'Reason',
      template: true,
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.columns.totalCredits',
      field: 'TotalCredits',
      template: true,
      headerClass: 'k-header-right-aligned',
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.columns.allocatedWIP',
      field: 'TotalWip',
      template: true,
      headerClass: 'k-header-right-aligned',
      sortable: false
    }];

    return columns;
  };
}
