import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { AbstractControl, FormBuilder, FormControl, FormGroup, ValidationErrors } from '@angular/forms';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged, take, takeUntil, takeWhile } from 'rxjs/operators';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { CaseRequest } from '../../case-debtor.model';
import { CaseDebtorService } from '../case-debtor.service';
import { CaseStatusRestrictionComponent } from './case-status-restriction.component';

@Component({
  selector: 'ipx-maintain-case-debtor',
  templateUrl: './maintain-case-debtor.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [IpxDestroy]
})
export class MaintainCaseDebtorComponent implements OnInit, AfterViewInit, OnDestroy {

  @Input() grid: any;
  @Input() dataItem: any;
  @Input() rowIndex: any;
  @Input() entityNo: number;
  @Input() raisedByStaffId: number;
  @Input() draftBillSiteControl: boolean;
  onClose$ = new Subject();
  form: any;
  disableCase = false;
  hasMainCase = false;
  mainCaseId: number;
  newCaseId: number;
  newCases: Array<number>;
  disableCaseList = false;
  isSingleCase = true;
  draftBills: any = [];
  isFirstCaseAdding = false;
  intialCasesCount = 0;

  constructor(
    private readonly service: CaseDebtorService,
    private readonly ipxNotificationService: IpxNotificationService,
    private readonly sbsModalRef: BsModalRef,
    private readonly formBuilder: FormBuilder,
    readonly cdRef: ChangeDetectorRef,
    private readonly destroy$: IpxDestroy,
    private readonly shortcutsService: IpxShortcutsService,
    private readonly modalService: IpxModalService) { }

  ngOnInit(): void {
    this.handleShortcuts();
    this.createFormGroup(this.dataItem);
  }

  createFormGroup = (dataItem: any): FormGroup => {
    if (dataItem) {
      this.form = this.formBuilder.group({
        case: new FormControl(dataItem.case),
        caseList: new FormControl(dataItem.caseList)
      });

      return this.form;
    }
  };

  get caseList(): AbstractControl {
    return this.form.get('caseList');
  }
  get case(): AbstractControl {
    return this.form.get('case');
  }

  handleShortcuts(): void {
    const shortcutCallbacksMap = new Map(
      [[RegisterableShortcuts.SAVE, (): void => { this.apply(); }],
      [RegisterableShortcuts.REVERT, (): void => { this.cancel(); }]]);
    this.shortcutsService.observeMultiple$([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT])
      .pipe(takeUntil(this.destroy$))
      .subscribe((key: RegisterableShortcuts) => {
        if (!!key && shortcutCallbacksMap.has(key)) {
          shortcutCallbacksMap.get(key)();
        }
      });
  }

  ngAfterViewInit(): void {
    if (this.grid && this.grid.wrapper.data && this.grid.wrapper.data.filter(x => x).length > 0) {
      this.hasMainCase = this.grid.wrapper.data.some(x => x && x.IsMainCase);
      this.mainCaseId = this.hasMainCase ? this.grid.wrapper.data.filter(x => x && x.IsMainCase)[0].CaseId : null;
      this.isFirstCaseAdding = this.grid.wrapper.data.length === 0;
      this.intialCasesCount = this.grid.wrapper.data.filter(x => x).length;
    } else {
      this.isFirstCaseAdding = true;
    }
    this.form.controls.case.valueChanges
      .pipe(debounceTime(200), distinctUntilChanged())
      .subscribe((value) => {
        this.disableCaseList = value && value.length > 0 ? true : false;
        this.form.setErrors(value && value.length > 0 ? null : { errors: 'invalid' });
        this.cdRef.markForCheck();
      });

    this.form.controls.caseList.valueChanges
      .pipe(debounceTime(200), distinctUntilChanged())
      .subscribe((value) => {
        this.disableCase = value ? true : false;
        this.form.setErrors(value ? null : { errors: 'invalid' });
        this.cdRef.markForCheck();
      });
  }

  apply(): any {
    if (this.form.valid) {
      const rowObject = { rowIndex: this.rowIndex, dataItem: this.dataItem, formGroup: this.form } as any;
      this.newCaseId = (this.form.value.case && this.form.value.case.length > 0) ? this.form.value.case[0].key : this.form.value.caseList.key;
      this.newCases = this.form.value.caseList ? this.form.value.caseList.caseKeys : [];
      this.getAssociatedCases(rowObject);
    }
  }

  getUniqueCases = (): any => {
    this.grid.wrapper.data = this.grid.wrapper.data.reduce((a, b) => {
      if (!a.find(data => data.CaseId === b.CaseId)) {
        a.push(b);
      }

      return a;
    }, []);
  };

  getAssociatedCases = (row: any): any => {
    const form = row.formGroup.value;
    this.isSingleCase = (!form.caseList && form.case && form.case.length === 1) ? true : false;
    const request: CaseRequest = {
      caseListId: form.caseList ? form.caseList.key : null,
      caseIds: this.getCaseIds(form),
      entityId: this.entityNo,
      raisedByStaffId: this.raisedByStaffId
    };
    this.service.getCases(request).subscribe(res => {
      this.validateCaseStatusRestriction(res.CaseList, row);
    });
  };

