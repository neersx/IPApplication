import { FormBuilder } from '@angular/forms';
import { BsModalRefMock, ChangeDetectorRefMock, GridNavigationServiceMock, IpxNotificationServiceMock } from 'mocks';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { CurrencyRequest } from '../currencies.model';
import { MaintainCurrenciesComponent } from './maintain-currencies.component';

describe('MaintainCurrenciesComponent', () => {
  let component: MaintainCurrenciesComponent;
  let ipxNotificationService: IpxNotificationServiceMock;
  let bsModal: BsModalRefMock;
  const fb = new FormBuilder();
  let cdr: ChangeDetectorRefMock;
  let navService: GridNavigationServiceMock;
  let shortcutsService: IpxShortcutsServiceMock;
  let destroy$: any;

  const service = {
    getCurrencyDetails: jest.fn().mockReturnValue(of({})),
    validateCurrencyCode: jest.fn().mockReturnValue(of({})),
    submitCurrency: jest.fn().mockReturnValue(of({}))
  };

  beforeEach(() => {
    ipxNotificationService = new IpxNotificationServiceMock();
    bsModal = new BsModalRefMock();
    navService = new GridNavigationServiceMock();
    cdr = new ChangeDetectorRefMock();
    shortcutsService = new IpxShortcutsServiceMock();
    destroy$ = of({}).pipe(delay(1000));
    component = new MaintainCurrenciesComponent(service as any, cdr as any, ipxNotificationService as any, bsModal as any, fb, navService as any, destroy$, shortcutsService as any, {} as any);
    component.onClose$.next = jest.fn() as any;
    component.form = {
      reset: jest.fn(),
      value: {},
      valid: false,
      dirty: false
    };
    component.navData = {
      keys: [{ value: 1 }],
      totalRows: 3,
      pageSize: 10,
      fetchCallback: jest.fn().mockReturnValue({ keys: [{ value: 1 }, { value: 4 }, { value: 31 }] })
    };
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should set formData', () => {
    const data: CurrencyRequest = {
      id: 'AB',
      currencyCode: 'AB',
      currencyDescription: 'Code desc',
      dateChanged: new Date(),
      buyFactor: 1,
      sellFactor: 1
    };
    component.form = { setValue: jest.fn() };
    component.setFormData(data);
    expect(component.form.setValue).toBeCalledWith(data);
  });

  it('should create new formGroup', () => {
    component.createFormGroup();
    expect(component.form).not.toBeNull();
  });

  it('should submit formData', () => {
    const result = {
      id: 'AB',
      currencyCode: 'AB',
      currencyDescription: 'Code desc',
      dateChanged: new Date(),
      buyFactor: 1,
      sellFactor: 1.5,
      roundedBillValues: 2.5,
      buyRate: 5,
      bankRate: 5,
      sellRate: 7.5
    };
    component.form = {
      value: result,
      valid: true,
      dirty: true
    };
    component.submit();
    expect(component.form).not.toBeNull();
  });

  it('should discard changes', () => {
    component.form = {
      dirty: true
    };
    component.cancel();
    expect(component.form).not.toBeNull();
    component.sbsModalRef.content.confirmed$.subscribe(() => {
      expect(component.form).not.toBeNull();
    });
  });

  it('should reset form', () => {
    component.resetForm();
    expect(component.onClose$.next).toHaveBeenCalledWith(false);
    expect(bsModal.hide).toHaveBeenCalled();
    expect(component.form.reset).toBeCalled();
  });

  it('should get next currency details', () => {
    component.form = {
      markAsPristine: jest.fn()
    };
    jest.spyOn(component, 'getCurrencyDetails');
    component.getNextCurrencyDetails('ABC');
    expect(component.id).toBe('ABC');
    expect(component.getCurrencyDetails).toBeCalled();
  });

  it('should set error on empty date', () => {
    component.form = {
      markAsPristine: jest.fn(),
      controls: {
        dateChanged: {
          markAsDirty: jest.fn(),
          setErrors: jest.fn(),
          value: null
        }
      }
    };

    component.onDateChanged();
    expect(component.form.controls.dateChanged.setErrors).toBeCalledWith({ invalid: 'required' });
  });

  it('should validate unique currency code', () => {
    component.form = {
      patchValue: jest.fn(),
      markAsPristine: jest.fn(),
      controls: {
        currencyCode: {
          markAsDirty: jest.fn(),
          patchValue: jest.fn(),
          value: 'abc'
        }
      }
    };

    component.formatCurrencyCode();
    expect(component.form.patchValue).toBeCalledWith({ currencyCode: 'abc'.toUpperCase() });
    expect(service.validateCurrencyCode).toBeCalled();
  });

  it('should get correct buyRate', () => {
    component.form = {
      patchValue: jest.fn(),
      markAsPristine: jest.fn(),
      controls: {
        bankRate: { value: 5, valueChanges: jest.fn().mockReturnValue(of(1)) },
        buyFactor: { value: 1, valueChanges: jest.fn().mockReturnValue(of(1)) }
      }
    };

    component.getBuyRate();
    const bankRate = component.form.controls.bankRate.value;
    const buyFactor = component.form.controls.buyFactor.value;
    expect(component.form.patchValue).toBeCalledWith({
      buyRate: (bankRate * buyFactor)
    }, {
      onlySelf: true,
      emitEvent: false
    });
  });

  it('should get correct buyFactor', () => {
    component.form = {
      patchValue: jest.fn(),
      markAsPristine: jest.fn(),
      controls: {
        bankRate: { value: 5, valueChanges: jest.fn().mockReturnValue(of(1)) },
        buyRate: { value: 0, valueChanges: jest.fn().mockReturnValue(of({})) }
      }
    };

    component.getBuyFactor();
    const bankRate = component.form.controls.bankRate.value;
    const buyRate = component.form.controls.buyRate.value;
    expect(component.form.patchValue).toBeCalledWith({
      buyFactor: (buyRate / bankRate)
    }, {
      onlySelf: true,
      emitEvent: false
    });
  });

  it('should get correct sellRate', () => {
    component.form = {
      patchValue: jest.fn(),
      markAsPristine: jest.fn(),
      controls: {
        bankRate: { value: 5, valueChanges: jest.fn().mockReturnValue(of(1)) },
        sellFactor: { value: 1, valueChanges: jest.fn().mockReturnValue(of(1)) }
      }
    };

    component.getSellRate();
    const bankRate = component.form.controls.bankRate.value;
    const sellFactor = component.form.controls.sellFactor.value;
    expect(component.form.patchValue).toBeCalledWith({
      sellRate: (bankRate * sellFactor)
    }, {
      onlySelf: true,
      emitEvent: false
    });
  });

  it('should get correct sellFactor', () => {
    component.form = {
      patchValue: jest.fn(),
      markAsPristine: jest.fn(),
      controls: {
        bankRate: { value: 5, valueChanges: jest.fn().mockReturnValue(of(1)) },
        sellRate: { value: 1, valueChanges: jest.fn().mockReturnValue(of({})) }
      }
    };

    component.getSellFactor();
    const bankRate = component.form.controls.bankRate.value;
    const sellRate = component.form.controls.sellRate.value;
    expect(component.form.patchValue).toBeCalledWith({
      sellFactor: (sellRate / bankRate)
    }, {
      onlySelf: true,
      emitEvent: false
    });
  });

  it('should set formstatus', () => {
    component.form = {
      markAsPristine: jest.fn(),
      controls: {
        bankRate: { value: 5, valueChanges: jest.fn().mockReturnValue(of(1)) },
        sellRate: { value: 1, valueChanges: jest.fn().mockReturnValue(of({})) },
        dateChanged: {
          markAsUntouched: jest.fn(),
          dirty: true
        }
      }
    };

    component.setFormStatus();
    setTimeout(() => {
      expect(component.form.markAsPristine).toBeCalled();
      expect(component.form.controls.dateChanged.markAsUntouched).toBeCalled();
    }, 200);
  });

});
