import { FormBuilder } from '@angular/forms';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRefMock, ChangeDetectorRefMock, IpxNotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { CaseRequest } from '../../case-debtor.model';
import { CaseStatusRestrictionComponent } from './case-status-restriction.component';
import { MaintainCaseDebtorComponent } from './maintain-case-debtor.component';

describe('MaintainCaseDebtorComponent', () => {
  let component: MaintainCaseDebtorComponent;
  let cdr: ChangeDetectorRefMock;
  let ipxNotificationService: IpxNotificationServiceMock;
  let fb: FormBuilder;
  let modalService: BsModalRefMock;
  let ipxModalService: ModalServiceMock;
  let shortcutsService: IpxShortcutsServiceMock;
  let destroy$: any;
  let service: {
    getCases: any;
  };

  beforeEach(() => {
    service = {
      getCases: jest.fn().mockReturnValue(of({ CaseList: [{ IsMainCase: false, CaseId: 123, DraftBills: [22, 34] }, { IsMainCase: true, CaseId: 976, DraftBills: [232, 634] }] }))
    };
    fb = new FormBuilder();
    ipxNotificationService = new IpxNotificationServiceMock();
    cdr = new ChangeDetectorRefMock();
    modalService = new BsModalRefMock();
    ipxModalService = new ModalServiceMock();
    shortcutsService = new IpxShortcutsServiceMock();
    destroy$ = of({}).pipe(delay(1000));
    component = new MaintainCaseDebtorComponent(service as any, ipxNotificationService as any, modalService as any, fb, cdr as any, destroy$, shortcutsService as any, ipxModalService as any);
    component.dataItem = {
      renew: false
    };
    component.grid = {
      rowCancelHandler: jest.fn(),
      checkChanges: jest.fn(),
      isValid: jest.fn(),
      isDirty: jest.fn(),
      wrapper: {
        data: [
          {
            CaseId: 500,
            IsMainCase: true,
            status: 'A'
          }, {
            CaseId: 100,
            IsMainCase: false,
            status: 'A'
          }
        ]
      }
    } as any;

    component.form = {
      markAsDirty: jest.fn(),
      reset: jest.fn(),
      value: {},
      valid: false,
      dirty: false,
      controls: {
        case: {
          markAsTouched: jest.fn(),
          markAsDirty: jest.fn(),
          setErrors: jest.fn(),
          value: { key: 'Acb', code: 'Acb', value: 'Abc Value' },
          valueChanges: new Observable<any>(),
          setValue: jest.fn()
        },
        caseList: {
          markAsTouched: jest.fn(),
          markAsPristine: jest.fn(),
          markAsDirty: jest.fn(),
          setErrors: jest.fn(),
          value: 192,
          valueChanges: new Observable<any>(),
          setValue: jest.fn()
        }
      }
    };
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('initialize component', () => {
    it('initialize variable on ngOnInit', () => {
      jest.spyOn(component, 'createFormGroup');
      component.ngOnInit();
      expect(component.createFormGroup).toHaveBeenCalledWith(component.dataItem);
      expect(component.isSingleCase).toBe(true);

    });

    it('create FromGroup', () => {
      const dataItem = {
        case: -927,
        IsMainCase: true
      };
      component.dataItem = dataItem;
      jest.spyOn(component, 'createFormGroup');
      component.ngOnInit();
      expect(component.createFormGroup).toHaveBeenCalled();
    });

    it('should initialize shortcuts', () => {
      component.ngOnInit();
      expect(shortcutsService.observeMultiple$).toHaveBeenCalledWith([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT]);
    });

    it('create FromGroup with empty dataItem', () => {
      component.dataItem = null;
      component.form = null;
      component.createFormGroup(component.dataItem);
      expect(component.form).toBeNull();
    });

    it('should intialize afterview init', () => {
      component.form = {
        controls: {
          case: {
            valueChanges: new Observable<any>()
          },
          caseList: {
            valueChanges: new Observable<any>()
          }
        }
      };
      component.isSingleCase = false;
      component.rowIndex = 0;
      jest.spyOn(component, 'createFormGroup');
      component.ngAfterViewInit();
      expect(component.hasMainCase).toBeTruthy();
      expect(component.isFirstCaseAdding).toBe(false);
      expect(component.mainCaseId).not.toBe(null);
    });
  });

  it('should apply form', () => {
    component.rowIndex = 0;
    component.form = {
      valid: true,
      markAsDirty: jest.fn(),
      reset: jest.fn(),
      value: {
        caseList: { caseKeys: [123, 92] },
        case: [{ key: 22 }]
      }
    };
    jest.spyOn(component, 'getAssociatedCases');
    const rowObject = { rowIndex: 0, dataItem: component.dataItem, formGroup: component.form } as any;
    component.apply();
    expect(component.getAssociatedCases).toHaveBeenCalledWith(rowObject);
    expect(component.newCaseId).toBe(22);
    expect(component.newCases).toEqual([123, 92]);
  });

  it('should call getAssociatedCases', (done) => {
    component.form = {
      valid: true,
      value: {
        caseList: { caseKeys: [123, 92], CaseId: 12 },
        case: { key: 22 }
      },
      caseList: { caseKeys: [123, 92], CaseId: 12 },
      case: { key: 22 }
    };

    const request: CaseRequest = {
      caseListId: component.form.caseList ? component.form.caseList.key : null,
      caseIds: component.form.caseList && component.form.caseList.caseKeys ? component.form.caseList.caseKeys.join(', ') : component.form.case.key.toString(),
      entityId: component.entityNo,
      raisedByStaffId: component.raisedByStaffId
    };
    jest.spyOn(component, 'validateCaseStatusRestriction');
    const row = { rowIndex: 0, dataItem: component.dataItem, formGroup: component.form } as any;
    component.getAssociatedCases(row);
    service.getCases(request).subscribe((result) => {
      expect(result).toBeTruthy();
      expect(component.validateCaseStatusRestriction).toHaveBeenCalledWith([{ CaseId: 976, DraftBills: [232, 634], IsMainCase: true }], row);
      done();
    });
  });

  describe('Case Status Restriction', () => {
    it('should thorw error when single case status is restricted for billing', () => {
      component.isSingleCase = true;
      const response = [{ CaseId: 123, CaseReference: 'Acb', HasRestrictedStatusForBilling: true }];
      component.form.get = jest.fn().mockReturnValue(component.form.controls.case);
      component.validateCaseStatusRestriction(response, null);
      expect(ipxNotificationService.openAlertModal).toBeCalledWith('accounting.billing.step1.caseRestriction', 'field.errors.billing.validations.caseStatusRestriction', null, null, 'Acb');
    });
    it('should call case list retriction modal if case list is provided', (done) => {
      const response = [{ CaseId: 123, HasRestrictedStatusForBilling: true }, { CaseId: 234, HasRestrictedStatusForBilling: false }];
      component.proceedAfterStatusValidation = jest.fn();
      component.form.get = jest.fn().mockReturnValue(component.form.controls.caseList);
      component.isSingleCase = false;
      ipxModalService.content = { onClose$: of(true) };
      component.validateCaseStatusRestriction(response, null);
      expect(ipxModalService.openModal).toHaveBeenCalledWith(CaseStatusRestrictionComponent, {
        animated: false,
        backdrop: 'static',
        class: 'modal-lg',
        initialState: {
          caseList: [{ CaseId: 123, HasRestrictedStatusForBilling: true }],
          allcasesRestricted: false
        }
      });
      ipxModalService.content.onClose$.subscribe(res => {
        expect(component.proceedAfterStatusValidation).toBeCalledWith([{ CaseId: 234, HasRestrictedStatusForBilling: false }], null);
        done();
      });
    });
    it('should throw error when all cases in case list has restricted status', (done) => {
      const response = [{ CaseId: 123, HasRestrictedStatusForBilling: true }, { CaseId: 234, HasRestrictedStatusForBilling: true }];
      component.proceedAfterStatusValidation = jest.fn();
      component.form.get = jest.fn().mockReturnValue(component.form.controls.caseList);
      component.isSingleCase = false;
      ipxModalService.content = { onClose$: of(true) };
      component.validateCaseStatusRestriction(response, null);
      expect(ipxModalService.openModal).toHaveBeenCalledWith(CaseStatusRestrictionComponent, {
        animated: false,
        backdrop: 'static',
        class: 'modal-lg',
        initialState: {
          caseList: [{ CaseId: 123, HasRestrictedStatusForBilling: true }, { CaseId: 234, HasRestrictedStatusForBilling: true }],
          allcasesRestricted: true
        }
      });
      ipxModalService.content.onClose$.subscribe(res => {
        expect(res).toBe(true);
        done();
      });
    });
    it('should proceed if no case status restriction', () => {
      const response = [{ CaseId: 123, HasRestrictedStatusForBilling: false, DraftBills: [22, 34], IsMainCase: true }, { CaseId: 234, HasRestrictedStatusForBilling: false, DraftBills: [22, 34], IsMainCase: false }];
      jest.spyOn(component, 'proceedAfterStatusValidation');
      jest.spyOn(component, 'closeModal');
      jest.spyOn(component, 'validateCases');
      component.isSingleCase = false;
      const rowObject = { rowIndex: 0, dataItem: component.dataItem, formGroup: component.form } as any;
      component.validateCaseStatusRestriction(response, rowObject);
      expect(component.proceedAfterStatusValidation).toBeCalled();
      expect(component.validateCases).toBeCalled();
    });
    it('should return if cancel is clicked on case status restriction', (done) => {
      const response = [{ CaseId: 123, HasRestrictedStatusForBilling: true }, { CaseId: 234, HasRestrictedStatusForBilling: false }];
      jest.spyOn(component, 'proceedAfterStatusValidation');
      component.isSingleCase = false;
      ipxModalService.content = { onClose$: of(false) };
      component.validateCaseStatusRestriction(response, null);
      expect(ipxModalService.openModal).toHaveBeenCalledWith(CaseStatusRestrictionComponent, {
        animated: false,
        backdrop: 'static',
        class: 'modal-lg',
        initialState: {
          caseList: [{ CaseId: 123, HasRestrictedStatusForBilling: true }],
          allcasesRestricted: false
        }
      });
      ipxModalService.content.onClose$.subscribe(res => {
        expect(res).toBe(false);
        done();
      });
    });
  });

  it('should validate cases', () => {
    component.form = {
      value: {
        caseList: { caseKeys: [123, 92] },
        case: { key: 22 }
      }
    };
    const response = [{ CaseId: 123, DraftBills: [22, 34] }, { CaseId: 976, DraftBills: [232, 634] }];
    jest.spyOn(component, 'validationOperations');
    const rowObject = { rowIndex: 0, dataItem: component.dataItem, formGroup: component.form } as any;
    component.validateCases(123, rowObject, response);
    expect(component.validationOperations).toHaveBeenCalledWith(rowObject, response);
  });

  it('should call validationOperations', () => {
    component.form = {
      valid: true,
      value: {
        caseList: { caseKeys: [123, 92] },
        case: { key: 22 }
      }
    };
    const response = [{ CaseId: 123, DraftBills: [22, 34] }, { CaseId: 976, DraftBills: [232, 634] }];
    jest.spyOn(component, 'getUniqueCases');
    const rowObject = { rowIndex: 0, dataItem: component.dataItem, formGroup: component.form } as any;
    component.validationOperations(rowObject, response);
    expect(component.getUniqueCases).toHaveBeenCalled();
  });

  it('should call validationOperations', () => {
    component.rowIndex = 0;
    component.form = {
      valid: true,
      value: {
        caseList: { caseKeys: [123, 92] },
        case: { key: 22 }
      }
    };
    component.grid = {
      rowCancelHandler: jest.fn(),
      wrapper: {
        data: [
          {
            IsMainCase: true,
            status: 'A'
          }, {
            IsMainCase: false,
            status: 'A'
          }
        ]
      }
    } as any;
    const response = [{ CaseId: 123, DraftBills: [22, 34] }, { CaseId: 976, DraftBills: [232, 634] }];
    jest.spyOn(component, 'getUniqueCases');
    const rowObject = { rowIndex: 0, dataItem: component.dataItem, formGroup: component.form } as any;
    component.validationOperations(rowObject, response);
    expect(component.getUniqueCases).toHaveBeenCalled();
    expect(component.hasMainCase).toBeTruthy();
  });

  it('should call getUniqueCases', () => {
    component.rowIndex = 0;
    component.grid = {
      rowCancelHandler: jest.fn(),
      wrapper: {
        data: [
          {
            CaseId: 100,
            IsMainCase: true
          }, {
            CaseId: 100,
            IsMainCase: false
          },
          {
            CaseId: 234,
            IsMainCase: false
          }
        ]
      }
    } as any;

    const result = component.getUniqueCases();
    expect(result).not.toBeNull();
    expect(component.grid.wrapper.data.length).toBe(2);
  });

  describe('cancel', () => {
    it('cancel form changes if form not dirty', () => {
      jest.spyOn(component, 'resetForm');
      component.cancel();
      expect(component.resetForm).toHaveBeenCalled();
    });

    it('close Modal form with correct data', () => {
      jest.spyOn(component, 'resetForm');
      component.onClose$ = { getValue: jest.fn().mockReturnValue(true), next: jest.fn() } as any;
      component.closeModal(true);
      expect(component.onClose$.next).toHaveBeenCalled();
    });
  });
});
