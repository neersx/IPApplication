import { FormBuilder } from '@angular/forms';
import { WarningCheckerServiceMock } from 'accounting/warnings/warning.mock';
import { BsModalRefMock, ChangeDetectorRefMock, IpxNotificationServiceMock } from 'mocks';
import { Observable, of } from 'rxjs';
import { DisbursementDissectionWipComponent } from './disbursement-dissection-wip.component';

describe('DisbursementDissectionWipComponent', () => {
    let component: DisbursementDissectionWipComponent;
    let cdr: ChangeDetectorRefMock;
    let ipxNotificationService: IpxNotificationServiceMock;
    let fb: FormBuilder;
    let warningChecker: WarningCheckerServiceMock;
    let modalService: BsModalRefMock;
    let service: {
        isAddAnotherChecked: any;
        validateItemDate: any;
    };
    beforeEach(() => {
        service = {
            isAddAnotherChecked: { getValue: jest.fn().mockReturnValue(true), next: jest.fn() },
            validateItemDate: jest.fn().mockReturnValue(of([]))
        };

        fb = new FormBuilder();
        warningChecker = new WarningCheckerServiceMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        cdr = new ChangeDetectorRefMock();
        modalService = new BsModalRefMock();
        component = new DisbursementDissectionWipComponent(service as any, ipxNotificationService as any, modalService as any, fb, warningChecker as any, cdr as any);
        component.form = {
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
                        amount: 500,
                        splitPercent: 50,
                        localValue: 500,
                        foreignValue: null,
                        balance: 500,
                        case: {},
                        name: {},
                        staff: {},
                        id: 0,
                        status: 'A'
                    }, {
                        amount: 100,
                        splitPercent: 10,
                        localValue: 100,
                        foreignValue: null,
                        balance: 100,
                        case: {},
                        name: {},
                        staff: {},
                        id: 1,
                        status: 'A'
                    }
                ]
            }
        } as any;

        const elementMock = {
            clearValue: jest.fn(),
            showError$: { next: jest.fn() },
            el: {
                nativeElement: {
                    querySelector: jest.fn().mockReturnValue({
                        click: jest.fn()
                    })
                }
            }
        };
        component.caseEl = elementMock;
        component.nameEl = elementMock;
        component.staffEl = elementMock;

        component.form = {
            markAsDirty: jest.fn(),
            reset: jest.fn(),
            value: {},
            valid: false,
            dirty: false,
            controls: {
                case: {
                    markAsTouched: jest.fn(),
                    setErrors: jest.fn(),
                    value: { key: 'Acb', code: 'Acb', value: 'Abc Value' }
                },
                amount: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    setErrors: jest.fn(),
                    value: 100
                },
                disbursement: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    setErrors: jest.fn(),
                    value: {}
                },
                localCurrency: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    setErrors: jest.fn(),
                    value: 10
                },
                name: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    setErrors: jest.fn()
                },
                foreignAmount: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    setErrors: jest.fn()
                },
                staff: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    setErrors: jest.fn()
                },
                discount: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    setErrors: jest.fn()
                },
                foreignMargin: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    setErrors: jest.fn()
                },
                currency: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    setErrors: jest.fn()
                },
                narrative: {
                    markAsTouched: jest.fn(),
                    markAsPristine: jest.fn(),
                    setErrors: jest.fn()
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

        component.dataItem = {
            status: 'A',
            id: 2
        };
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    describe('initialize component', () => {
        it('set call Createformgroup', () => {
            jest.spyOn(component, 'createFormGroup');
            component.ngOnInit();
            expect(component.createFormGroup).toHaveBeenCalledWith(component.dataItem);
        });
        it('set addanother status with dataItem', () => {
            jest.spyOn(component, 'createFormGroup');
            component.ngOnInit();
            expect(component.isAddAnotherChecked).toBe(false);
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

        it('should intialize afterview inti', () => {
            component.form = {
                markAsDirty: jest.fn(),
                patchValue: jest.fn(),
                markAsPristine: jest.fn(),
                controls: {
                    amount: {
                        markAsTouched: jest.fn(),
                        markAsPristine: jest.fn(),
                        setErrors: jest.fn(),
                        setValue: jest.fn(),
                        value: 100,
                        valueChanges: new Observable<any>()
                    },
                    foreignAmount: {
                        markAsTouched: jest.fn(),
                        markAsDirty: jest.fn(),
                        setErrors: jest.fn(),
                        setValue: jest.fn(),
                        value: 100,
                        valueChanges: new Observable<any>()
                    }
                }
            };
            component.isAddAnother = false;
            jest.spyOn(component, 'createFormGroup');
            component.ngAfterViewInit();
            expect(component.form.markAsPristine).toHaveBeenCalled();
        });
    });

    describe('On input control Field Changes', () => {
        it('should call calculatewip on change of currency', () => {
            component.form = {
                markAsDirty: jest.fn(),
                patchValue: jest.fn(),
                markAsPristine: jest.fn(),
                controls: {
                    amount: {
                        setErrors: jest.fn(),
                        setValue: jest.fn()
                    },
                    foreignAmount: {
                        setValue: jest.fn(),
                        setErrors: jest.fn()
                    }
                }
            };
            jest.spyOn(component, 'getWipCost');
            jest.spyOn(component, 'clearAllCost');
            component.calculateWip(null, true);
            expect(component.clearAllCost).toHaveBeenCalled();
            expect(component.form.markAsPristine).toHaveBeenCalled();
        });

        it('should call the warningChecker oncaseChange', done => {
            warningChecker.performCaseWarningsCheckResult = of(true);
            const event = { key: 123 };
            component.onCaseChange(event);
            warningChecker.performCaseWarningsCheck(event, new Date()).subscribe((result) => {
                expect(result).toBeTruthy();
                done();
            });
        });

        it('should call the warningChecker onNameChange', done => {
            warningChecker.performCaseWarningsCheckResult = of(true);
            const event = { key: 123 };
            component.onNameChange(event);
            warningChecker.performCaseWarningsCheck(event, new Date()).subscribe((result) => {
                expect(result).toBeTruthy();
                done();
            });
        });

        it('should call the onStaffChange', () => {
            component.form = {
                controls: {
                    amount: {
                        setValue: jest.fn()
                    },
                    staff: {
                        setValue: jest.fn(),
                        markAsTouched: jest.fn(),
                        markAsDirty: jest.fn(),
                        setErrors: jest.fn()
                    }
                }
            };
            jest.spyOn(component, 'validateStaff');
            const event = { key: 123 };
            component.onStaffChange(null);
            expect(component.validateStaff).toHaveBeenCalled();
        });

        it('should call the onNarrativeChange', () => {
            component.form = {
                controls: {
                    debitNoteText: {
                        setValue: jest.fn()
                    }
                }
            };
            jest.spyOn(component, 'validateStaff');
            const event = { text: 'Narrative' };
            component.onNarrativeChange(event);
            expect(component.form.controls.debitNoteText.setValue).toHaveBeenCalledWith(event.text);
        });

        it('should call the onCheckChanged', () => {
            component.form = {
                controls: {
                    debitNoteText: {
                        setValue: jest.fn()
                    }
                }
            };
            component.onCheckChanged();
            expect(service.isAddAnotherChecked.next).toHaveBeenCalledWith(false);
        });

        it('should call the clearCaseDefault', () => {
            component.form = {
                controls: {
                    name: {
                        setValue: jest.fn()
                    },
                    staff: {
                        setValue: jest.fn()
                    },
                    profitCentre: {
                        setValue: jest.fn()
                    }
                }
            };
            component.clearCaseDefaultedFields();
            expect(component.form.controls.name.setValue).toHaveBeenCalledWith(null);
            expect(component.form.controls.staff.setValue).toHaveBeenCalledWith(null);
        });
    });

    describe('apply modal changes', () => {
        it('should  not submit if invalid form', () => {
            component.form = {
                dirty: false,
                status: 'INVALID',
                setErrors: jest.fn()
            };
            component.apply();
            expect(component.form.setErrors).not.toHaveBeenCalled();
        });

        it('should  check validation when no errors', () => {
            component.form = {
                dirty: false,
                invalid: false,
                status: 'INVALID',
                setErrors: jest.fn()
            };
            jest.spyOn(component, 'caseNameMandatoryValidation').mockReturnValue(true);
            jest.spyOn(component, 'validateStaff').mockReturnValue(true);
            jest.spyOn(component, 'checkDisbursementValidation').mockReturnValue(true);
            jest.spyOn(component, 'checkAmountValidation').mockReturnValue(true);
            component.apply();
            expect(component.form.setErrors).toHaveBeenCalled();
        });

        it('should  check validation when no errors', () => {
            component.form = {
                dirty: false,
                invalid: false,
                status: 'INVALID',
                setErrors: jest.fn(),
                controls: {
                    staff: {
                        setValue: jest.fn(),
                        markAsTouched: jest.fn(),
                        markAsDirty: jest.fn(),
                        setErrors: jest.fn(),
                        value: null
                    }
                }
            };
            component.validateStaff();
            expect(component.form.controls.staff.setErrors).toHaveBeenCalledWith({ required: true });
            expect(component.form.controls.staff.markAsTouched).toHaveBeenCalled();
            expect(component.form.controls.staff.markAsDirty).toHaveBeenCalled();
        });
    });
    describe('cancel', () => {
        const notificationRef = {
            content: {
                confirmed$: of({}),
                cancelled$: of({})
            }
        };
        it('cancel form changes if form not dirty', () => {
            component.form = {
                dirty: false,
                status: 'VALID',
                reset: jest.fn()
            };
            const modalServiceSpy = ipxNotificationService.openDiscardModal.mockReturnValue(notificationRef);
            jest.spyOn(component, 'resetForm');
            component.cancel();
            expect(component.resetForm).toHaveBeenCalled();
        });
    });
});