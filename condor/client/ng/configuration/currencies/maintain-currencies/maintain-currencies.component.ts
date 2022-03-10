import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, Renderer2, ViewChild } from '@angular/core';
import { FormBuilder, FormControl, FormGroup, Validators } from '@angular/forms';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject, Subscription } from 'rxjs';
import { debounceTime, distinctUntilChanged, take, takeUntil } from 'rxjs/operators';
import { dataTypeEnum } from 'shared/component/forms/ipx-data-type/datatype-enum';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import { CurrencyItems, CurrencyRequest } from '../currencies.model';
import { CurrenciesService } from '../currencies.service';

@Component({
  selector: 'ipx-maintain-currencies',
  templateUrl: './maintain-currencies.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [IpxDestroy]
})
export class MaintainCurrenciesComponent implements OnInit, AfterViewInit {
  @Input() id: any;
  @Input() isAdding: boolean;
  @ViewChild('dateChanged', { static: false }) dateChangedView: any;
  form: any;
  canNavigate: boolean;
  entry: CurrencyItems;
  navData: {
    keys: Array<any>,
    totalRows: number,
    pageSize: number,
    fetchCallback(currentIndex: number): any
  };
  onClose$ = new Subject();
  subscription: Subscription;
  modalRef: BsModalRef;
  addedRecordId$ = new Subject();
  currentKey: number;
  dataType: any = dataTypeEnum;

  constructor(readonly service: CurrenciesService,
    private readonly cdRef: ChangeDetectorRef,
    private readonly ipxNotificationService: IpxNotificationService,
    readonly sbsModalRef: BsModalRef,
    readonly formBuilder: FormBuilder,
    private readonly navService: GridNavigationService,
    private readonly destroy$: IpxDestroy,
    private readonly shortcutsService: IpxShortcutsService,
    private readonly renderer: Renderer2) {
  }

  ngOnInit(): void {
    this.createFormGroup();
    if (!this.isAdding) {
      this.canNavigate = true;
      this.getCurrencyDetails(this.id);

      this.navData = {
        ...this.navService.getNavigationData(),
        fetchCallback: (currentIndex: number): any => {
          return this.navService.fetchNext$(currentIndex).toPromise();
        }
      };
      this.currentKey = this.navData.keys.filter(x => x.value === this.id)[0].key;
    } else {
      this.entry = new CurrencyItems();
    }
    this.handleShortcuts();
  }

  ngAfterViewInit(): void {

    this.form.controls.buyFactor.valueChanges.pipe(distinctUntilChanged(), debounceTime(200)).subscribe(value => {
      if (value) {
        this.getBuyRate();
      }
    });

    this.form.controls.buyRate.valueChanges.pipe(distinctUntilChanged(), debounceTime(300)).subscribe(value => {
      if (value) {
        this.getBuyFactor();
      }
    });

    this.form.controls.sellRate.valueChanges.pipe(distinctUntilChanged(), debounceTime(200)).subscribe(value => {
      if (value) {
        this.getSellFactor();
      }
    });

    this.form.controls.sellFactor.valueChanges.pipe(distinctUntilChanged(), debounceTime(200)).subscribe(value => {
      if (value) {
        this.getSellRate();
      }
    });

    this.form.controls.bankRate.valueChanges.pipe(distinctUntilChanged(), debounceTime(200)).subscribe(value => {
      if (value) {
        this.getSellRate();
        this.getBuyRate();
      }
    });

    this.form.controls.dateChanged.valueChanges.pipe(distinctUntilChanged(), debounceTime(200)).subscribe(() => {
      this.onDateChanged();
    });

    this.setFormStatus();
  }

  formatCurrencyCode = (): any => {
    const value = this.form.controls.currencyCode.value;
    if (!value) { return; }
    this.form.patchValue({ currencyCode: value.toUpperCase() });

    this.service.validateCurrencyCode(value).subscribe(res => {
      if (res) {
        this.form.controls.currencyCode.setErrors({ duplicateCurrencyCode: true });
        this.cdRef.markForCheck();
      }
    });
  };

  onDateChanged(): any {
    if (this.form.controls && !this.form.controls.dateChanged.value) {
      this.form.controls.dateChanged.setErrors({ invalid: 'required' });
      this.cdRef.markForCheck();
    }
  }

