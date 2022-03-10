import { fakeAsync, tick } from '@angular/core/testing';
import { FormBuilder } from '@angular/forms';
import { BsModalRefMock, ChangeDetectorRefMock, IpxNotificationServiceMock } from 'mocks';
import { Observable, of } from 'rxjs';
import { MaintainBilledAmountComponent, TransactionType } from './maintain-billed-amount.component';

describe('MaintainBilledAmountComponent', () => {
    let component: MaintainBilledAmountComponent;
    let modalRef: BsModalRefMock;
    let fb: FormBuilder;
    let cdr: ChangeDetectorRefMock;
    let ipxNotificationService: IpxNotificationServiceMock;
    beforeEach(() => {
        ipxNotificationService = new IpxNotificationServiceMock();
        modalRef = new BsModalRefMock();
        fb = new FormBuilder();
        cdr = new ChangeDetectorRefMock();
        component = new MaintainBilledAmountComponent(modalRef as any, fb as any, cdr as any, ipxNotificationService as any);
        (component as any).sbsModalRef = {
            hide: jest.fn()
        } as any;
        component.dataItem = {
            UniqueReferenceId: 1,
            CaseId: 100,
            Balance: 100,
            ForeignBalance: 150,
            IsRenewal: false,
            TransactionType: TransactionType.writeUp,
            ForeignDecimalPlaces: 2
        };
        component.formGroup = {
            markAsDirty: jest.fn(),
            reset: jest.fn(),
            setErrors: jest.fn(),
            value: {
                LocalBilled: 120,
                Balance: 100,
                ForeignBalance: 150,
                ForeignBilled: 200
            },
            valid: false,
            dirty: false,
            controls: {
                LocalBilled: {
                    markAsTouched: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: 120,
                    valueChanges: new Observable<any>(),
                    setValue: jest.fn()
                },
                ForeignBilled: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: 200,
                    valueChanges: new Observable<any>(),
                    setValue: jest.fn()
                },
                Balance: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: 100,
                    valueChanges: new Observable<any>(),
                    setValue: jest.fn()
                },
                ForeignBalance: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: 150,
                    valueChanges: new Observable<any>(),
                    setValue: jest.fn()
                },
                LocalVariation: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: null,
                    valueChanges: new Observable<any>(),
                    setValue: jest.fn()
                },
                ForeignVariation: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: null,
                    valueChanges: new Observable<any>(),
                    setValue: jest.fn()
                },
                ReasonCode: {
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
        });
        it('initialize writeup value', () => {
            jest.spyOn(component, 'createFormGroup');
            component.ngOnInit();
            expect(component.showWriteUp).toBe(true);
            expect(component.formData.transactionType).toBe(component.dataItem.TransactionType);
            expect(cdr.markForCheck).toHaveBeenCalled();
        });
    });
    it('should set variation fields', () => {
        component.setVariation();
        expect(component.formGroup.controls.LocalVariation.setValue).toHaveBeenCalledWith(20);
        expect(component.formGroup.controls.ForeignVariation.setValue).toHaveBeenCalledWith(50);
    });
    describe('validate writeDown', () => {
        beforeEach(() => {
            component.localBilled = {
                showError$: {
                    next: jest.fn()
                }
            };
        });
        it('should return false if ShouldPreventWriteDown is true', () => {
            component.dataItem.ShouldPreventWriteDown = true;
            const isValid = component.validateWriteDown();
            expect(isValid).toBe(false);
            expect(component.formGroup.controls.LocalBilled.setErrors).toHaveBeenCalledWith({ 'billing.validations.preventWriteDown': true });
            expect(component.localBilled.showError$.next).toHaveBeenCalledWith(true);
        });
        it('should return true if site control WipWriteDownRestricted is false', () => {
            component.isWipWriteDownRestricted = false;
            const isValid = component.validateWriteDown();
            expect(isValid).toBe(true);
            expect(component.formGroup.controls.LocalBilled.setErrors).toHaveBeenCalledWith(null);
            expect(component.localBilled.showError$.next).toHaveBeenCalledWith(false);
        });
        it('should return error for 0 amount if minimum wip amount not specified', () => {
            component.isWipWriteDownRestricted = true;
            const isValid = component.validateWriteDown();
            expect(isValid).toBe(false);
            expect(component.formGroup.controls.LocalBilled.setErrors).toHaveBeenCalledWith({ 'billing.validations.writeDownLimitNotProvided': true });
            expect(component.localBilled.showError$.next).toHaveBeenCalledWith(true);
        });
        it('should return error if minimum wip amount is greater than billed amount', () => {
            component.isWipWriteDownRestricted = true;
            component.writeDownLimit = 30;
            component.formGroup.controls.LocalVariation.value = -50;
            const isValid = component.validateWriteDown();
            expect(isValid).toBe(false);
            expect(component.formGroup.controls.LocalBilled.setErrors).toHaveBeenCalledWith({ 'billing.validations.writeDownLimit': true });
        });
    });

    describe('apply', () => {
        it('should apply form if formGroup is valid', () => {
            component.formGroup.dirty = true;
            component.apply();
            expect(component.formGroup.setErrors).toHaveBeenCalledWith(null);
            expect((component as any).sbsModalRef.hide).toHaveBeenCalled();
        });
        it('should apply not close the modal if formGroup is invalid', () => {
            component.formGroup.isValid = false;
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

        it('close Modal form with correct data', fakeAsync(() => {
            component.formGroup.dirty = true;
            jest.spyOn(component, 'resetForm');
            const model = { content: { confirmed$: of(), cancelled$: of() } };
            ipxNotificationService.openDiscardModal.mockReturnValue(model);
            component.cancel();
            expect(ipxNotificationService.openDiscardModal).toHaveBeenCalled();
            tick(10);
            model.content.confirmed$.subscribe(() => {
                expect(component.resetForm).toHaveBeenCalled();
            });
        }));
        it('should reset form', () => {
            component.onClose$.next = jest.fn();
            component.resetForm(false);
            expect(component.formGroup.reset).toHaveBeenCalled();
            expect(component.onClose$.next).toHaveBeenCalledWith({ success: false, formGroup: component.formGroup });
            expect((component as any).sbsModalRef.hide).toHaveBeenCalled();
        });
    });
});