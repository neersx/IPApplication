import { FormBuilder } from '@angular/forms';
import { BsModalRefMock, NotificationServiceMock } from 'mocks';
import { of } from 'rxjs';
import { DesignElementsMaintenanceComponent } from './design-elements-maintenance.component';

describe('DesignElementsMaintenanceComponent', () => {
    let component: DesignElementsMaintenanceComponent;
    let modalRef: any;
    let notificationServiceMock: NotificationServiceMock;
    let formBuilder: FormBuilder;
    let service: {
        getDesignElements(caseKey: number): any;
        isAddAnotherChecked: any;
        getValidationErrors: any;
    };
    beforeEach(() => {
        service = {
            getDesignElements: jest.fn(),
            isAddAnotherChecked: { getValue: jest.fn().mockReturnValue(true), next: jest.fn() },
            getValidationErrors: jest.fn().mockReturnValue(of([]))
        };

        notificationServiceMock = new NotificationServiceMock();
        formBuilder = new FormBuilder();
        modalRef = new BsModalRefMock();
        component = new DesignElementsMaintenanceComponent(service as any, notificationServiceMock as any, modalRef, formBuilder as any);
        component.formGroup = {
            value: { renew: true },
            dirty: false,
            controls: {
                stopRenewDate: { setValue: jest.fn().mockReturnValue('') }
            }
        };
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
                        firmElementCaseRef: '123',
                        clientElementCaseRef: '123',
                        elementOfficialNo: '123',
                        registrationNo: '123',
                        noOfViews: 1,
                        elementDescription: '567',
                        renew: true,
                        sequence: 0,
                        status: null,
                        rowKey: '1'
                    }, {
                        firmElementCaseRef: '1234',
                        clientElementCaseRef: '123',
                        elementOfficialNo: '123',
                        registrationNo: '123',
                        noOfViews: 1,
                        elementDescription: '567',
                        renew: true,
                        sequence: 1,
                        status: null,
                        rowKey: '2'
                    }
                ]
            },
            rowEditFormGroups: [
                {
                    firmElementCaseRef: '123456',
                    clientElementCaseRef: '12345',
                    elementOfficialNo: '123',
                    registrationNo: '123',
                    noOfViews: 1,
                    elementDescription: '567',
                    renew: true,
                    sequence: 1,
                    status: 'E',
                    rowKey: '2'
                }
            ]
        } as any;
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    describe('ngOnInit', () => {
        it('set stop renew date disabled on load', () => {
            component.dataItem.renew = true;
            component.ngOnInit();
            expect(component.isDateDisabled).toBe(true);
        });
        it('set stop renew date editable on load', () => {
            component.formGroup = {
                value: { renew: false }
            };
            component.ngOnInit();
            expect(component.isDateDisabled).toBe(false);
        });
        it('should check isAddAnother checkbox', () => {
            component.ngOnInit();
            expect(component.isAddAnotherChecked).toBe(true);
        });

        it('createFromGroup', () => {
            const dataItem = {
                firmElementCaseRef: '123',
                clientElementCaseRef: '123',
                elementOfficialNo: '123',
                registrationNo: '123',
                noOfViews: 1,
                elementDescription: '567',
                renew: true,
                sequence: 0,
                status: null,
                rowKey: '1'
            };
            component.dataItem = dataItem;
            jest.spyOn(component, 'createFormGroup');
            component.ngOnInit();
            expect(component.createFormGroup).toHaveBeenCalled();
        });
    });

    describe('apply modal changes', () => {
        it('should  submit if valid form', () => {
            component.formGroup = {
                dirty: true,
                status: 'VALID'
            };
            jest.spyOn(component, 'validate');
            component.apply();
            expect(component.validate).toBeCalled();
        });

        it('should  not submit if invalid form', () => {
            component.formGroup = {
                dirty: false,
                status: 'INVALID'
            };
            component.apply();
            expect(modalRef.hide).not.toBeCalled();
        });

        it('should  check validation when no errors', () => {
            component.formGroup = {
                dirty: false,
                status: 'INVALID',
                setErrors: jest.fn()
            };
            component.validate();
            service.getValidationErrors().subscribe(() => {
                expect(component.formGroup.setErrors).toBeCalledWith(null);
                expect((component as any).sbsModalRef.hide).toHaveBeenCalled();
            });
        });

        it('should  check validation when receive errors', () => {
            component.firmElem = {
                el: {
                    nativeElement: {
                        firstElementChild: { click: jest.fn() }
                    }
                }
            };
            component.formGroup = {
                dirty: false,
                status: 'INVALID',
                setErrors: jest.fn(),
                controls: {
                    firmElementCaseRef: {
                        setErrors: jest.fn()
                    },
                    images: {
                        setErrors: jest.fn()
                    }
                }
            };
            service.getValidationErrors = jest.fn().mockReturnValue(of([{ message: 'elementref', field: 'firmElementCaseRef' }, { message: 'images', field: 'images' }]));
            component.validate();
            service.getValidationErrors().subscribe(() => {
                expect(component.formGroup.controls.firmElementCaseRef.setErrors).toBeCalledWith({ duplicateDesignElement: 'duplicate' });
                expect(component.formGroup.controls.images.setErrors).toBeCalledWith({ duplicateElementImage: 'duplicate' });
            });

        });
    });
    describe('cancel', () => {
        it('cancel form changes', () => {
            component.formGroup = {
                dirty: false,
                status: 'VALID',
                reset: jest.fn()
            };
            component.cancel();
            expect(component.formGroup.reset).toBeCalled();
            expect(modalRef.hide).toBeCalled();
        });
    });
});