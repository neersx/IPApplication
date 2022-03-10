import { FormBuilder } from '@angular/forms';
import { BsModalRefMock, CaseValidCombinationServiceMock, ChangeDetectorRefMock, IpxNotificationServiceMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { BehaviorSubject, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { ExchangeRateVariationModel, ExchangeRateVariationRequest } from '../exchange-rate-variations.model';
import { MaintainExchangerateVarComponent } from './maintain-exchangerate-var.component';

describe('MaintainExchangerateVarComponent', () => {
  let component: MaintainExchangerateVarComponent;
  let ipxNotificationService: IpxNotificationServiceMock;
  let bsModal: BsModalRefMock;
  const fb = new FormBuilder();
  let cdr: ChangeDetectorRefMock;
  let shortcutsService: IpxShortcutsServiceMock;
  let destroy$: any;
  let translateService: TranslateServiceMock;
  let notificationService: NotificationServiceMock;
  let validCombination: CaseValidCombinationServiceMock;

  const service = {
    getExchangeRateDetails: jest.fn().mockReturnValue(of({ id: 1, currency: { code: 'CA', value: 'Canadian Currency' } })),
    validateExchangeRateVariations: jest.fn().mockReturnValue(of({})),
    submitExchangeRateVariations: jest.fn().mockReturnValue(of(2))
  };

  beforeEach(() => {
    validCombination = new CaseValidCombinationServiceMock();
    notificationService = new NotificationServiceMock();
    translateService = new TranslateServiceMock();
    ipxNotificationService = new IpxNotificationServiceMock();
    bsModal = new BsModalRefMock();
    cdr = new ChangeDetectorRefMock();
    shortcutsService = new IpxShortcutsServiceMock();
    destroy$ = of({}).pipe(delay(1000));
    component = new MaintainExchangerateVarComponent(service as any, cdr as any, bsModal as any, fb, destroy$, shortcutsService as any, {} as any, validCombination as any, notificationService as any, ipxNotificationService as any, translateService as any, {} as any);
    component.onClose$.next = jest.fn() as any;
    component.form = {
      reset: jest.fn(),
      value: {},
      valid: false,
      dirty: false
    };
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should set formData', () => {
    const data: ExchangeRateVariationModel = {
      id: 1,
      currency: { code: 'AB', value: 'AB Description' },
      exchRateSch: null,
      buyRate: null,
      buyFactor: 1,
      sellRate: null,
      sellFactor: 1,
      caseCategory: { key: 'P', code: 'P', value: 'Patents' },
      caseType: { key: 'P', value: 'Properties' },
      subType: null,
      country: { code: 'AU', value: 'Australia' },
      propertyType: null,
      effectiveDate: new Date(),
      notes: 'Notes'
    };

    component.form = {
      patchValue: jest.fn(),
      markAsPristine: jest.fn(),
      get: jest.fn()
    };

    jest.spyOn(component, 'setFormStatus');
    component.form = { setValue: jest.fn() };
    component.setFormData(data);
    expect(component.form.setValue).toBeCalled();
    expect(component.setFormStatus).toBeCalled();
  });

  it('should create new formGroup', () => {
    component.createFormGroup();
    expect(component.form).not.toBeNull();
  });

  it('initialize component onInit', () => {
    jest.spyOn(component, 'createFormGroup');
    jest.spyOn(component, 'handleShortcuts');
    component.isAdding = true;
    component.ngOnInit();
    expect(component.form).not.toBeNull();
    expect(component.createFormGroup).toBeCalled();
    expect(component.handleShortcuts).toBeCalled();
    expect(validCombination.initFormData).toBeCalled();
  });

  it('should validate currency code and rate combination', () => {
    component.form = {
      patchValue: jest.fn(),
      markAsPristine: jest.fn(),
      get: jest.fn(),
      controls: {
        currency: {
          markAsDirty: jest.fn(),
          patchValue: jest.fn(),
          setErrors: jest.fn(),
          markAsTouched: jest.fn()
        },
        exchRateSch: {
          markAsDirty: jest.fn(),
          patchValue: jest.fn(),
          setErrors: jest.fn(),
          markAsTouched: jest.fn()
        }
      }
    };

    component.exchangeRateVarEl = {
      el: {
        nativeElement: {
          querySelector: jest.fn().mockReturnValue({
            click: jest.fn()
          })
        }
      }
    };
    component.currencyEl = {
      el: {
        nativeElement: {
          querySelector: jest.fn().mockReturnValue({
            click: jest.fn()
          })
        }
      }
    };
    jest.spyOn(component, 'clickEvents');
    component.currencyAndRateValidationPassed();
    expect(component.form.controls.currency.markAsTouched).toBeCalled();
    expect(component.form.controls.currency.markAsDirty).toBeCalled();
    expect(component.form.controls.currency.setErrors).toBeCalledWith({ currencyORExchRateRequired: true });
    expect(component.form.controls.exchRateSch.markAsTouched).toBeCalled();
    expect(component.form.controls.exchRateSch.setErrors).toBeCalledWith({ currencyORExchRateRequired: true });
    expect(component.clickEvents).toBeCalled();
  });

  it('should validate rate and factor combination', () => {
    component.form = {
      patchValue: jest.fn(),
      markAsPristine: jest.fn(),
      get: jest.fn(),
      controls: {
        buyRate: {
          markAsDirty: jest.fn(),
          patchValue: jest.fn(),
          setErrors: jest.fn(),
          markAsTouched: jest.fn()
        },
        sellRate: {
          markAsDirty: jest.fn(),
          patchValue: jest.fn(),
          setErrors: jest.fn(),
          markAsTouched: jest.fn()
        },
        buyFactor: {
          markAsDirty: jest.fn(),
          patchValue: jest.fn(),
          setErrors: jest.fn(),
          markAsTouched: jest.fn()
        },
        sellFactor: {
          markAsDirty: jest.fn(),
          patchValue: jest.fn(),
          setErrors: jest.fn(),
          markAsTouched: jest.fn()
        }
      }
    };

    component.rateFactorValidationPassed();
    expect(component.form.controls.buyRate.markAsTouched).toBeCalled();
    expect(component.form.controls.buyRate.setErrors).toBeCalledWith({ sellORFactorRequired: true });
    expect(component.form.controls.buyRate.markAsDirty).toBeCalled();
  });

  it('should call click events', () => {
    component.exchangeRateVarEl = {
      el: {
        nativeElement: {
          querySelector: jest.fn().mockReturnValue({
            click: jest.fn()
          })
        }
      }
    };
    component.currencyEl = {
      el: {
        nativeElement: {
          querySelector: jest.fn().mockReturnValue({
            click: jest.fn()
          })
        }
      }
    };
    component.clickEvents();
    expect(component.exchangeRateVarEl.el.nativeElement.querySelector).toBeCalledWith('input');
    expect(component.currencyEl.el.nativeElement.querySelector).toBeCalledWith('input');
  });

  it('should call disable rates', () => {
    component.form = {
      patchValue: jest.fn(),
      markAsPristine: jest.fn(),
      get: jest.fn(),
      controls: {
        buyRate: {
          markAsPristine: jest.fn()
        },
        sellRate: {
          markAsPristine: jest.fn()
        },
        buyFactor: {
          markAsPristine: jest.fn(),
          value: 1
        },
        sellFactor: {
          markAsPristine: jest.fn()
        }
      }
    };
    component.disableRate();
    expect(component.form.controls.buyRate.markAsPristine).toBeCalledWith();
    expect(component.form.controls.sellRate.markAsPristine).toBeCalledWith();
  });

  it('should call disable factor', () => {
    component.form = {
      patchValue: jest.fn(),
      markAsPristine: jest.fn(),
      get: jest.fn(),
      controls: {
        buyRate: {
          markAsPristine: jest.fn()
        },
        sellRate: {
          markAsPristine: jest.fn(),
          value: 1
        },
        buyFactor: {
          markAsPristine: jest.fn()
        },
        sellFactor: {
          markAsPristine: jest.fn()
        }
      }
    };
    component.disableFactor();
    expect(component.form.controls.buyFactor.markAsPristine).toBeCalledWith();
    expect(component.form.controls.sellFactor.markAsPristine).toBeCalledWith();
  });

  it('should set formstatus', () => {
    component.form = {
      markAsPristine: jest.fn(),
      controls: {
        effectiveDate: {
          markAsUntouched: jest.fn(),
          dirty: true
        }
      }
    };

    component.setFormStatus();
    setTimeout(() => {
      expect(component.form.markAsPristine).toBeCalled();
      expect(component.form.controls.effectiveDate.markAsUntouched).toBeCalled();
    }, 200);
  });

  it('should call onDateChanged', () => {
    component.form = {
      markAsPristine: jest.fn(),
      controls: {
        effectiveDate: {
          setErrors: jest.fn(),
          dirty: true
        }
      }
    };

    component.onDateChanged();
    expect(component.form.controls.effectiveDate.setErrors).toBeCalledWith({ effectiveDateRequired: 'required' });
  });

  it('should get exchangerate details', () => {
    component.form = {
      markAsDirty: jest.fn()
    };

    jest.spyOn(component, 'setFormData');
    component.getExchangeRateDetails(1);
    service.getExchangeRateDetails(1).subscribe(res => {
      expect(component.setFormData).toBeCalledWith(res);
    });
  });

  it('shouldinitialize controls state', () => {
    component.form = {
      markAsDirty: jest.fn(),
      markAsPristine: jest.fn(),
      controls: {
        subType: {
          markAsPristine: jest.fn()
        },
        propertyType: {
          markAsPristine: jest.fn()
        },
        caseCategory: {
          markAsPristine: jest.fn()
        }
      }
    };

    component.intializeControlsState();
    setTimeout(() => {
      expect(component.form.markAsPristine).toBeCalled();
      expect(component.form.controls.subType.markAsPristine).toBeCalled();
      expect(component.form.controls.propertyType.markAsPristine).toBeCalled();
    }, 100);
  });

  it('should save exchangerate variation data', () => {
    component.form = {
      setErrors: jest.fn()
    };
    const request: ExchangeRateVariationRequest = {
      id: null,
      currencyCode: 'AB',
      exchScheduleId: null,
      buyRate: null,
      buyFactor: 1,
      sellRate: null,
      sellFactor: 1,
      caseCategoryCode: 'P',
      caseTypeCode: null,
      subTypeCode: null,
      countryCode: 'AU',
      effectiveDate: new Date(),
      notes: 'Notes'
    };
    component.addedRecordId$ = new BehaviorSubject(1);
    component.saveExchangeRateVariation(request);
    service.submitExchangeRateVariations(request).subscribe(res => {
      expect(component.isSubmitted).toBeFalsy();
      expect(component.addedRecordId$.next).toBeCalledWith(res);
      expect(component.form.setErrors).toBeCalledWith(null);
    });
  });

  it('should submit requested data', () => {
    component.form = {
      markAsDirty: jest.fn(),
      valid: true,
      dirty: true,
      value: { id: null, currrency: { code: 'CA', description: 'AC' } }
    };
    const request: ExchangeRateVariationRequest = {
      id: null,
      currencyCode: 'AB',
      exchScheduleId: null,
      buyRate: null,
      buyFactor: 1,
      sellRate: null,
      sellFactor: 1,
      caseCategoryCode: 'P',
      caseTypeCode: null,
      subTypeCode: null,
      countryCode: 'AU',
      effectiveDate: new Date(),
      notes: 'Notes'
    };
    jest.spyOn(component, 'rateFactorValidationPassed').mockReturnValue(true);
    jest.spyOn(component, 'currencyAndRateValidationPassed').mockReturnValue(true);
    jest.spyOn(component, 'prepareRequest').mockReturnValue(request);
    jest.spyOn(component, 'saveExchangeRateVariation');
    component.submit();
    service.validateExchangeRateVariations(request).subscribe(res => {
      expect(component.setFormData).toBeCalledWith(res);
      expect(component.saveExchangeRateVariation).toBeCalledWith(res);
    });
  });
});
