import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, Renderer2, ViewChild } from '@angular/core';
import { AbstractControl, FormBuilder, FormControl, FormGroup, Validators } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { criteriaPurposeCode, SearchService } from 'configuration/rules/screen-designer/case/search/search.service';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { CaseValidCombinationService } from 'portfolio/case/case-valid-combination.service';
import { Subject, Subscription } from 'rxjs';
import { debounceTime, distinctUntilChanged, take, takeUntil } from 'rxjs/operators';
import { dataTypeEnum } from 'shared/component/forms/ipx-data-type/datatype-enum';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { ExchangeRateVariationModel, ExchangeRateVariationRequest } from '../exchange-rate-variations.model';
import { ExchangeRateVariationService } from '../exchange-rate-variations.service';

@Component({
  selector: 'ipx-maintain-exchangerate-var',
  templateUrl: './maintain-exchangerate-var.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [IpxDestroy]
})
export class MaintainExchangerateVarComponent implements OnInit, AfterViewInit {
  @Input() id: any;
  @Input() isAdding: boolean;
  @Input() currencyCodeValue: any;
  @Input() exchangeRateScheduleCodeValue: any;

  @ViewChild('effectiveDate', { static: false }) dateChangedView: any;
  form: any;
  canNavigate: boolean;
  onClose$ = new Subject();
  subscription: Subscription;
  modalRef: BsModalRef;
  addedRecordId$ = new Subject();
  currentKey: number;
  dataType: any = dataTypeEnum;
  validCombinationDescriptionsMap: any;
  extendValidCombinationPickList: any;
  isSubmitted = false;
  disableCategory = true;
  formDataForVC = { caseType: {}, jurisdiction: {}, propertyType: {}, caseCategory: {} };
  @ViewChild('currencyEl', { static: false }) currencyEl: any;
  @ViewChild('exchangeRateVarEl', { static: false }) exchangeRateVarEl: any;

  constructor(readonly service: ExchangeRateVariationService,
    private readonly cdRef: ChangeDetectorRef,
    readonly sbsModalRef: BsModalRef,
    readonly formBuilder: FormBuilder,
    private readonly destroy$: IpxDestroy,
    private readonly shortcutsService: IpxShortcutsService,
    private readonly renderer: Renderer2,
    private readonly vcService: CaseValidCombinationService,
    private readonly notificationService: NotificationService,
    private readonly ipxNotificationService: IpxNotificationService,
    private readonly translate: TranslateService,
    public searchService: SearchService) {
  }

  ngOnInit(): void {
    this.createFormGroup();
    if (!this.isAdding) {
      this.getExchangeRateDetails(this.id);
    }

    this.initializeValidCombinationForm();
    this.handleShortcuts();
    this.cdRef.markForCheck();
  }

  ngAfterViewInit(): void {
    this.currency.valueChanges.pipe(distinctUntilChanged(), debounceTime(200)).subscribe(value => {
      if (value && this.isSubmitted) {
        this.currencyAndRateValidationPassed();
      }
    });

    this.exchRateSch.valueChanges.pipe(distinctUntilChanged(), debounceTime(200)).subscribe(value => {
      if (value && this.isSubmitted) {
        this.currencyAndRateValidationPassed();
      }
    });

    this.form.controls.buyFactor.valueChanges.pipe(distinctUntilChanged(), debounceTime(200)).subscribe(value => {
      if (value && this.isSubmitted) {
        this.rateFactorValidationPassed();
        this.disableRate();
      }
    });

    this.form.controls.buyRate.valueChanges.pipe(distinctUntilChanged(), debounceTime(300)).subscribe(value => {
      if (value && this.isSubmitted) {
        this.rateFactorValidationPassed();
        this.disableFactor();
      }
    });

    this.caseType.valueChanges.pipe(distinctUntilChanged()).subscribe(value => {
      if (value) {
        this.disableCategory = false;
      } else {
        this.disableCategory = true;
        this.caseCategory.setValue(null);
        this.caseCategory.markAsPristine();
      }
    });

    this.form.controls.sellRate.valueChanges.pipe(distinctUntilChanged(), debounceTime(200)).subscribe(value => {
      if (value && this.isSubmitted) {
        this.rateFactorValidationPassed();
        this.disableFactor();
      }
    });

    this.form.controls.sellFactor.valueChanges.pipe(distinctUntilChanged(), debounceTime(200)).subscribe(value => {
      if (value && this.isSubmitted) {
        this.rateFactorValidationPassed();
        this.disableRate();
      }
    });

    this.form.controls.effectiveDate.valueChanges.pipe(distinctUntilChanged(), debounceTime(200)).subscribe(() => {
      this.onDateChanged();
    });

    this.setFormStatus();
  }

