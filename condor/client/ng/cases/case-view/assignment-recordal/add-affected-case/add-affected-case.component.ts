import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { AbstractControl, FormArray, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject, Subscription } from 'rxjs';
import { debounceTime, distinctUntilChanged, take, takeUntil, takeWhile } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { AffectedCasesService } from '../affected-cases.service';
import { AddAffetcedRequestModel } from '../model/affected-case.model';

@Component({
  selector: 'ipx-add-affected-case',
  templateUrl: './add-affected-case.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [IpxDestroy]
})
export class AddAffectedCaseComponent implements OnInit, AfterViewInit, OnDestroy {
  @Input() caseKey: number;
  formGroup: any;
  onClose$ = new Subject();
  subscription: Subscription;
  officialNoSubscription: Subscription;
  modalRef: BsModalRef;
  isExternalCaseDisabled = false;
  isCaseReferenceDisabled = false;
  steps = [];
  isSaveDisabled = true;

  constructor(readonly service: AffectedCasesService,
    private readonly cdRef: ChangeDetectorRef,
    private readonly notificationService: IpxNotificationService,
    private readonly notification: NotificationService,
    private readonly sbsModalRef: BsModalRef,
    readonly translate: TranslateService,
    private readonly formBuilder: FormBuilder,
    private readonly destroy$: IpxDestroy,
    private readonly shortcutsService: IpxShortcutsService) {
  }

  ngOnInit(): void {
    this.subscription = this.service.getRecordalSteps(this.caseKey).subscribe((res: any) => {
      this.steps = res;
      this.formGroup = this.createFormGroup();
      this.officialNoSubscription = this.officialNo.valueChanges
        .pipe(debounceTime(500), distinctUntilChanged())
        .subscribe((value: string) => {
          this.checkChanges();
        });
      this.cdRef.detectChanges();
    });
    this.handleShortcuts();
  }

  ngAfterViewInit(): void {
    if (this.formGroup) {
      this.formGroup.statusChanges
        .pipe(distinctUntilChanged())
        .subscribe(() => {
          this.validateFormState();
        });
    }
  }

  handleShortcuts(): void {
    const shortcutCallbacksMap = new Map(
      [[RegisterableShortcuts.SAVE, (): void => { this.submit(); }],
      [RegisterableShortcuts.REVERT, (): void => { this.cancel(); }]]);
    this.shortcutsService.observeMultiple$([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT])
      .pipe(takeUntil(this.destroy$))
      .subscribe((key: RegisterableShortcuts) => {
        if (!!key && shortcutCallbacksMap.has(key)) {
          shortcutCallbacksMap.get(key)();
        }
      });
  }

  createFormGroup = (): FormGroup => {
    const steps = this.formBuilder.array(
      _.map(_.sortBy(this.steps, 'stepId'), (d) => { return [d]; }), { validators: Validators.required });

    this.formGroup = this.formBuilder.group({
      cases: [{ value: null, disabled: this.isCaseReferenceDisabled }],
      jurisdiction: [{ value: null, disabled: this.isExternalCaseDisabled }],
      officialNo: [{ value: null, disabled: this.isExternalCaseDisabled }],
      recordalSteps: steps
    });

    return this.formGroup;
  };

  get recordalSteps(): FormArray {
    return this.formGroup.get('recordalSteps') as FormArray;
  }
  get cases(): AbstractControl {
    return this.formGroup.get('cases');
  }
  get jurisdiction(): AbstractControl {
    return this.formGroup.get('jurisdiction');
  }

  get officialNo(): AbstractControl {
    return this.formGroup.get('officialNo');
  }

  onCaseChange(): any {
    if (!this.cases.value || (this.cases.value && this.cases.value.length === 0)) {
      this.isExternalCaseDisabled = false;
      this.formGroup.markAsPristine();
      this.formGroup.setErrors({ invalid: true });
    } else {
      this.isExternalCaseDisabled = true;
    }
    this.validateFormState();
  }