  getBuyRate = (): void => {
    const bankRate = this.form.controls.bankRate.value;
    if (bankRate) {
      const buyFactor = this.form.controls.buyFactor.value;
      this.form.patchValue({
        buyRate: (bankRate * buyFactor)
      }, {
        onlySelf: true,
        emitEvent: false
      });
      this.cdRef.markForCheck();
    }
  };

  getBuyFactor = (): void => {
    const bankRate = this.form.controls.bankRate.value;
    if (bankRate) {
      const buyRate = this.form.controls.buyRate.value;
      this.form.patchValue({
        buyFactor: (buyRate / bankRate)
      }, {
        onlySelf: true,
        emitEvent: false
      });
      this.cdRef.markForCheck();
    }
  };

  getSellFactor = (): void => {
    const bankRate = this.form.controls.bankRate.value;
    if (bankRate) {
      const sellRate = this.form.controls.sellRate.value;
      this.form.patchValue({
        sellFactor: (sellRate / bankRate)
      }, {
        onlySelf: true,
        emitEvent: false
      });
      this.cdRef.markForCheck();
    }
  };

  getSellRate = (): void => {
    const bankRate = this.form.controls.bankRate.value;
    if (bankRate) {
      const sellFactor = this.form.controls.sellFactor.value;
      this.form.patchValue({
        sellRate: (bankRate * sellFactor)
      }, {
        onlySelf: true,
        emitEvent: false
      });
      this.cdRef.markForCheck();
    }
  };

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

  getCurrencyDetails(key: string): any {
    if (key) {
      this.service.getCurrencyDetails(key).subscribe((res: CurrencyRequest) => {
        if (res) {
          this.setFormData(res);
        }
      });
    }
  }

  createFormGroup = (): FormGroup => {
    this.form = this.formBuilder.group({
      id: this.id,
      currencyCode: ['', Validators.compose([Validators.required, Validators.maxLength(3)])],
      currencyDescription: ['', Validators.compose([Validators.required, Validators.maxLength(40)])],
      buyRate: [''],
      buyFactor: [1, Validators.compose([Validators.required, Validators.max(10000000)])],
      sellRate: [''],
      sellFactor: [1, Validators.compose([Validators.required, Validators.max(10000000)])],
      roundedBillValues: ['', Validators.compose([Validators.maxLength(4)])],
      bankRate: [''],
      dateChanged: [new Date(), Validators.required]
    });

    return this.form;
  };

  setFormStatus = (): void => {
    setTimeout(() => {
      this.form.controls.dateChanged.markAsUntouched();
      this.form.markAsPristine();
      this.cdRef.markForCheck();
      if (!this.form.controls.dateChanged.dirty) {
        const input = this.dateChangedView.el.nativeElement.querySelector('.datepicker-input');
        this.renderer.removeClass(input, 'edited');
        this.cdRef.detectChanges();
      }
    }, 200);
  };

  get bankRate(): FormControl {
    return this.form.get('bankRate') as FormControl;
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

  get roundedBillValues(): FormControl {
    return this.form.get('roundedBillValues') as FormControl;
  }

  setFormData(data: CurrencyRequest): any {
    this.form.setValue({
      id: data.id,
      currencyCode: data.currencyCode,
      currencyDescription: data.currencyDescription,
      buyRate: data.buyRate,
      buyFactor: data.buyFactor,
      sellRate: data.sellRate,
      sellFactor: data.sellFactor,
      roundedBillValues: data.roundedBillValues,
      bankRate: data.bankRate,
      dateChanged: data.dateChanged ? new Date(data.dateChanged) : new Date()
    });
    this.setFormStatus();
    this.cdRef.markForCheck();
  }

  getNextCurrencyDetails(next: string): void {
    this.id = next;
    this.setFormStatus();
    this.getCurrencyDetails(next);
  }

  submit(): void {
    if (this.form.valid && this.form.value && this.form.dirty) {
      this.service.submitCurrency(this.form.value).subscribe((res) => {
        if (res) {
          this.addedRecordId$.next(res);
          this.onClose$.next({ success: true });
          this.form.setErrors(null);
          this.sbsModalRef.hide();
        }
        this.cdRef.markForCheck();
      });
    }
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
    this.onClose$.next(false);
    this.sbsModalRef.hide();
  };

}
