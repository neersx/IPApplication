import { DatePipe } from '@angular/common';
import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  OnInit,
  ViewChild
} from '@angular/core';
import { AbstractControl, FormBuilder, FormControl, FormGroup } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { CaseBillNarrativeComponent } from 'accounting/time-recording/case-bill-narrative/case-bill-narrative.component';
import { WarningCheckerService } from 'accounting/warnings/warning-checker.service';
import { WarningService } from 'accounting/warnings/warning-service';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import { BehaviorSubject, of } from 'rxjs';
import { distinctUntilChanged, switchMap, take, takeUntil } from 'rxjs/operators';
import { dataTypeEnum } from 'shared/component/forms/ipx-data-type/datatype-enum';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { IpxKendoGridComponent, rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { SplitWipHelper } from './split-wip-helper';
import { SplitWipArray, SplitWipData, SplitWipItem, SplitWipType } from './split-wip.model';
import { SplitWipService } from './split-wip.service';

@Component({
  selector: 'ipx-split-wip',
  templateUrl: './split-wip.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [IpxDestroy, SplitWipService]
})
export class SplitWipComponent implements OnInit, AfterViewInit {
  entityKey: number;
  transKey: number;
  wipSeqKey: number;
  viewData: any;
  splitWipData: SplitWipData;
  form: any;
  activityExtendQuery: any;
  caseExtendQuery: any;
  hasMultipleDebtors = false;
  defaultprofitCentre: any;
  externalScope: any;
  isForeignCurrency = false;
  originalAmount: number;
  validRows: any;
  allocatedAmount = 0;
  activeIndex = 0;
  activeDataItem: any;
  isAdding = true;
  disableAll = false;
  showApply = true;
  disableClear = false;
  dataType: any = dataTypeEnum;
  siteControls = { SplitWipMultiDebtor: false, WipWriteDownRestricted: false };
  splitByType: SplitWipType = SplitWipType.amount;
  oldSplitByType: SplitWipType = SplitWipType.amount;
  splitWipTypeEnum = SplitWipType;
  maintainFormGroup$ = new BehaviorSubject<FormGroup>(null);
  splitWipNewData: Array<SplitWipItem>;
  gridOptions: IpxGridOptions;
  isAmountDisabled = false;
  isPercentageDisabled = true;
  numericStyle = { maxWidth: '180px', marginLeft: '-10px' };
  percentStyle = { maxWidth: '180px', marginLeft: '-8px' };
  errorStyle = { marginLeft: '4px' };
  splitWipHelper: SplitWipHelper;
  decimalPlaces: number;
  applyClicked = false;
  @ViewChild('caseEl', { static: false }) caseEl: any;
  @ViewChild('nameEl', { static: false }) nameEl: any;
  @ViewChild('staffEl', { static: false }) staffEl: any;
  @ViewChild('amountCtrl', { static: false }) amountCtrl: any;
  @ViewChild('percentCtrl', { static: false }) percentCtrl: any;
  @ViewChild('ipxKendoGridRef', { static: false }) grid: IpxKendoGridComponent;
  @ViewChild('splitWipheader', { static: false }) splitWipheader: any;

  constructor(
    private readonly service: SplitWipService,
    private readonly cdRef: ChangeDetectorRef,
    private readonly notificationService: NotificationService,
    private readonly ipxNotificationService: IpxNotificationService,
    private readonly translate: TranslateService,
    private readonly fb: FormBuilder,
    private readonly destroy$: IpxDestroy,
    private readonly warningChecker: WarningCheckerService,
    private readonly windowParentMessagingService: WindowParentMessagingService,
    private readonly datePipe: DatePipe,
    private readonly warningService: WarningService,
    private readonly modalService: IpxModalService
  ) {
    this.activityExtendQuery = this.activitiesFor.bind(this);
    this.caseExtendQuery = this.casesFor.bind(this);
    this.externalScope = this.nameExternalScopeForCase.bind(this);
  }

  ngOnInit(): void {
    this.applyClicked = false;
    this.splitWipNewData = [];
    this.service.getWipSupportData$().pipe(takeUntil(this.destroy$)).subscribe((response: any) => {
      this.viewData = response;
      this.siteControls.SplitWipMultiDebtor = response.splitWipMultiDebtor;
      this.siteControls.WipWriteDownRestricted = response.wipWriteDownRestricted;
      this.warningService.restrictOnWip = this.viewData.restrictOnWIP;
      this.warningChecker.restrictOnWip = this.viewData.restrictOnWIP;
    });
  }

  ngAfterViewInit(): void {
    this.getSplitWipDetails();
  }

  casesFor(query: any): void {
    const selectedName = this.name ? this.name.value : null;
    const extended = _.extend({}, query, {
      nameKey: selectedName ? selectedName.key : null
    });

    return extended;
  }

  activitiesFor(query: any): void {
    const selectedCase = this.case ? this.case.value : null;
    const extended = _.extend({}, query, {
      caseId: selectedCase ? selectedCase.key : null
    });

    return extended;
  }

  nameExternalScopeForCase(): any {
    if (this.name && !!this.name.value) {
      return {
        label: 'Instructor',
        value: this.name.value ? this.name.value.displayName : null
      };
    }
  }

  checkErrorState = (): any => {
    if (this.form.touched && this.form.controls.amount.errors) {
      this.amountCtrl.showError$.next(true);
    } else {
      this.amountCtrl.showError$.next(false);
    }

    if (this.form.touched && this.form.controls.splitPercent.errors) {
      this.percentCtrl.showError$.next(true);
    } else {
      this.percentCtrl.showError$.next(false);
    }

    return false;
  };

  createFormGroup = (): FormGroup => {
    this.form = this.fb.group({
      id: new FormControl(this.activeIndex),
      name: new FormControl(),
      case: new FormControl(),
      staff: new FormControl(),
      amount: new FormControl(null),
      localValue: new FormControl(),
      foreignValue: new FormControl(),
      splitPercent: new FormControl(null),
      profitCentre: new FormControl(),
      exchRate: new FormControl(this.isForeignCurrency ? this.splitWipHelper.round(this.splitWipData.foreignBalance / this.splitWipData.balance, 4) : null),
      narrative: this.splitWipData ? new FormControl({ key: this.splitWipData.narrativeKey, code: this.splitWipData.narrativeCode, value: this.splitWipData.narrativeTitle }) : new FormControl(),
      debitNoteText: new FormControl(this.splitWipData.debitNoteText)
    });
    this.showApply = true;
    setTimeout(() => {
      if (this.caseEl) {
        this.caseEl.el.nativeElement.querySelector('input').focus();
      }
    }, 300);

    return this.form;
  };

  get name(): AbstractControl {
    return this.form.get('name');
  }
  get case(): AbstractControl {
    return this.form.get('case');
  }
  get staff(): AbstractControl {
    return this.form.get('staff');
  }
  get profitCentre(): AbstractControl {
    return this.form.get('profitCentre');
  }
  get narrative(): AbstractControl {
    return this.form.get('narrative');
  }

  caseNameMandatoryValidation(): boolean {
    if (this.form && this.form.controls) {
      if (!this.form.controls.case.value && !this.form.controls.name.value) {
        this.form.controls.case.setErrors({ caseOrNameRequired: true });
        this.form.controls.case.markAsTouched();
        this.form.controls.case.markAsDirty();
        this.form.controls.name.setErrors({ caseOrNameRequired: true });
        this.form.controls.name.markAsTouched();
        this.form.controls.name.markAsDirty();
        this.validateStaff();
        this.clickEvents();

        return false;
      }
      this.form.controls.case.setErrors(null);
      this.form.controls.name.setErrors(null);

      return true;
    }
  }

  validateStaff(): boolean {
    if (!this.form.controls.staff.value) {
      this.form.controls.staff.setErrors({ required: true });
      this.form.controls.staff.markAsTouched();
      this.form.controls.staff.markAsDirty();
      this.staffEl.el.nativeElement.querySelector('input').click();

      return false;
    }
    this.form.controls.staff.setErrors(null);

    return true;
  }

  clickEvents(): void {
    this.caseEl.el.nativeElement.querySelector('input').click();
    this.nameEl.el.nativeElement.querySelector('input').click();
  }

  applyForm(): void {
    this.applyClicked = true;
    if (this.form.invalid || !this.caseNameMandatoryValidation() || !this.validateStaff()) { return; }

    if (this.splitByType !== SplitWipType.equally) {
      if (this.isTotalAmountAllocated()) { return; }

      const val = this.splitWipHelper.setLocalAndForeignValue(this.form, this.splitByType);
      if (!val) {
        this.checkErrorState();
        this.cdRef.markForCheck();

        return;
      }
    }

    const rowIndex = this.activeIndex;
    const rowObject = {
      rowIndex,
      dataItem: this.activeDataItem,
      formGroup: this.form
    } as any;
    this.splitWipHelper.adjustLocalValue(rowObject, this.validRows, this.form, this.activeDataItem, this.splitByType, this.isAdding);
    this.gridOptions.maintainFormGroup$.next(rowObject);
    this.applyClicked = false;
    if (this.splitByType === SplitWipType.equally) {
      this.splitItemsEqually();
    }
    this.splitWipheader.unallocatedAmount.next(this.originalAmount - this.appliedAmount);
    this.reset();
    this.splitWipheader.setReasonDirty();
    this.disableClear = this.splitWipheader.unallocatedAmount.getValue() === 0 && this.splitByType !== SplitWipType.equally;
    this.cdRef.detectChanges();
  }

  onAllocateRemainder(): void {
    const amount = this.originalAmount - this.appliedAmount;
    this.setAmount(amount);
    this.form.markAsDirty();
    this.splitWipheader.unallocatedAmount.next(0);
    this.setPercentage();
    this.checkErrorState();
    this.cdRef.markForCheck();
  }

  get appliedAmount(): number {
    if (!this.grid) { return 0; }
    this.validRows = this.getValidRows();

    return this.splitWipHelper.appliedAmount(this.validRows, this.isAdding, this.activeDataItem ? this.activeDataItem.amount : 0);
  }

  get appliedPercent(): number {
    if (!this.grid) { return 0; }
    this.validRows = this.getValidRows();

    return this.splitWipHelper.appliedPercent(this.validRows, this.isAdding, this.activeDataItem.splitPercent);
  }

  onAmountChange = (value): any => {
    if (!value) {
      this.form.controls.amount.setErrors({ required: true });
      this.checkErrorState();

      return;
    }
    this.form.controls.amount.setErrors(null);
    this.checkErrorState();
    if (this.isTotalAmountAllocated() || value < 0) {
      this.setAmount(0);

      return;
    }

    this.splitWipheader.unallocatedAmount.next((this.originalAmount - this.appliedAmount) - value);

    if (this.form.controls.amount.value > (this.originalAmount - this.appliedAmount)) {
      this.form.controls.amount.markAsPristine();
      this.setAmount(this.originalAmount - this.appliedAmount);
      this.splitWipheader.unallocatedAmount.next(this.originalAmount - this.appliedAmount);
    }

    this.setPercentage();
    this.cdRef.markForCheck();
  };

  onPercentageChange = (value): any => {
    if (!value) {
      this.form.controls.splitPercent.setErrors({ required: true });
      this.checkErrorState();

      return;
    }
    this.form.controls.amount.setErrors(null);
    this.checkErrorState();
    const items = this.getValidRows();
    const splitPercentageBalance = this.splitWipHelper.splitPercentageBalance(items);
    if (splitPercentageBalance < 0) {
      this.setPercent(value + splitPercentageBalance);
    }

    if (this.splitByType === SplitWipType.percentage) {
      if (value > (100 - this.appliedPercent)) {
        this.setPercent(100 - this.appliedPercent);
        this.splitWipheader.unallocatedAmount.next(0);
      }
      if (this.isForeignCurrency) {
        this.form.controls.amount.setValue(this.splitWipHelper.round(this.splitWipData.foreignBalance * value / 100, this.splitWipData.foreignDecimalPlaces));
      } else {
        this.form.controls.amount.setValue(this.splitWipHelper.round(this.splitWipData.balance * value / 100, this.splitWipData.localDeciamlPlaces));
      }
    }
    this.cdRef.markForCheck();
  };

  setPercentage(): void {
    this.form.controls.splitPercent.markAsDirty();
    this.form.patchValue({ splitPercent: this.splitWipHelper.round((+this.form.controls.amount.value * 100) / +this.originalAmount, 2) });
  }

  getDefaultWipFromCase(caseKey): any {
    this.service.getDefaultWipItems$(caseKey, this.splitWipData.wipCategoryCode).subscribe(res => {
      if (res) {
        this.form.patchValue({
          name: { key: res.nameKey, code: res.nameCode, displayName: res.name },
          staff: { key: res.staffKey, code: res.staffCode, displayName: res.staffName },
          profitCentre: { code: res.profitCentreKey, description: res.profitCentreDescription }
        });
        this.cdRef.markForCheck();
      }
    });
  }

  getDefaultprofitCentre(): void {
    if (!this.form.controls.staff.value) { return; }
    this.service.getStaffProfitCenter(this.form.controls.staff.value.key).subscribe(value => {
      if (value) {
        this.profitCentre.setValue({ code: value.code, description: value.description });
      }
    });
  }

  applyDefaultProfitCentre = (): void => {
    if (this.splitWipData.wipProfitCentreSource === 0) {
      this.getDefaultprofitCentre();
    } else {
      this.form.controls.profitCentre.setValue({ code: this.splitWipData.empProfitCentre, description: this.splitWipData.empProfitCentreDescription });
    }
    this.cdRef.markForCheck();
  };

  onCaseChange = (value: any): void => {
    if (value && value.key) {
      const caseKey = value.key;
      of(caseKey).pipe(distinctUntilChanged(),
        switchMap((newCaseKey) => {

          return this.warningChecker.performCaseWarningsCheck(newCaseKey, new Date());
        })
      ).subscribe((result: boolean) => this._handleCaseWarningsResult(result, caseKey));
    } else {
      this.clearCaseDefaultedFields();
    }
  };

  private readonly _handleCaseWarningsResult = (selected: boolean, caseKey: number): void => {
    if (selected) {
      this.caseHasMultiDebtors(caseKey);
    } else {
      this.case.setValue(null);
    }
  };

  private readonly _handleNameWarningResult = (selected: boolean): void => {
    if (!selected) {
      this.form.patchValue({ name: null });
      this.form.controls.name.markAsPristine();
    }
  };

  onNameChange = (value: any): void => {
    if (value && value.key) {
      this.caseNameMandatoryValidation();
      this.warningChecker.performNameWarningsCheck(value.key, value.value, new Date())
        .pipe(take(1))
        .subscribe((result: boolean) => this._handleNameWarningResult(result));
    }
  };

  onStaffChange = (value: any): void => {
    if (value && value.key) {
      this.applyDefaultProfitCentre();
    } else {
      this.validateStaff();
    }
  };

  onNarrativeChange = (value: any): void => {
    if (value && value.text) {
      this.form.controls.debitNoteText.setValue(value.text);
    } else {
      this.form.controls.debitNoteText.setValue(null);
    }
  };

  caseHasMultiDebtors(caseKey: number): void {
    if (!caseKey) { return; }
    this.service.hasMultipleDebtors$(caseKey).subscribe(res => {
      this.hasMultipleDebtors = res;
      if (res) {
        const message = this.translate.instant('field.errors.splitWipCaseHasMultipleDebtor');
        const title = 'modal.unableToComplete';
        this.notificationService.info({
          title,
          message
        }).then(() => {
          this.case.setValue(null);
        });
      } else {
        this.getDefaultWipFromCase(caseKey);
      }
    });
  }

  clearCaseDefaultedFields = (): void => {
    this.form.controls.name.setValue(null);
    this.form.controls.staff.setValue(null);
    this.form.controls.profitCentre.setValue(null);
  };

  getSplitWipDetails(): void {
    this.service.getItemForSplitWip$(this.entityKey, this.transKey, this.wipSeqKey).subscribe((res: any) => {
      this.splitWipData = res;
      this.cdRef.markForCheck();
      if (res.alerts && res.alerts.length > 0) {
        this.showRemovedWipDialog(res.alerts[0]);

        return;
      }
      this.isForeignCurrency = res.foreignCurrency ? true : false;
      this.originalAmount = this.isForeignCurrency ? res.foreignBalance : res.balance;
      this.decimalPlaces = this.isForeignCurrency ? res.foreignDecimalPlaces : res.localDeciamlPlaces;
      setTimeout(() => {
        this.grid.addRow();
        this.splitWipheader.unallocatedAmount.next(this.originalAmount);
      }, 200);
      this.splitWipHelper = new SplitWipHelper(this.splitWipData);
      this.gridOptions = this.buildGridOptions();
      this.cdRef.markForCheck();
    });
  }

  showRemovedWipDialog = (message): any => {
    const title = 'modal.unableToComplete';
    this.notificationService.info({ title, message, continue: 'Ok' }).then(() => {
      this.windowParentMessagingService.postLifeCycleMessage({
        action: 'onChange',
        target: 'splitWipHost',
        payload: {
          close: true
        }
      });
    });
  };

  changeSplitBy = (splitBy: SplitWipType) => {
    const rows: any = this.getValidRows();
    if (splitBy === SplitWipType.equally && rows.length > 0) {
      const message = this.translate.instant('wip.splitWip.confirmSplitEqually') + '<br/>' + this.translate.instant('wip.splitWip.proceedConfirmation');
      this.notificationService.confirm({
        title: this.translate.instant('wip.splitWip.pageHeader'),
        message,
        cancel: this.translate.instant('modal.warning.cancel'),
        continue: this.translate.instant('modal.warning.proceed')
      }).then(() => {
        this.processSplitBy(splitBy);
      }, () => {
        this.splitByType = this.oldSplitByType;
        this.cdRef.detectChanges();
      });
    } else {
      this.processSplitBy(splitBy);
    }
  };

  processSplitBy = (splitBy: SplitWipType) => {
    switch (splitBy) {
      case SplitWipType.amount:
        this.isPercentageDisabled = true;
        this.isAmountDisabled = false;
        this.form.controls.splitPercent.setErrors(null);
        this.isAmountDisabled = this.isTotalAmountAllocated();
        this.navigateFromEqually();
        break;
      case SplitWipType.percentage:
        this.isPercentageDisabled = this.isTotalAmountAllocated();
        this.isAmountDisabled = true;
        this.isPercentageDisabled = false;
        this.form.controls.amount.setErrors(null);
        this.form.controls.amount.clearValidators();
        this.form.controls.amount.updateValueAndValidity();
        this.navigateFromEqually();
        break;
      case SplitWipType.equally:
        this.isPercentageDisabled = true;
        this.isAmountDisabled = true;
        this.splitWipheader.unallocatedAmount.next(0);
        this.form.setErrors(null);
        this.form.controls.splitPercent.clearValidators();
        this.form.controls.splitPercent.updateValueAndValidity();
        this.form.controls.amount.clearValidators();
        this.form.controls.amount.updateValueAndValidity();
        this.form.controls.amount.setErrors(null);
        this.form.controls.amount.markAsPristine();

        this.form.controls.splitPercent.setErrors(null);
        this.form.controls.splitPercent.markAsPristine();
        this.splitItemsEqually();
        break;
      default:
        break;
    }
    this.oldSplitByType = splitBy;
    setTimeout(() => {
      if (this.caseEl) {
        this.caseEl.el.nativeElement.querySelector('input').focus();
      }
    }, 300);
  };

  splitItemsEqually = () => {
    if (this.form.dirty && this.isAdding) {
      this.setAmount(null);
      this.setPercent(null);
    }
    const rows: any = this.grid.wrapper.data;
    const items = rows.filter((x) => x && x !== undefined);
    if (items.length > 0) {
      this.splitWipHelper.splitItemsEqually(items);

      if (this.disableAll) {
        this.disableForm();
      }
    }
    this.cdRef.markForCheck();
  };

  navigateFromEqually = (): any => {
    this.checkErrorState();
    if (this.oldSplitByType === this.splitWipTypeEnum.equally) {
      this.removeAddedEmptyRow();
      this.reset();
    }
  };

  get applyDisabled(): boolean {
    if (this.splitByType === this.splitWipTypeEnum.equally) {
      this.form.controls.splitPercent.setErrors(null);
      this.form.controls.amount.setErrors(null);
      this.form.controls.splitPercent.markAsPristine();
      this.form.controls.amount.markAsPristine();
    }

    return this.form.status === 'INVALID' || !this.form.dirty || (this.isTotalAmountAllocated() && this.splitByType !== this.splitWipTypeEnum.equally);
  }

  reset(): void {
    this.clearForm();
    this.disableForm();
    this.cdRef.detectChanges();
  }

  disableForm = (): void => {
    if (this.isTotalAmountAllocated() && this.splitByType !== SplitWipType.equally) {
      this.form.reset();
      this.form.disable();
      this.isPercentageDisabled = true;
      this.isAmountDisabled = true;
      this.disableAll = true;
    } else {
      this.form.enable();
      this.grid.addRow();
      this.isPercentageDisabled = this.isAdding ? this.splitByType === SplitWipType.amount : false;
      this.isAmountDisabled = this.isAdding ? this.splitByType === SplitWipType.percentage : false;
      this.disableAll = false;
      if (this.splitByType === SplitWipType.equally) {
        this.isPercentageDisabled = true;
        this.isAmountDisabled = true;
      }
    }
  };

  clearForm = (): void => {
    this.form.reset();
    this.setAmount(null);
    this.setPercent(null);
    this.percentCtrl.clearValue();
    this.amountCtrl.clearValue();
    this.form.controls.amount.markAsPristine();
    this.form.controls.splitPercent.markAsPristine();
    this.createFormGroup();
    this.form.markAsPristine();
    this.checkErrorState();
    this.cdRef.markForCheck();

  };

  setAmount = (val?: number) => {
    if (val) {
      this.form.controls.amount.setErrors(null);
    }
    const value = val ? this.splitWipHelper.round(val, this.decimalPlaces) : null;

    if (this.amountCtrl) {
      this.amountCtrl.el.nativeElement.querySelector('input').value = value;
    }
    this.form.controls.amount.setValue(value);
  };

  setPercent = (val?: number) => {
    if (val) {
      this.form.controls.splitPercent.setErrors(null);
    }
    const value = val ? this.splitWipHelper.round(val, 2) : null;

    if (this.percentCtrl) {
      this.percentCtrl.el.nativeElement.querySelector('input').value = value;
    }
    this.form.controls.splitPercent.setValue(value);
  };

  setFormData(data): void {
    this.form.setValue({
      case: data.case,
      name: data.name,
      debitNoteText: data.debitNoteText,
      exchRate: data.exchRate,
      foreignValue: data.foreignValue,
      localValue: data.localValue,
      profitCentre: data.profitCentre,
      narrative: data.narrative,
      id: data.id,
      staff: data.staff,
      amount: data.amount,
      splitPercent: data.splitPercent
    });

    if (this.splitByType === this.splitWipTypeEnum.percentage) {
      this.isPercentageDisabled = false;
    } else if (this.splitByType === this.splitWipTypeEnum.amount) {
      this.isAmountDisabled = false;
    }

    this.cdRef.detectChanges();
  }

  submit = () => {
    if (this.splitWipheader.reasonForm.control.controls.reason && this.splitWipheader.reasonForm.control.controls.reason.errors) {
      this.splitWipheader.reasonForm.control.controls.reason.setValue(null);
      this.cdRef.markForCheck();

      return;
    }

    const transDate = this.datePipe.transform(this.splitWipData.transDate, 'yyyy-MM-dd');
    this.service.validateItemDate(transDate).subscribe((res: any) => {
      if (res && res.hasError) {
        const warning = _.first(_.filter(res.validationErrorList, (err: any) => {
          return err.warningCode !== '';
        }));
        if (warning) {
          const message = this.translate.instant('wip.splitWip.' + warning.warningCode) + '<br/>' + this.translate.instant('wip.splitWip.proceedConfirmation');
          this.notificationService.confirm({
            title: this.translate.instant('modal.warning.title'),
            message,
            cancel: this.translate.instant('modal.warning.cancel'),
            continue: this.translate.instant('modal.warning.proceed')
          }).then(() => {
            this.submitAfterValidate(true);
          });
        } else {
          this.notificationService.alert({
            title: this.translate.instant('wip.splitWip.error'),
            message: this.translate.instant('field.errors.' + res.validationErrorList[0].errorCode),
            continue: 'Ok'
          });
        }
      } else {
        this.submitAfterValidate();
      }
    });
  };

  getValidRows = (): any => {
    const rows: any = this.grid.wrapper.data;

    return rows.filter(x => x && x !== undefined && x.amount);
  };

  submitAfterValidate = (isWarningSuppressed = false) => {
    if (this.splitWipheader.unallocatedAmount.getValue() === 0 && this.splitWipheader.reason) {
      const data = new SplitWipArray();
      const validRows = this.getValidRows();
      data.getServerReady(validRows, this.splitWipData, this.splitWipheader.reason, isWarningSuppressed);
      this.service.submitSplitWip(data.entities).subscribe((res) => {
        const entityWithErrors = _.filter(res, (r: any) => {
          return r.validationErrors && r.validationErrors.length > 0;
        });
        if (entityWithErrors.length > 0) {
          const validationErrors = _.first(entityWithErrors).validationErrors;
          const message = validationErrors[0].message;
          const title = 'modal.unableToComplete';
          this.notificationService.alert({ title, message });
        } else {
          this.notificationService.info({
            title: 'wip.splitWip.info',
            message: 'wip.splitWip.success',
            continue: 'Ok'
          }).then(() => {
            this.closeModal(true);
          });
        }
      });
    }
  };

  isTotalAmountAllocated = () => {
    return this.appliedAmount === this.originalAmount;
  };

  isSaveDisabled = () => {
    return this.splitWipHelper.totalAllocatedAmount(this.validRows) !== this.originalAmount;
  };

  closeModal = (saved = false) => {
    if (saved || (!this.form.dirty && this.validRows.length === 0)) {
      this.windowParentMessagingService.postLifeCycleMessage({
        action: 'onChange',
        target: 'splitWipHost',
        payload: {
          close: true
        }
      });

      return;
    }
    this.discardAndClear();
  };

  discardAndClear = (): void => {
    if (this.form.dirty || this.validRows && this.validRows.length > 0 || this.splitWipheader.reason) {
      const modal = this.ipxNotificationService.openDiscardModal();
      modal.content.confirmed$.pipe(
        take(1))
        .subscribe(() => {
          this.windowParentMessagingService.postLifeCycleMessage({
            action: 'onChange',
            target: 'splitWipHost',
            payload: {
              close: true
            }
          });
        });
    } else {
      this.reset();
    }
  };

  removeAddedEmptyRow = (): any => {
    const rows: any = this.grid.wrapper.data;
    this.grid.wrapper.data = rows.filter(x => x);
  };

  onRowDeleted = () => {
    this.removeAddedEmptyRow();
    const rows: any = this.grid.wrapper.data;
    if (this.splitByType === SplitWipType.equally && rows.length > 0) {
      this.splitItemsEqually();
    }
    this.splitWipheader.unallocatedAmount.next(this.originalAmount - this.appliedAmount);
    this.form.markAsPristine();
    this.reset();
  };

  onRowAdded = (data: any) => {
    this.initializeDataItem(data);
    this.createFormGroup();
    this.splitWipheader.unallocatedAmount.next(this.originalAmount - this.appliedAmount);
    this.isAdding = true;
  };

  addNewRecord = () => {
    this.grid.addRow();
  };

  onRowEdited = (data: any) => {
    this.disableAll = false;
    this.activeDataItem = data.dataItem;
    this.removeAddedEmptyRow();
    this.initializeDataItem(data);
    this.clearForm();
    this.form.controls.amount.setValue('');
    this.setFormData(data.dataItem);
    this.isAdding = false;
    this.cdRef.markForCheck();
  };

  initializeDataItem = (data): void => {
    this.activeIndex = data.rowIndex;
    this.activeDataItem = data.dataItem;
    this.isAdding = data.dataItem.status === rowStatus.Adding;
  };

  disabledCaseNarrative = () => {
    return !this.case || !this.case.value;
  };

  openCaseNarrative = () => {
    if (this.disabledCaseNarrative()) { return; }
    const initialState = {
      caseKey: this.case.value.key
    };
    this.modalService.openModal(CaseBillNarrativeComponent, {
      focus: true,
      animated: false,
      backdrop: 'static',
      class: 'modal-lg',
      initialState
    });
  };

  buildGridOptions(): IpxGridOptions {
    return {
      autobind: true,
      pageable: false,
      sortable: false,
      reorderable: false,
      addRowToTheBottom: true,
      read$: () => {
        return of(this.splitWipNewData);
      },
      columns: this.splitWipHelper.getColumns(),
      enableGridAdd: false,
      canAdd: false,
      rowMaintenance: {
        canEdit: true,
        canDelete: true,
        rowEditKeyField: 'id',
        width: '75px'
      },
      maintainFormGroup$: this.maintainFormGroup$
    };
  }
}