  onCaseTypeChange(value): void {
    if (value) {
      this.onCriteriaChange(true);
      this.disableCategory = false;
    } else {
      this.disableCategory = true;
      this.onCriteriaChange(false);
      this.caseCategory.setValue(null);
      this.caseCategory.markAsPristine();
    }
  }

  onPropertyTypeChange(value): void {
    this.onCriteriaChange(value ? true : false);
  }

  onJurisdictionChange(value): void {
    this.onCriteriaChange(value ? true : false);
  }

  onCaseCategoryChange(value): void {
    this.onCriteriaChange(value ? true : false);
  }

  updateVCFormData(): void {
    this.formDataForVC.caseType = this.caseType.value;
    this.formDataForVC.jurisdiction = this.jurisdiction.value;
    this.formDataForVC.propertyType = this.propertyType.value;
    this.formDataForVC.caseCategory = this.caseCategory.value;
    this.form.markAsDirty();
    this.cdRef.markForCheck();
  }

  onCriteriaChange = _.debounce((dirty) => {
    this.searchService.validateCaseCharacteristics$(this.form, criteriaPurposeCode.ScreenDesignerCases, dirty).then(() => {
      this.updateVCFormData();
    });
  }, 100);

  onDateChanged(): any {
    if (this.form.controls && !this.form.controls.effectiveDate.value) {
      this.form.controls.effectiveDate.setErrors({ effectiveDateRequired: 'required' });
      this.cdRef.markForCheck();
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

  getExchangeRateDetails(id: number): any {
    if (id) {
      this.service.getExchangeRateDetails(id).subscribe((res: ExchangeRateVariationModel) => {
        if (res) {
          this.setFormData(res);
          this.updateVCFormData();
          this.initializeValidCombinationForm();
        }
      });
    }
  }

  private initializeValidCombinationForm(): void {
    this.intializeControlsState();
    this.vcService.initFormData(this.formDataForVC);
    this.validCombinationDescriptionsMap = this.vcService.validCombinationDescriptionsMap;
    this.extendValidCombinationPickList = this.vcService.extendValidCombinationPickList;
  }

  intializeControlsState = (): void => {
    setTimeout(() => {
      this.form.markAsPristine();
      this.form.controls.propertyType.markAsPristine();
      this.form.controls.subType.markAsPristine();
      this.form.controls.caseCategory.markAsPristine();
    }, 100);
  };

  createFormGroup = (): FormGroup => {
    this.form = this.formBuilder.group({
      id: this.id,
      currency: [this.currencyCodeValue, Validators.compose([Validators.maxLength(3)])],
      exchRateSch: [this.exchangeRateScheduleCodeValue, Validators.compose([Validators.maxLength(20)])],
      caseCategory: new FormControl(),
      caseType: new FormControl(),
      subType: new FormControl(),
      jurisdiction: new FormControl(),
      propertyType: new FormControl(),
      buyRate: new FormControl({ value: null, disabled: this.disableFactor() }, Validators.compose([Validators.max(1000000)])),
      buyFactor: new FormControl({ value: null, disabled: this.disableRate() }, Validators.compose([Validators.max(1000000)])),
      sellRate: new FormControl({ value: null, disabled: this.disableFactor() }, Validators.compose([Validators.max(1000000)])),
      sellFactor: new FormControl({ value: null, disabled: this.disableRate() }, Validators.compose([Validators.max(1000000)])),
      effectiveDate: [new Date(), Validators.required],
      notes: []
    });

    return this.form;
  };

  rateFactorValidationPassed(): boolean {
    if (this.form && this.form.controls) {
      if ((!this.form.controls.buyRate.value && !this.form.controls.sellRate.value)
        && (!this.form.controls.buyFactor.value && !this.form.controls.sellFactor.value)) {
        this.form.controls.buyRate.markAsTouched();
        this.form.controls.buyRate.markAsDirty();
        this.form.controls.buyRate.setErrors({ sellORFactorRequired: true });
        this.form.controls.sellRate.markAsTouched();
        this.form.controls.sellRate.markAsDirty();
        this.form.controls.sellRate.setErrors({ sellORFactorRequired: true });
        this.form.controls.buyFactor.markAsTouched();
        this.form.controls.buyFactor.markAsDirty();
        this.form.controls.buyFactor.setErrors({ sellORFactorRequired: true });
        this.form.controls.sellFactor.markAsTouched();
        this.form.controls.sellFactor.markAsDirty();
        this.form.controls.sellFactor.setErrors({ sellORFactorRequired: true });
        this.cdRef.markForCheck();

        return false;
      }

      this.form.controls.buyRate.setErrors(null);
      this.form.controls.sellRate.setErrors(null);
      this.form.controls.buyFactor.setErrors(null);
      this.form.controls.sellFactor.setErrors(null);
      this.cdRef.markForCheck();

      return true;
    }

    return false;
  }

  currencyAndRateValidationPassed(): boolean {
    if (this.form && this.form.controls) {
      if (!this.form.controls.currency.value && !this.form.controls.exchRateSch.value) {
        this.form.controls.currency.setErrors({ currencyORExchRateRequired: true });
        this.form.controls.currency.markAsTouched();
        this.form.controls.currency.markAsDirty();
        this.form.controls.exchRateSch.setErrors({ currencyORExchRateRequired: true });
        this.form.controls.exchRateSch.markAsTouched();
        this.form.controls.exchRateSch.markAsDirty();
        this.clickEvents();

        return false;
      }

      this.form.controls.currency.markAsPristine();
      this.form.controls.currency.setErrors(null);
      this.form.controls.exchRateSch.markAsPristine();
      this.form.controls.exchRateSch.setErrors(null);
      this.clickEvents();

      return true;
    }

    return false;
  }

  clickEvents(): void {
    this.exchangeRateVarEl.el.nativeElement.querySelector('input').click();
    this.currencyEl.el.nativeElement.querySelector('input').click();
  }

  disableRate = (): boolean => {
    if (this.form && this.form.controls) {
      if (this.form.controls.buyFactor.value || this.form.controls.sellFactor.value) {
        this.form.controls.buyRate.markAsPristine();
        this.form.controls.sellRate.markAsPristine();

        return true;
      }
    }

    return false;
  };

  disableFactor = (): boolean => {
    if (this.form && this.form.controls) {
      if (this.form.controls.buyRate.value || this.form.controls.sellRate.value) {
        this.form.controls.buyFactor.markAsPristine();
        this.form.controls.sellFactor.markAsPristine();

        return true;
      }
    }

    return false;
  };

  setFormStatus = (): void => {
    setTimeout(() => {
      this.form.controls.effectiveDate.markAsUntouched();
      this.form.markAsPristine();
      this.cdRef.markForCheck();
      if (this.dateChangedView && !this.form.controls.effectiveDate.dirty) {
        const input = this.dateChangedView.el.nativeElement.querySelector('.datepicker-input');
        this.renderer.removeClass(input, 'edited');
        this.cdRef.detectChanges();
      }
    }, 200);
  };

  get currency(): any {
    return this.form.get('currency');
  }

  get exchRateSch(): any {
    return this.form.get('exchRateSch');
  }

  get jurisdiction(): AbstractControl {
    return this.form.get('jurisdiction');
  }

  get caseCategory(): AbstractControl {
    return this.form.get('caseCategory');
  }

  get propertyType(): AbstractControl {
    return this.form.get('propertyType');
  }

  get caseType(): AbstractControl {
    return this.form.get('caseType');
  }

  get subType(): AbstractControl {
    return this.form.get('subType');
  }

  get buyRate(): FormControl {
    return this.form.get('buyRate') as FormControl;
  }

  get buyFactor(): FormControl {
    return this.form.get('buyFactor') as FormControl;
  }

  get sellRate(): FormControl {
    return this.form.get('sellRate') as FormControl;
  }

  get sellFactor(): FormControl {
    return this.form.get('sellFactor') as FormControl;
  }

  setFormData(data: ExchangeRateVariationModel): any {
    this.form.setValue({
      id: data.id,
      currency: data.currency ? { code: data.currency.code, description: data.currency.value } : null,
      exchRateSch: data.exchRateSch ? { id: data.exchRateSch.id, description: data.exchRateSch.value } : null,
      buyRate: data.buyRate,
      buyFactor: data.buyFactor,
      sellRate: data.sellRate,
      sellFactor: data.sellFactor,
      caseCategory: data.caseCategory ? { key: data.caseCategory.key, code: data.caseCategory.code, value: data.caseCategory.value } : null,
      caseType: data.caseType ? { key: data.caseType.key, code: data.caseType.code, value: data.caseType.value } : null,
      subType: data.subType ? { key: data.subType.key, code: data.subType.key, value: data.subType.value } : null,
      jurisdiction: data.country ? { key: data.country.code, code: data.country.code, value: data.country.value } : null,
      propertyType: data.propertyType ? { code: data.propertyType.code, value: data.propertyType.value } : null,
      effectiveDate: data.effectiveDate ? new Date(data.effectiveDate) : new Date(),
      notes: data.notes
    });
    this.setFormStatus();

    this.cdRef.markForCheck();
  }

  submit(): any {
    this.isSubmitted = true;
    if (this.form.valid && this.form.value && this.form.dirty) {
      const validCurrecnyForm = this.currencyAndRateValidationPassed();
      const validFactors = this.rateFactorValidationPassed();
      if (!validCurrecnyForm || !validFactors) {
        return;
      }

      const request = this.prepareRequest(this.form.value);
      this.service.validateExchangeRateVariations(request).subscribe((res) => {
        if (!res) {
          this.saveExchangeRateVariation(request);
        } else {
          this.showDuplicateError(res);

          return;
        }
      });
    }
  }

  showDuplicateError = (res): void => {
    if (res && res.displayMessage) {
      const message = this.translate.instant('field.errors.duplicateExchangeRateVariation');
      const title = 'modal.unableToComplete';
      this.notificationService.alert({ title, message });
    }
  };

  prepareRequest(form: any): ExchangeRateVariationRequest {
    let request = new ExchangeRateVariationRequest();
    request = { ...form };
    request.id = this.isAdding ? null : form.id;
    request.currencyCode = form.currency ? form.currency.code : null;
    request.caseCategoryCode = (this.caseCategory && this.caseCategory.value) ? this.caseCategory.value.code : null;
    request.caseTypeCode = (this.caseType && this.caseType.value) ? this.caseType.value.code : null;
    request.exchScheduleId = form.exchRateSch ? form.exchRateSch.id : null;
    request.propertyTypeCode = form.propertyType ? form.propertyType.code : null;
    request.subTypeCode = form.subType ? form.subType.code : null;
    request.countryCode = form.jurisdiction ? form.jurisdiction.code : null;

    return request;
  }

  saveExchangeRateVariation(request: ExchangeRateVariationRequest): any {
    this.service.submitExchangeRateVariations(request).subscribe((res) => {
      if (res && res.displayMessage) {
        this.showDuplicateError(res);

        return;
      }
      this.isSubmitted = false;
      this.addedRecordId$.next(res);
      this.onClose$.next({ success: true });
      this.form.setErrors(null);
      this.sbsModalRef.hide();

      this.cdRef.markForCheck();
    });
  }

  cancel(): void {
    if (this.form.dirty) {
      const modal = this.ipxNotificationService.openDiscardModal();
      modal.content.confirmed$.pipe(
        take(1))
        .subscribe(() => {
          this.resetForm();
        });
    } else {
      this.resetForm();
    }
  }

  resetForm = (): void => {
    this.form.reset();
    this.vcService.initFormData(this.formDataForVC);
    this.onClose$.next(false);
    this.sbsModalRef.hide();
  };
}
