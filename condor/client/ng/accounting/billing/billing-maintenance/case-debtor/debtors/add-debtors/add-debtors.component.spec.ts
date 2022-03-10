import { FormBuilder } from '@angular/forms';
import { BillingStepsPersistanceService } from 'accounting/billing/billing-steps-persistance.service';
import { BillingServiceMock } from 'accounting/billing/billing.mocks';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRefMock, ChangeDetectorRefMock, IpxNotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { AddDebtorsComponent } from './add-debtors.component';

describe('AddDebtorsComponent', () => {
    let component: AddDebtorsComponent;
    let cdr: ChangeDetectorRefMock;
    let ipxNotificationService: IpxNotificationServiceMock;
    let fb: FormBuilder;
    let modalService: BsModalRefMock;
    let ipxModalService: ModalServiceMock;
    let shortcutsService: IpxShortcutsServiceMock;
    let destroy$: any;
    let service: {
        getDebtors: any;
        getCaseDebtorDetails: any;
        getOpenItemDebtors: any;
    };
    let billingStepsService: BillingStepsPersistanceService;
    let billingService: BillingServiceMock;

    beforeEach(() => {
        ipxNotificationService = new IpxNotificationServiceMock();
        service = {
            getDebtors: jest.fn().mockReturnValue(of({ errors: null, DebtorList: [{ NameId: 123, BillToNameId: 345 }] })),
            getCaseDebtorDetails: jest.fn().mockReturnValue(of({ errors: null, DebtorList: [{ NameId: 123, BillToNameId: 345 }] })),
            getOpenItemDebtors: jest.fn().mockReturnValue(of({ errors: null, DebtorList: [{ NameId: 123, BillToNameId: 345 }] }))
        };
        billingStepsService = new BillingStepsPersistanceService();
        cdr = new ChangeDetectorRefMock();
        fb = new FormBuilder();
        ipxNotificationService = new IpxNotificationServiceMock();
        modalService = new BsModalRefMock();
        ipxModalService = new ModalServiceMock();
        shortcutsService = new IpxShortcutsServiceMock();
        billingService = new BillingServiceMock();
        destroy$ = of({}).pipe(delay(1000));
        component = new AddDebtorsComponent(service as any, billingStepsService as any, modalService as any, ipxNotificationService as any, fb, shortcutsService as any, destroy$, cdr as any, billingService as any);
        (component as any).sbsModalRef = {
            hide: jest.fn()
        } as any;
        component.dataItem = {
            DebtorCheckbox: false,
            FormattedNameWithCode: { key: 1, displayName: 'abc' },
            AttentionName: { key: 1, displayName: 'att1' }
        };
        component.grid = {
            rowCancelHandler: jest.fn(),
            checkChanges: jest.fn(),
            isValid: jest.fn(),
            isDirty: jest.fn(),
            wrapper: {
                data: [
                    {
                        DebtorCheckbox: false,
                        FormattedNameWithCode: { key: 1, displayName: 'abc' },
                        AttentionName: { key: 1, displayName: 'att1' }
                    }, {
                        DebtorCheckbox: false,
                        FormattedNameWithCode: { key: 2, displayName: 'def' },
                        AttentionName: { key: 1, displayName: 'att2' }
                    }
                ]
            }
        } as any;
        component.isAdding = true;
        component.formGroup = {
            markAsDirty: jest.fn(),
            reset: jest.fn(),
            value: {},
            valid: false,
            dirty: false,
            controls: {
                DebtorCheckbox: {
                    markAsTouched: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: false,
                    valueChanges: new Observable<any>(),
                    setValue: jest.fn()
                },
                FormattedNameWithCode: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: { key: 1, displayName: 'abc' },
                    valueChanges: new Observable<any>(),
                    setValue: jest.fn()
                },
                AttentionName: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: { key: 1, displayName: 'xyz' },
                    valueChanges: new Observable<any>(),
                    setValue: jest.fn()
                },
                Reason: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: { key: 1, displayName: 'xyz' },
                    valueChanges: new Observable<any>(),
                    setValue: jest.fn(),
                    reset: jest.fn()
                }
            }
        };
    });

    describe('initialize component', () => {
        it('should create', () => {
            expect(component).toBeTruthy();
        });

        it('initialize variable on ngOnInit', () => {
            jest.spyOn(component, 'createFormGroup');
            component.ngOnInit();
            expect(component.createFormGroup).toHaveBeenCalled();
            expect(component.disableFields).toBe(true);

        });

        it('create FromGroup', () => {
            const dataItem = {
                FormattedNameWithCode: -927,
                AddressId: 123,
                AttentionNameId: 456,
                ReferenceNo: 'xyz'
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
    });

    describe('onAddressChange', () => {
        it('should enable reason when address/attention/reference is changed', () => {
            component.disableReason = true;
            const event = {
                address: 'add1'
            };
            component.onAddressChange(event);
            expect(component.disableReason).toBeFalsy();
        });
        it('should disable and reset reason when address/attention/reference is undefined', () => {
            component.onAddressChange(null);
            expect(component.disableReason).toBeTruthy();
        });
    });

    describe('onDebtorChange', () => {
        it('should call getDebtor service when debtor is defined', () => {
            component.disableReason = true;
            const stepResponse = {
                stepData: {
                    currentAction: { key: 1, code: 'abc' },
                    entity: 123455,
                    raisedBy: { key: 1 },
                    useRenewalDebtor: true
                }
            };
            billingStepsService.getStepData = jest.fn().mockReturnValue(stepResponse);
            const event = {
                key: 123
            };
            component.onDebtorChange(event);
            expect(component.debtorKey).toEqual(event.key);
            expect(service.getDebtors).toHaveBeenCalled();
        });
    });

    describe('apply', () => {
        it('should apply form if formGroup is valid', () => {
            const reasons = [{ key: 1, value: 'Reason1' }, { key: 2, value: 'Reason2' }, { key: 3, value: 'Reason3' }];
            component.reasonList = [{ key: 1, value: 'Reason1' }];
            billingService.reasonList$.next(reasons);
            component.rowIndex = 0;
            component.formGroup = {
                valid: true,
                markAsDirty: jest.fn(),
                reset: jest.fn(),
                controls: {
                    Reason: {
                        value: 'Reason1',
                        markAsPristine: jest.fn(),
                        markAsTouched: jest.fn(),
                        setErrors: jest.fn(),
                        markAsDirty: jest.fn()
                    }
                },
                value: { Reason: '' }
            };
            const newLocal = true;
            component.validateRequiredFiled = jest.fn().mockReturnValue(of(newLocal));
            component.apply();
            expect((component as any).sbsModalRef.hide).toHaveBeenCalled();
        });
        it('should apply not close the modal if formGroup is invalid', () => {
            const reasons = [{ key: 1, value: 'Reason1' }, { key: 2, value: 'Reason2' }, { key: 3, value: 'Reason3' }];
            component.reasonList = [{ key: 1, value: 'Reason1' }];
            billingService.reasonList$.next(reasons);
            component.rowIndex = 0;
            component.formGroup = {
                valid: false,
                markAsDirty: jest.fn(),
                reset: jest.fn(),
                controls: {
                    Reason: {
                        value: 'Reason1',
                        markAsPristine: jest.fn(),
                        markAsTouched: jest.fn(),
                        setErrors: jest.fn(),
                        markAsDirty: jest.fn()
                    }
                },
                value: { Reason: '' }
            };
            const newLocal = true;
            component.validateRequiredFiled = jest.fn().mockReturnValue(of(newLocal));
            component.apply();
            expect((component as any).sbsModalRef.hide).not.toHaveBeenCalled();
        });
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
            component.cancel();
            expect(component.onClose$.next).toHaveBeenCalled();
        });
    });

    describe('toggleReason', () => {
        it('should disable reason if event is defined', () => {
            const event = { key: 1, value: 'Add1' };
            component.toggleReason(event);
            expect(component.disableReason).toBeFalsy();
        });
    });
});
