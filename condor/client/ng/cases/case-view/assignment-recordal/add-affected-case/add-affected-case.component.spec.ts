import { fakeAsync, tick } from '@angular/core/testing';
import { FormBuilder } from '@angular/forms';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRefMock, ChangeDetectorRefMock, IpxNotificationServiceMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { RecordalStepElementForm, StepElements } from '../affected-cases.model';
import { AddAffetcedRequestModel } from '../model/affected-case.model';
import { AddAffectedCaseComponent } from './add-affected-case.component';

describe('AddAffectedCaseComponent', () => {
  let component: AddAffectedCaseComponent;
  let service: {
    rowSelected$: BehaviorSubject<StepElements>;
    stepElementForm: Array<RecordalStepElementForm>;
    getRecordalSteps(caseKey: number): any;
    submitAffectedCase(model: any): Observable<any>;
    getRecordalStepElements(caseKey: number, stepId: number): any;
    clearStepElementRowFormData(stepId: number, rowId: number): void;
    clearStepElementFormData(): void;
    saveRecordalSteps(data: any): Observable<any>;
    validateAddAffectedCase(caseKey: number, code: string, officialNo: string): any;
  };
  let cdRef: ChangeDetectorRefMock;
  let modalRef: BsModalRefMock;
  let formBuilder: FormBuilder;
  let translateService: TranslateServiceMock;
  let ipxNotificationService: IpxNotificationServiceMock;
  let notificationService: NotificationServiceMock;
  let shortcutsService: IpxShortcutsServiceMock;
  let destroy$: any;

  beforeEach(() => {
    const steps = [{ id: 1, stepId: 1, isSelected: false, stepName: 'Step 1', recordalType: { key: 1 } }];
    service = {
      rowSelected$: new BehaviorSubject<StepElements>({ stepId: 1 } as any),
      stepElementForm: [
        {
          stepId: 1, rowId: 1, form: { status: 'INVALID', dirty: false }
        }
      ] as any,
      getRecordalSteps: jest.fn().mockReturnValue(of(steps)),
      submitAffectedCase: jest.fn().mockReturnValue(of({})),
      getRecordalStepElements: jest.fn(),
      clearStepElementRowFormData: jest.fn(),
      clearStepElementFormData: jest.fn(),
      saveRecordalSteps: jest.fn().mockReturnValue(new Observable()),
      validateAddAffectedCase: jest.fn().mockReturnValue(of([{ key: 123, code: 'abc/123' }]))
    };
    cdRef = new ChangeDetectorRefMock();
    modalRef = new BsModalRefMock();
    formBuilder = new FormBuilder();
    translateService = new TranslateServiceMock();
    notificationService = new NotificationServiceMock();
    ipxNotificationService = new IpxNotificationServiceMock();
    shortcutsService = new IpxShortcutsServiceMock();
    destroy$ = of({}).pipe(delay(1000));
    component = new AddAffectedCaseComponent(service as any, cdRef as any, ipxNotificationService as any, notificationService as any, modalRef as any, translateService as any, formBuilder as any, destroy$, shortcutsService as any);
    (component as any).sbsModalRef = {
      hide: jest.fn()
    } as any;
    component.steps = steps;
    component.formGroup = {
      value: {
        jurisdiction: {},
        officialNo: '1234',
        cases: [{ key: 123, code: '123/1A' }],
        recordalSteps: [{ id: 1, stepId: 1, isSelected: true, stepName: 'Step 1', recordalType: { key: 1 } }]
      },
      patchValue: jest.fn(),
      markAsPristine: jest.fn(),
      setErrors: jest.fn(),
      markAsDirty: jest.fn(),
      get: jest.fn().mockReturnValue([])
    };
  });

  it('should create component', () => {
    expect(component).toBeTruthy();
  });

  it('should initialize component', (done) => {
    jest.spyOn(component, 'createFormGroup');
    component.ngOnInit();
    service.getRecordalSteps(component.caseKey).subscribe((res: any) => {
      expect(component.steps).toBe(res);
      expect(component.createFormGroup).toBeCalled();
      expect(component.formGroup).toBeDefined();
      done();
    });
  });

  it('should initialize shortcuts', () => {
    component.ngOnInit();
    expect(shortcutsService.observeMultiple$).toHaveBeenCalledWith([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT]);
  });

  it('should call save if shortcut is given', fakeAsync(() => {
    component.submit = jest.fn();
    shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SAVE;
    component.ngOnInit();
    tick(shortcutsService.interval);

    expect(component.submit).toHaveBeenCalled();
  }));
  it('should call revert if shortcut is given', fakeAsync(() => {
    component.cancel = jest.fn();
    shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.REVERT;
    component.ngOnInit();
    tick(shortcutsService.interval);

    expect(component.cancel).toHaveBeenCalled();
  }));

  it('should call caseChange with value', () => {
    jest.spyOn(component, 'validateFormState').mockResolvedValue(false);
    component.onCaseChange();
    expect(component.isExternalCaseDisabled).toBeFalsy();
    expect(component.validateFormState).toBeCalled();
  });

  it('should call caseChange with null', () => {
    jest.spyOn(component, 'validateFormState').mockResolvedValue(false);
    component.onCaseChange();
    expect(component.isExternalCaseDisabled).toBeFalsy();
    expect(component.validateFormState).toBeCalled();
    expect(component.formGroup.setErrors).toBeCalledWith({ invalid: true });
  });

  it('should call onOfficialNoChange', () => {
    jest.spyOn(component, 'confirmCases');
    jest.spyOn(component, 'validateFormState').mockResolvedValue(false);
    component.checkChanges();
    service.validateAddAffectedCase(123, 'AU', '12345').subscribe(res => {
      expect(res.length).toBe(1);
      expect(component.confirmCases).toBeCalledWith(res);
    });
    expect(component.isExternalCaseDisabled).toBeFalsy();
    expect(component.isCaseReferenceDisabled).toBeTruthy();
    expect(component.validateFormState).toBeCalled();
  });

  it('should call validate FormState', () => {
    const result = component.validateFormState();
    expect(result).toBeTruthy();
    expect(component.isExternalCaseDisabled).toBeFalsy();
    expect(component.formGroup.setErrors).toBeCalledWith(null);
  });

  it('should call on checkbox change', () => {
    jest.spyOn(component, 'validateFormState');
    const step = component.steps[0];
    component.onCheckboxChange();

    expect(component.isExternalCaseDisabled).toBeFalsy();
    expect(component.formGroup.setErrors).toBeCalledWith(null);
  });

  it('should submit valid data for save', () => {
    component.onClose$.next = jest.fn() as any;
    jest.spyOn(component, 'validateFormState').mockReturnValue(true);
    jest.spyOn(component, 'cancel');
    component.formGroup.value.recordalSteps = [{ id: 1, stepId: 1, isSelected: true, stepName: 'Step 1', recordalType: { key: 1 } }];
    const request: AddAffetcedRequestModel = {
      caseId: component.caseKey,
      relatedCases: [],
      jurisdiction: component.formGroup.value.jurisdiction,
      officialNo: component.formGroup.value.officialNo,
      recordalSteps: component.formGroup.value.recordalSteps
    };

    component.submit();
    service.submitAffectedCase(request).subscribe(() => {
      expect(component.cancel).toBeCalled();
    });
  });
});
