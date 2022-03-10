import { FormBuilder } from '@angular/forms';
import { TimeRecordingServiceMock } from 'accounting/time-recording/time-recording.mock';
import { WarningCheckerServiceMock, WarningServiceMock } from 'accounting/warnings/warning.mock';
import { ChangeDetectorRefMock, IpxNotificationServiceMock, NotificationServiceMock } from 'mocks';
import { WindowParentMessagingServiceMock } from 'mocks/window-parent-messaging.service.mock';
import { BehaviorSubject, of } from 'rxjs';
import { AdjustWipComponent } from './adjust-wip.component';
import { TransactionTypeEnum } from './adjust-wip.model';

describe('AjustWipComponent', () => {
    let component: AdjustWipComponent;
    let cdr: ChangeDetectorRefMock;
    let notificationService: NotificationServiceMock;
    let ipxNotificationService: IpxNotificationServiceMock;
    let fb: FormBuilder;
    let timeService: any;
    let datepipe: any;
    let windowParentMessagingService: WindowParentMessagingServiceMock;
    let warningChecker: WarningCheckerServiceMock;
    let warningService: WarningServiceMock;
    const service = {
        getAdjustWipSupportData$: jest.fn().mockReturnValue(of({})),
        getItemForWipAdjustment$: jest.fn().mockReturnValue(of({})),
        submitAdjustWip: jest.fn().mockReturnValue(of({})),
        validateItemDate: jest.fn().mockReturnValue(of({}))
    };

    beforeEach(() => {
        notificationService = new NotificationServiceMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        timeService = new TimeRecordingServiceMock();
        fb = new FormBuilder();
        cdr = new ChangeDetectorRefMock();
        datepipe = { transform: jest.fn() };
        windowParentMessagingService = new WindowParentMessagingServiceMock();
        warningChecker = new WarningCheckerServiceMock();
        warningService = new WarningServiceMock();

        component = new AdjustWipComponent(service as any, cdr as any, fb as any, datepipe, notificationService as any, ipxNotificationService as any, windowParentMessagingService as any, timeService, warningChecker as any, warningService as any);
        component.formGroup = {
            markAsDirty: jest.fn(),
            reset: jest.fn(),
            value: {},
            valid: false,
            dirty: false,
            controls: {
                transactionDate: {
                    isValid: true,
                    markAsPristine: jest.fn(),
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    markAsDirty: jest.fn()
                },
                originalTransDate: {
                    isValid: true,
                    markAsPristine: jest.fn(),
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    markAsDirty: jest.fn()
                },
                localAdjustment: {
                    markAsPristine: jest.fn(),
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    markAsDirty: jest.fn(),
                    isValid: true,
                    value: 100
                },
                localValue: {
                    markAsPristine: jest.fn(),
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    markAsDirty: jest.fn(),
                    value: 10
                },
                foreignAdjustment: {
                    markAsPristine: jest.fn(),
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    markAsDirty: jest.fn()
                },
                foreignValue: {
                    markAsPristine: jest.fn(),
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    markAsDirty: jest.fn()
                },
                newCase: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    setErrors: jest.fn()
                },
                newStaff: {
                    markAsPristine: jest.fn(),
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    markAsDirty: jest.fn()
                },
                newDebtor: {
                    markAsPristine: jest.fn(),
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    markAsDirty: jest.fn()
                },
                newProduct: {
                    markAsPristine: jest.fn(),
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    markAsDirty: jest.fn()
                },
                newNarrative: {
                    markAsPristine: jest.fn(),
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    markAsDirty: jest.fn()
                },
                debitNoteText: {
                    markAsPristine: jest.fn(),
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    markAsDirty: jest.fn(),
                    value: '',
                    invalid: false
                }
            }
        };
        const elementMock = {
            clearValue: jest.fn(),
            el: {
                nativeElement: {
                    querySelector: jest.fn().mockReturnValue({
                        click: jest.fn()
                    })
                }
            }
        };
        component.localValueEl = elementMock;
        component.localValueEl = elementMock;
        component.localAdjustmentEl = elementMock;
        component.foreignValueEl = elementMock;
        component.foreignAdjustmentEl = elementMock;
        component.viewData = {
            reasonSupportCollection: null,
            localCurrency: null,
            productRecordedOnWIP: true,
            restrictOnWIP: true,
            splitWipMultiDebtor: true,
            wipWriteDownRestricted: true,
            writeDownLimit: 200,
            transferAssociatedDiscount: true
        };

        component.formData = {
            transactionType: TransactionTypeEnum.debit
        };
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('should initialize component', () => {
        jest.spyOn(component, 'createFormGroup');
        component.ngOnInit();
        expect(component.createFormGroup).toBeCalled();
        service.getAdjustWipSupportData$().subscribe(res => {
            expect(res).toBeDefined();
            expect(component.viewData).toBe(res);
            expect(service.getItemForWipAdjustment$).toBeCalled();
        });
    });

    it('should set formData', () => {
        const data: any = {
            requestedByStaff: null,
            wipCode: 'AB',
            reason: null,
            transactionDate: new Date(),
            originalTransDate: null,
            localValue: null,
            localAdjustment: null,
            currentLocalValue: 1000,
            foreignValue: null,
            foreignAdjustment: null,
            currentForeignValue: 1000,
            adjustWipItem: {
                originalWIPItem: {
                    localCurrency: 10,
                    foreignCurrency: 20
                }
            }
        };

        component.formGroup = {
            patchValue: jest.fn(),
            markAsPristine: jest.fn(),
            get: jest.fn()
        };

        component.formGroup = { patchValue: jest.fn(), markAsPristine: jest.fn() };
        component.setFormData(data);
        expect(component.formGroup.patchValue).toBeCalled();
        expect(component.localCurrency).toBe(data.adjustWipItem.originalWIPItem.localCurrency);
        expect(component.foreignCurrency).toBe(data.adjustWipItem.originalWIPItem.foreignCurrency);
    });

    it('validate write limit', () => {
        component.formData = {
            transactionType: TransactionTypeEnum.debit
        };
        component.formGroup = {
            controls: {
                localAdjustment: {
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    markAsDirty: jest.fn(),
                    value: 100
                }
            }
        };
        component.validateWriteLimit(1);
        expect(component.formGroup.controls.localAdjustment.markAsTouched).toBeCalled();
        expect(component.formGroup.controls.localAdjustment.setErrors).toBeCalledWith(null);
    });

    it('should set localadjustment and other values on transactiontype change', () => {
        component.formGroup = {
            patchValue: jest.fn(),
            controls: {
                localAdjustment: {
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    markAsDirty: jest.fn(),
                    value: 100
                },
                localValue: {
                    value: 120
                },
                currentLocalValue: {
                    value: 100
                },
                currentForeignValue: {
                    value: 1020
                },
                foreignAdjustment: {
                    markAsPristine: jest.fn(),
                    value: 5
                },
                newStaff: {
                    markAsPristine: jest.fn(),
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    markAsDirty: jest.fn()
                },
                newDebtor: {
                    markAsPristine: jest.fn(),
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    markAsDirty: jest.fn()
                },
                newProduct: {
                    markAsPristine: jest.fn(),
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    markAsDirty: jest.fn()
                },
                debitNoteText: {
                    markAsPristine: jest.fn(),
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    markAsDirty: jest.fn(),
                    value: '',
                    invalid: false
                }
            }
        };
        jest.spyOn(component, 'calculateByLocalAdjustedValue');
        component.onTransactionTypeChange(TransactionTypeEnum.case);
        expect(component.formGroup.patchValue).toBeCalledWith({ foreignAdjustment: null, foreignValue: null, localAdjustment: null, localValue: null, newDebtor: null, newProduct: null, newStaff: null });
    });
    it('validate calculateByLocalValue', () => {
        component.formGroup = {
            patchValue: jest.fn(),
            controls: {
                localAdjustment: {
                    markAsTouched: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: 123
                },
                localValue: {
                    value: 120
                },
                currentLocalValue: {
                    value: 100
                },
                currentForeignValue: {
                    value: 1020
                }
            }
        };
        jest.spyOn(component, 'validateWriteLimit');
        component.calculateByLocalValue();
        expect(component.formGroup.patchValue).toBeCalled();
        expect(component.validateWriteLimit).toBeCalled();
    });

    it('validate calculateByLocalAdjustedValue with localadjustment value', () => {
        component.formGroup = {
            patchValue: jest.fn(),
            controls: {
                localAdjustment: {
                    markAsTouched: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: 123
                },
                localValue: {
                    value: 120
                },
                currentLocalValue: {
                    value: 100
                },
                currentForeignValue: {
                    value: 1020
                }
            }
        };
        jest.spyOn(component, 'validateWriteLimit');
        component.calculateByLocalAdjustedValue();
        expect(component.formGroup.patchValue).toBeCalled();
        expect(component.validateWriteLimit).toBeCalled();
    });
    it('validate calculateByLocalAdjustedValue without localadjustment value', () => {
        component.formGroup = {
            patchValue: jest.fn(),
            controls: {
                localAdjustment: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn()
                },
                localValue: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn()
                },
                foreignAdjustment: {
                    markAsPristine: jest.fn()
                },
                foreignValue: {
                    markAsPristine: jest.fn()
                }
            }
        };
        jest.spyOn(component, 'validateWriteLimit');
        jest.spyOn(component, 'clearAll');
        component.calculateByLocalAdjustedValue();
        expect(component.validateWriteLimit).not.toBeCalled();
        expect(component.clearAll).toBeCalled();
    });

    it('should check calculateByForeignValue', () => {
        component.formGroup = {
            patchValue: jest.fn(),
            controls: {
                localAdjustment: {
                    markAsTouched: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    value: 123
                },
                localValue: {
                    value: 120
                },
                foreignAdjustment: {
                    markAsPristine: jest.fn()
                },
                foreignValue: {
                    value: 100
                },
                currentForeignValue: {
                    value: 1020
                },
                currentLocalValue: {
                    value: 1020
                }
            }
        };
        jest.spyOn(component, 'validateWriteLimit');
        component.calculateByForeignValue();
        expect(component.formGroup.patchValue).toBeCalledWith({ foreignAdjustment: +component.formGroup.controls.foreignValue.value - +component.formGroup.controls.currentForeignValue.value });
        expect(component.validateWriteLimit).toBeCalledWith(component.formGroup.controls.localAdjustment.value);
    });

    it('should check calculateByForeignAdjustedValue', () => {
        component.formGroup = {
            patchValue: jest.fn(),
            controls: {
                localAdjustment: {
                    markAsTouched: jest.fn(),
                    markAsDirty: jest.fn(),
                    setErrors: jest.fn(),
                    markAsPristine: jest.fn(),
                    value: -12
                },
                localValue: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn()
                },
                currentForeignValue: {
                    value: 900
                },
                currentLocalValue: {
                    value: 1020
                },
                foreignAdjustment: {
                    markAsPristine: jest.fn(),
                    value: -20
                },
                foreignValue: {
                    markAsPristine: jest.fn(),
                    value: 1000
                }
            }
        };

        const foreignValue = +component.formGroup.controls.foreignAdjustment.value + +component.formGroup.controls.currentForeignValue.value;
        jest.spyOn(component, 'validateWriteLimit');
        component.calculateByForeignAdjustedValue();
        expect(component.formGroup.patchValue).toBeCalledWith({ foreignValue });
        expect(component.validateWriteLimit).toBeCalledWith(component.formGroup.controls.localAdjustment.value);
    });

    it('should return error when transDate is not valid', done => {
        const responseData = {
            HasError: true,
            ValidationErrorList: [{
                ErrorCode: 'AC124'
            }]
        };
        jest.spyOn(service, 'validateItemDate').mockReturnValue(of(responseData));
        component.validateItemDate(new Date());
        service.validateItemDate().subscribe(res => {
            expect(res).toBeDefined();
            expect(res.HasError).toBeTruthy();
            expect(res.ValidationErrorList).toBeDefined();
            done();
        });
    });

    it('should return notification when transDate is not valid and warning code is returned', done => {
        const responseData = {
            hasError: true,
            validationErrorList: [{
                warningCode: 'AC124'
            }]
        };
        ipxNotificationService.modalRef.content = {
            confirmed$: of('confirm'),
            cancelled$: of()
        };
        jest.spyOn(service, 'validateItemDate').mockReturnValue(of(responseData));
        component.validateItemDate(new Date());
        service.validateItemDate(new Date()).subscribe(res => {
            expect(res).toBeDefined();
            expect(res.hasError).toBeTruthy();
            expect(res.validationErrorList[0].warningCode).toBeDefined();
            expect(ipxNotificationService.openConfirmationModal).toHaveBeenCalled();
            done();
        });
    });

    it('should submit valid form details', done => {
        component.originalWipAdjustmentData = {
            adjustWipItem: {
                logDateTimeStamp: new Date()
            }
        };
        component.entityKey = -123124;
        component.transKey = 12;
        component.wipSeqKey = 1;
        const data: any = {
            requestedByStaff: { key: 1 },
            wipCode: 'AB',
            reason: null,
            transactionDate: new Date(),
            originalTransDate: null,
            localValue: 56,
            localAdjustment: null,
            currentLocalValue: 1000,
            foreignValue: null,
            foreignAdjustment: null,
            currentForeignValue: 1000,
            adjustWipItem: {
                originalWIPItem: {
                    localCurrency: 10,
                    foreignCurrency: 20
                }
            }
        };
        component.formGroup.valid = true;
        component.formGroup.value = data;
        component.formGroup.dirty = true;
        component.formGroup.patchValue = jest.fn();

        const newStartTime = new Date();
        timeService.toLocalDate = jest.fn().mockReturnValue(newStartTime);
        component.submit();
        service.submitAdjustWip().subscribe(res => {
            expect(res).toBeDefined();
            expect(res.ValidationErrors).not.toBeDefined();
            expect(notificationService.info).toBeCalled();
            done();
        });
    });

    it('should return alert when validation error return on submit', done => {
        component.originalWipAdjustmentData = {
            adjustWipItem: {
                logDateTimeStamp: new Date()
            }
        };
        component.entityKey = -123124;
        component.transKey = 12;
        component.wipSeqKey = 1;
        const data: any = {
            requestedByStaff: { key: 1 },
            wipCode: 'AB',
            reason: null,
            transactionDate: new Date(),
            originalTransDate: null,
            localValue: 56,
            localAdjustment: null,
            currentLocalValue: 1000,
            foreignValue: null,
            foreignAdjustment: null,
            currentForeignValue: 1000,
            adjustWipItem: {
                originalWIPItem: {
                    localCurrency: 10,
                    foreignCurrency: 20
                }
            }
        };
        component.formGroup.valid = true;
        component.formGroup.value = data;
        component.formGroup.dirty = true;
        component.formGroup.patchValue = jest.fn();

        const newStartTime = new Date();
        timeService.toLocalDate = jest.fn().mockReturnValue(newStartTime);
        const responseData = {
            validationErrors: [{
                message: 'error'
            }]
        };
        jest.spyOn(service, 'submitAdjustWip').mockReturnValue(of(responseData));
        component.submit();
        service.submitAdjustWip().subscribe(res => {
            expect(res).toBeDefined();
            expect(res.validationErrors).toBeDefined();
            done();
        });
        expect(notificationService.alert).toHaveBeenCalled();
    });

    it('should close form if form is not dirty', () => {
        component.formGroup.dirty = false;
        ipxNotificationService.openDiscardModal.mockReturnValue({ content: { confirmed$: new BehaviorSubject('') } });
        component.closeModal = jest.fn();
        component.close();
        expect(component.closeModal).toHaveBeenCalled();
    });

    it('should give confirmation dialog if form is dirty', () => {
        component.formGroup.dirty = true;
        ipxNotificationService.openDiscardModal.mockReturnValue({ content: { confirmed$: new BehaviorSubject('') } });
        component.closeModal = jest.fn();
        component.close();
        expect(ipxNotificationService.openDiscardModal).toHaveBeenCalled();
    });

    describe('validateWriteLimit', () => {
        beforeEach(() => {
            component.viewData.wipWriteDownRestricted = true;
            component.viewData.writeDownLimit = 2000;
        });

        it('should set the formData correctly', () => {
            component.validateWriteLimit(3000);
            expect(component.formData.transactionType).toEqual('debit');
        });
        it('should set the formData correctly', () => {
            component.validateWriteLimit(-3000);
            expect(component.formData.transactionType).toEqual('credit');
        });
    });

    describe('onCaseChanged and onDebtorChanged', () => {
        it('should call the warningChecker service', done => {
            warningChecker.performCaseWarningsCheckResult = of(true);
            const event = { key: 123 };
            component.onCaseChanged(event);
            warningChecker.performCaseWarningsCheck(event, new Date()).subscribe((result) => {
                expect(result).toBeTruthy();
                done();
            });
        });
        it('should call the warningChecker service', done => {
            warningChecker.performCaseWarningsCheckResult = of(true);
            const event = { key: 123 };
            component.onDebtorChanged(event);
            warningChecker.performCaseWarningsCheck(event, new Date()).subscribe((result) => {
                expect(result).toBeTruthy();
                done();
            });
        });
    });
});