  checkChanges(): void {
    this.isCaseReferenceDisabled = true;
    const jurisdiction = this.formGroup.value.jurisdiction;
    const officialNo = this.formGroup.value.officialNo;
    if (!jurisdiction && !officialNo) {
      this.isCaseReferenceDisabled = false;
      this.jurisdiction.markAsPristine();
      this.formGroup.controls.officialNo.markAsPristine();
    }
    if (jurisdiction && officialNo) {
      this.service.validateAddAffectedCase(jurisdiction.code, officialNo).subscribe((res: any) => {
        if (res && res.length > 0) {
          this.confirmCases(res);
        }
      });
    }
    this.validateFormState();
  }

  confirmCases(cases: any): any {
    const info = this.translate.instant('caseview.affectedCases.confirmAddAffectedCase');
    const notificationRef = this.notificationService.openConfirmationModal('caseview.affectedCases.confirmAddAffectedCaseTitle', info, 'Proceed', 'Cancel');
    notificationRef.content.confirmed$.subscribe(() => {
      this.formGroup.markAsPristine();
      this.formGroup.setErrors(null);
      this.formGroup.patchValue({ cases });
      this.formGroup.patchValue({ jurisdiction: null, officialNo: null });
      this.isExternalCaseDisabled = true;
      this.isCaseReferenceDisabled = false;
      this.cdRef.detectChanges();
    });
  }

  submit(): any {
    const isValid = this.validateFormState();
    if (isValid) {
      const relatedCases = (this.formGroup.value.cases && this.formGroup.value.cases.length) > 0 ? this.formGroup.value.cases.map(x => x.key) : null;
      const request: AddAffetcedRequestModel = {
        caseId: this.caseKey,
        relatedCases,
        jurisdiction: this.formGroup.value.jurisdiction ? this.formGroup.value.jurisdiction.code : null,
        officialNo: this.formGroup.value.officialNo,
        recordalSteps: this.formGroup.value.recordalSteps.filter(x => x.isSelected).map(x => ({ recordalStepSequence: x.id, recordalTypeNo: x.recordalType.key }))
      };

      this.service.submitAffectedCase(request).subscribe(res => {
        this.notification.success();
        this.onClose$.next(true);
        this.sbsModalRef.hide();
      });
    }
  }

  validateFormState(): boolean {
    let isValid = false;
    const jurisdiction = this.formGroup.value.jurisdiction;
    const officialNo = this.formGroup.value.officialNo;
    this.isCaseReferenceDisabled = (jurisdiction || officialNo) ? true : false;
    const isCaseValid = (this.formGroup.value.cases && this.formGroup.value.cases.length > 0) ? true : false;
    const isExternalsValid = (jurisdiction && officialNo) ? true : false;
    const isCheckBoxValid = this.formGroup.value.recordalSteps.some(x => x.isSelected);
    isValid = ((isCaseValid || isExternalsValid) && isCheckBoxValid) ? true : false;
    if (!isValid) {
      this.formGroup.setErrors({ required: true });
      this.isSaveDisabled = true;
    } else {
      this.formGroup.markAsDirty();
      this.formGroup.setErrors(null);
      this.isSaveDisabled = false;
    }

    return isValid;
  }

  onCheckboxChange(): any {
    this.formGroup.markAsDirty();
    if (this.formGroup.value) {
      this.validateFormState();
    }
  }

  ngOnDestroy(): void {
    if (!!this.subscription) {
      this.subscription.unsubscribe();
      this.officialNoSubscription.unsubscribe();
    }
  }

  cancel(): void {
    if (this.formGroup.dirty) {
      const modal = this.notificationService.openDiscardModal();
      modal.content.confirmed$.pipe(
        take(1))
        .subscribe(() => {
          this.sbsModalRef.hide();
        });
    } else {
      this.sbsModalRef.hide();
    }
  }

  trackByFn = (index): any => {
    return index;
  };

}
