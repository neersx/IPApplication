import { FormBuilder } from '@angular/forms';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRefMock, ChangeDetectorRefMock, IpxNotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { MaintainDebtorCopiesToComponent } from './maintain-debtor-copies-to.component';

describe('AddCopiesToNamesComponent', () => {
    let component: MaintainDebtorCopiesToComponent;
    let cdr: ChangeDetectorRefMock;
    let ipxNotificationService: IpxNotificationServiceMock;
    let fb: FormBuilder;
    let modalService: BsModalRefMock;
    let ipxModalService: ModalServiceMock;
    let shortcutsService: IpxShortcutsServiceMock;
    let destroy$: any;
    let service: {
        getDebtorCopiesToDetails: any;
    };
    beforeEach(() => {
        ipxNotificationService = new IpxNotificationServiceMock();
        service = {
            getDebtorCopiesToDetails: jest.fn().mockReturnValue(of({ errors: null, CopyToNameId: 1, CopyToName: 'ABC', ContactName: 'XYZ', ContactNameId: 2, Address: null, AddressId: null }))
        };
        cdr = new ChangeDetectorRefMock();
        fb = new FormBuilder();
        ipxNotificationService = new IpxNotificationServiceMock();
        modalService = new BsModalRefMock();
        ipxModalService = new ModalServiceMock();
        shortcutsService = new IpxShortcutsServiceMock();
        destroy$ = of({}).pipe(delay(1000));
        component = new MaintainDebtorCopiesToComponent(service as any, modalService as any, ipxNotificationService as any, fb, shortcutsService as any, destroy$, cdr as any);
        (component as any).sbsModalRef = {
            hide: jest.fn()
        } as any;
        component.dataItem = {
            CopyToNameId: 1,
            CopyToNameValue: 'Abc',
            ContactNameId: 1,
            ContactName: 'Attention1'
        };
        component.grid = {
            rowCancelHandler: jest.fn(),
            checkChanges: jest.fn(),
            isValid: jest.fn(),
            isDirty: jest.fn(),
            wrapper: {
                data: [
                    {
                        CopyToNameId: 1,
                        CopyToNameValue: 'Abc',
                        ContactNameId: 1,
                        ContactName: 'Attention1'
                    }
                ]
            }
        } as any;
        component.isAdding = true;
        component.formGroup = {
            markAsDirty: jest.fn(),
            reset: jest.fn(),
            value: {},
            valid: true,
            dirty: false,
            controls: {
                CopyToNameId: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: 1,
                    valueChanges: new Observable<any>(),
                    setValue: jest.fn()
                },
                CopyToName: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: 'abc',
                    valueChanges: new Observable<any>(),
                    setValue: jest.fn()
                },
                CopyToNameValue: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: { key: 1, displayName: 'abc' },
                    valueChanges: new Observable<any>(),
                    setValue: jest.fn()
                },
                ContactNameId: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: 2,
                    valueChanges: new Observable<any>(),
                    setValue: jest.fn()
                },
                ContactName: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: 'Xyz',
                    valueChanges: new Observable<any>(),
                    setValue: jest.fn()
                },
                AddressChangeReasonId: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: 1,
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
            expect(component.disableFields).toBe(false);

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

    describe('onCopyToNameChange', () => {
        it('should call copyToName service when debtor is defined', () => {
            component.disableReason = true;
            const event = {
                key: 123
            };
            component.debtorNameId = 1;
            component.onCopyToNameChange(event);
            expect(service.getDebtorCopiesToDetails).toHaveBeenCalledWith(1, 123);
        });
        it('should throw duplicate error for add if copyToName exists', () => {
            component.disableReason = true;
            const event = {
                key: 1
            };
            component.debtorNameId = 1;
            component.dataItem.status = rowStatus.Adding;
            component.clearAndDisableFields = jest.fn();
            component.onCopyToNameChange(event);
            expect(component.formGroup.controls.CopyToNameValue.setErrors).toBeCalled();
            expect(service.getDebtorCopiesToDetails).not.toBeCalled();
        });
    });

    describe('apply', () => {
        it('should apply form if formGroup is valid', () => {
            component.validateReason = jest.fn().mockReturnValue(of(true));
            component.apply();
            expect((component as any).sbsModalRef.hide).toHaveBeenCalled();
        });
        it('should apply not close the modal if formGroup is invalid', () => {
            component.hasAddressChanged = true;
            component.formGroup = {
                valid: false,
                markAsDirty: jest.fn(),
                reset: jest.fn(),
                controls: {
                    AddressChangeReasonId: {
                        value: null,
                        markAsPristine: jest.fn(),
                        markAsTouched: jest.fn(),
                        setErrors: jest.fn(),
                        markAsDirty: jest.fn()
                    }
                },
                value: { AddressChangeReasonId: null }
            };
            component.apply();
            expect(component.formGroup.controls.AddressChangeReasonId.setErrors).toBeCalled();
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
});