  private readonly getCaseIds = (form: any): any => {
    if (form.caseList && form.caseList.caseKeys) {

      return form.caseList.caseKeys.join(', ');
    }

    return form.case.map((val: { key: any; }) => val.key) ? form.case.map((val: { key: any; }) => val.key).join(', ') : '';
  };

  validateCaseStatusRestriction = (cases: any, row: any) => {
    const restrictedCases = _.filter(cases, (c: any) => {
      return c.HasRestrictedStatusForBilling;
    });

    if (this.isSingleCase && restrictedCases.length === 1) {
      const caseCode = restrictedCases[0].CaseReference;
      this.ipxNotificationService.openAlertModal('accounting.billing.step1.caseRestriction', 'field.errors.billing.validations.caseStatusRestriction', null, null, caseCode);
      this.case.setValue(null);

      return false;
    }

    const allcasesRestricted = restrictedCases.length === cases.length;

    if (restrictedCases.length > 0) {
      const modal = this.modalService.openModal(CaseStatusRestrictionComponent, {
        animated: false,
        backdrop: 'static',
        class: 'modal-lg',
        initialState: {
          caseList: restrictedCases,
          allcasesRestricted
        }
      });
      modal.content.onClose$.subscribe(
        (canProceed: any) => {
          if (!canProceed) {

            return false;
          }
          if (allcasesRestricted) {
            this.caseList.setValue(null);

            return false;
          }
          const casesToProceed: any = _.filter(cases, (c: any) => {
            return !c.HasRestrictedStatusForBilling;
          });
          this.proceedAfterStatusValidation(casesToProceed, row);
        }
      );
    } else {
      this.proceedAfterStatusValidation(cases, row);
    }
  };

  proceedAfterStatusValidation = (casesToProceed: any, row: any) => {
    let draftedBills = casesToProceed.map(x => x.DraftBills).reduce((a, y) => a.concat(y));
    draftedBills = _.filter(draftedBills, (data, index) => {
      return (draftedBills.indexOf(data) === index) && data[0];
    });
    this.draftBills = draftedBills;

    if (!this.hasMainCase) {
      if (this.isSingleCase) {
        this.hasMainCase = true;
        this.mainCaseId = casesToProceed[0].CaseId;
      } else {
        const data = _.find(casesToProceed, (item: any) => {
          return item.IsMainCase === true;
        });
        if (data) {
          this.mainCaseId = data.CaseId;
        } else {
          this.mainCaseId = casesToProceed[0].CaseId;
          casesToProceed[0].IsMainCase = true;
        }
      }
    }
    this.validateCases(this.mainCaseId, row, casesToProceed);
    this.cdRef.detectChanges();
  };

  validateCases = (caseId: number, row: any, caseResponse: Array<any>): boolean => {
    if (this.grid && this.grid.wrapper.data.length - 1 <= 0) {
      this.service.getCaseDebtors(caseId).pipe(takeUntil(this.destroy$)).subscribe(res => {
        if (res.length <= 0) {
          this.ipxNotificationService.openAlertModal(null, 'accounting.billing.step1.errorMessage');

          return false;
        }
        this.validationOperations(row, caseResponse);
      });
    } else {
      this.validationOperations(row, caseResponse);
    }

    return true;
  };

  validationOperations = (row: any, caseResponse: Array<any>): any => {
    const firstRow = caseResponse.shift();
    firstRow.IsMainCase = this.hasMainCase ? false : firstRow.IsMainCase;
    this.grid.wrapper.data[row.rowIndex] = { ...firstRow };
    if (this.isSingleCase && row.rowIndex === 0) {
      this.hasMainCase = true;
      this.grid.wrapper.data[row.rowIndex].IsMainCase = true;
    } else {
      this.hasMainCase = this.grid.wrapper.data.some(x => x.IsMainCase);
      if (this.hasMainCase) {
        caseResponse.forEach(e => { e.IsMainCase = false; });
      }
      this.grid.wrapper.data = this.grid.wrapper.data.concat(caseResponse);
    }

    this.getUniqueCases();
    if (this.intialCasesCount === this.grid.wrapper.data.length) {
      this.resetForm(false);
      this.closeModal(false);
    } else {
      this.closeModal();
    }
  };

  closeModal = (status = true): void => {
    this.onClose$.next({
      success: status,
      formGroup: this.form,
      rows: this.grid.wrapper.data,
      warnings: { draftBills: this.draftBills },
      mainCaseId: this.mainCaseId,
      newCaseId: this.newCaseId ? this.newCaseId : this.mainCaseId,
      caseListId: this.form && this.form.value.caseList ? this.form.value.caseList.key : null,
      newCases: this.newCases ? this.newCases.join(', ') : null,
      isFirstCaseAdded: this.isFirstCaseAdding
    });
    this.sbsModalRef.hide();
  };

  cancel = (): void => {
    if (this.form.dirty) {
      const modal = this.ipxNotificationService.openDiscardModal();
      modal.content.confirmed$.pipe(
        take(1))
        .subscribe(() => {
          this.resetForm(true);
        });
    } else {
      this.resetForm(false);
    }
  };

  resetForm = (isDirty: boolean): void => {
    if (this.dataItem.status === rowStatus.Adding) {
      this.grid.rowCancelHandler(this, this.rowIndex, this.dataItem);
    }
    this.form.reset();
    this.onClose$.next(isDirty);
    this.sbsModalRef.hide();
  };

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
