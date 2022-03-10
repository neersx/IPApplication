import { FormBuilder } from '@angular/forms';
import { BsModalRefMock, ChangeDetectorRefMock, IpxNotificationServiceMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { BehaviorSubject, of } from 'rxjs';
import { RecordalElementComponent } from './recordal-element.component';

describe('RecordalElementComponent', () => {
  let component: RecordalElementComponent;
  const service = {
    deleteRecordalType: jest.fn().mockReturnValue(of({})),
    isAddAnotherChecked: {
      getValue: jest.fn(),
      next: jest.fn()
    },
    getAllElements: jest.fn().mockReturnValue(of([{ key: 0, value: 'Element 1' }, { key: 1, value: 'New Name' }]))
  };
  let changeDetectorRef: ChangeDetectorRefMock;
  let ipxNotificationService: IpxNotificationServiceMock;
  let bsModal: BsModalRefMock;
  let translate: TranslateServiceMock;
  let fb: FormBuilder;

  beforeEach(() => {
    changeDetectorRef = new ChangeDetectorRefMock();
    ipxNotificationService = new IpxNotificationServiceMock();
    bsModal = new BsModalRefMock();
    translate = new TranslateServiceMock();
    fb = new FormBuilder();
    component = new RecordalElementComponent(service as any, changeDetectorRef as any,
      ipxNotificationService as any, bsModal as any, translate as any, fb as any);

    component.onClose$.next = jest.fn() as any;
    component.dataItem = {
      id: 123,
      element: { key: 1, value: 'New Name' },
      elementLabel: 'New Name Label',
      nameType: { key: 12, code: 'A', value: 'Agent' },
      attribute: { key: 'MAN', value: 'Mandatory' }
    };
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should initialize component', () => {
    jest.spyOn(component, 'createFormGroup');
    jest.spyOn(component, 'setFormData');
    component.form = { patchValue: jest.fn() };
    component.ngOnInit();
    expect(component.isAddAnotherChecked).toBeFalsy();
    expect(component.isSaveDisabled).toBeTruthy();
    expect(component.setFormData).toBeCalled();
    expect(component.createFormGroup).toBeCalled();
  });

  it('should set data in form', () => {
    const data = component.dataItem;
    component.form = { patchValue: jest.fn() };
    component.setFormData(data);
    expect(component.form.patchValue).toBeCalledWith(data);
  });

  it('should not set data if null', () => {
    component.form = { patchValue: jest.fn() };
    component.setFormData(null);
    expect(component.form.patchValue).not.toBeCalled();
  });

  it('should set form state in afterview Init', () => {
    component.isAddAnother = false;
    component.form = {
      patchValue: jest.fn(),
      markAsPristine: jest.fn()
    };
    component.ngAfterViewInit();
    expect(component.form.markAsPristine).toBeCalledWith();
  });

  it('should create new formGroup', () => {
    component.createFormGroup();
    expect(component.form).not.toBeNull();
  });

  it('should check add another checkbox', () => {
    component.onAddAnotherChanged();
    expect(service.isAddAnotherChecked.next).toBeCalledWith(component.isAddAnotherChecked);
  });

  it('should submit element form', () => {
    component.form = {
      reset: jest.fn(),
      valid: true,
      setErrors: jest.fn()
    };
    component.submit();
    expect(bsModal.hide).toHaveBeenCalled();
    expect(component.onClose$.next).toHaveBeenCalledWith({ success: true, formGroup: component.form });
    expect(component.form.setErrors).toHaveBeenCalledWith(null);
  });

  it('should reset form', () => {
    component.form = {
      reset: jest.fn()
    };
    component.resetForm(true);
    expect(service.isAddAnotherChecked.next).toBeCalledWith(false);
    expect(bsModal.hide).toHaveBeenCalled();
    expect(component.form.reset).toBeCalled();
  });
});
