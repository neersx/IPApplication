import { FormBuilder } from '@angular/forms';
import { TimeRecordingServiceMock } from 'accounting/time-recording/time-recording.mock';
import { ChangeDetectorRefMock, IpxNotificationServiceMock, NotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { Observable, of } from 'rxjs';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { DisbursementDissectionWipComponent } from './disbursement-dissection-wip/disbursement-dissection-wip.component';
import { DisbursementDissectionComponent } from './disbursement-dissection.component';

describe('DisbursementDissectionComponent', () => {
    let component: DisbursementDissectionComponent;
    let cdr: ChangeDetectorRefMock;
    let ipxNotificationService: IpxNotificationServiceMock;
    let notificationService: NotificationServiceMock;
    let fb: FormBuilder;
    let modalService: ModalServiceMock;
    let timeService: TimeRecordingServiceMock;
    let service: {
        getSupportData$: any;
        isAddAnotherChecked: any;
        validateItemDate: any;
        submitDisbursement: any;
        allDefaultWips: Array<any>;
    };
    const datePipe = {
        transform: jest.fn().mockReturnValue(new Date())
    };

    beforeEach(() => {
        service = {
            getSupportData$: jest.fn().mockReturnValue(of({ splitWipMultiDebtor: true, wipWriteDownRestricted: true })),
            isAddAnotherChecked: { getValue: jest.fn().mockReturnValue(true), next: jest.fn() },
            validateItemDate: jest.fn().mockReturnValue(of([])),
            submitDisbursement: jest.fn().mockReturnValue(of([])),
            allDefaultWips: [{ staffKey: 3, staffCode: 3, staffName: 'existingStaff' }]
        };

        timeService = new TimeRecordingServiceMock();
        fb = new FormBuilder();
        ipxNotificationService = new IpxNotificationServiceMock();
        cdr = new ChangeDetectorRefMock();
        modalService = new ModalServiceMock();
        notificationService = new NotificationServiceMock();
        component = new DisbursementDissectionComponent(service as any, fb, datePipe as any, timeService as any, cdr as any, ipxNotificationService as any, modalService as any, notificationService as any);
        component.grid = {
            refresh: jest.fn(),
            clear: jest.fn(),
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
                        case: { key: 1, code: 1, name: '1234' },
                        name: { key: 1, code: 1, displayName: 'ABC' },
                        staff: { key: 2, code: 2, displayName: 'Staff' },
                        debitNoteText: 'Notes',
                        disbursement: { key: 1 },
                        narrative: { key: 1 },
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

        component.totalAmountEl = elementMock;

        component.formGroup = {
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
                    value: 'AUD'
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
                    setErrors: jest.fn(),
                    value: { code: 'AUD' }
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
                },
                transactionDate: {
                    value: new Date()
                },
                entity: {
                    value: 'ABC'
                }
            }
        };
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    describe('initialize component', () => {
        it('set call Createformgroup', () => {
            component.formGroup = {
                markAsDirty: jest.fn(),
                patchValue: jest.fn(),
                markAsPristine: jest.fn(),
                controls: {
                    entity: {
                        markAsTouched: jest.fn(),
                        markAsPristine: jest.fn(),
                        setErrors: jest.fn(),
                        setValue: jest.fn(),
                        value: 100,
                        valueChanges: new Observable<any>()
                    }
                }
            };
            jest.spyOn(component, 'createFormGroup');
            component.ngOnInit();
            service.getSupportData$().subscribe(res => {
                expect(res).toBeDefined();
                expect(component.viewData).toBe(res);
            });
            expect(component.createFormGroup).toBeCalled();
        });

        it('should call createFromGroup', () => {
            jest.spyOn(component, 'createFormGroup');
            component.ngOnInit();
            expect(component.createFormGroup).toHaveBeenCalled();
        });

        it('should create new formgroup', () => {
            component.formGroup = {
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
                    }
                }
            };
            component.createFormGroup();
            expect(component.formGroup).toBeDefined();
        });
    });

    describe('On input control Field Validations', () => {
        it('should check isPageDirty', () => {
            component.formGroup = {
                hasPendingChanges: true
            };
            const result = component.isPageDirty();
            expect(result).toBeTruthy();
        });

        it('should return error when transaction Date is not valid', done => {
            const responseData = {
                HasError: true,
                ValidationErrorList: [{
                    ErrorCode: 'AC124'
                }]
            };

            component.formGroup = {
                markAsDirty: jest.fn(),
                patchValue: jest.fn(),
                markAsPristine: jest.fn(),
                controls: {
                    transactionDate: {
                        markAsTouched: jest.fn(),
                        markAsPristine: jest.fn(),
                        setErrors: jest.fn(),
                        setValue: jest.fn(),
                        value: 100,
                        valueChanges: new Observable<any>()
                    }
                }
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

        it('should call the totalAmountChange', () => {
            component.formGroup = {
                controls: {
                    currency: {
                        setValue: jest.fn(),
                        value: 200
                    },
                    totalAmount: {
                        setValue: jest.fn(),
                        markAsTouched: jest.fn(),
                        markAsDirty: jest.fn(),
                        value: 100
                    }
                }
            };
            jest.spyOn(component, 'updateChangeStatus');
            component.totalAmountChange(null);
            expect(component.updateChangeStatus).toHaveBeenCalled();
        });

        it('should call the currencyOnChange', () => {
            component.formGroup = {
                controls: {
                    debitNoteText: {
                        setValue: jest.fn()
                    }
                }
            };
            ipxNotificationService.modalRef.content = {
                confirmed$: of('confirm'),
                cancelled$: of()
            };

            const event = { code: 'AB' };
            component.currencyOnChange(event);
            expect(component.oldCurrency).toBe(event);
        });

        it('should call the onRowAddedOrEdited', () => {
            component.viewData = {
                localCurrency: 'AUD'
            };
            component.formGroup = {
                controls: {
                    currency: {
                        value: { code: 'AUD' }
                    },
                    entity: {
                        value: 'A1c'
                    },
                    transactionDate: {
                        value: new Date()
                    }
                }
            };

            const data = {
                dataItem: {
                    status: 'A',
                    disbursement: null
                }
            };

            jest.spyOn(component, 'onCloseModal');
            component.onRowAddedOrEdited(data);
            expect(component.onCloseModal).toHaveBeenCalled();
        });
        describe('staff manual entry values', () => {
            beforeEach(() => {
                component.viewData = {
                    localCurrency: 'AUD',
                    staffManualEntryforWIP: 1
                };
                component.isAddedAnother = true;
                component.lastAddedItemId = 1;
            });
            it('should send prefilled values on add another with staff null', () => {
                const data = {
                    dataItem: {
                        status: 'A',
                        disbursement: null
                    }
                };
                component.viewData.staffManualEntryforWIP = 1;
                jest.spyOn(component, 'onCloseModal');
                component.onRowAddedOrEdited(data);
                expect(modalService.openModal).toBeCalledWith(DisbursementDissectionWipComponent, {
                    animated: false, backdrop: 'static', class: 'modal-xl',
                    initialState: { currency: 'AUD', dataItem: { case: { code: 1, key: 1, name: '1234' }, debitNoteText: 'Notes', disbursement: { key: 1 }, name: { code: 1, displayName: 'ABC', key: 1 }, narrative: { key: 1 }, staff: null, status: 'A' }, entityKey: 'ABC', grid: component.grid, isAdding: true, localCurrency: 'AUD', rowIndex: undefined, transactionDate: component.formGroup.controls.transactionDate.value }
                });
                expect(component.onCloseModal).toHaveBeenCalled();
            });
            it('should send prefilled values on add another with staff as existing', () => {
                const data = {
                    dataItem: {
                        status: 'A',
                        disbursement: null
                    }
                };
                component.viewData.staffManualEntryforWIP = 2;
                jest.spyOn(component, 'onCloseModal');
                component.onRowAddedOrEdited(data);
                expect(modalService.openModal).toBeCalledWith(DisbursementDissectionWipComponent, {
                    animated: false, backdrop: 'static', class: 'modal-xl',
                    initialState: { currency: 'AUD', dataItem: { case: { code: 1, key: 1, name: '1234' }, debitNoteText: 'Notes', disbursement: { key: 1 }, name: { code: 1, displayName: 'ABC', key: 1 }, narrative: { key: 1 }, staff: { code: 2, displayName: 'Staff', key: 2 }, status: 'A' }, entityKey: 'ABC', grid: component.grid, isAdding: true, localCurrency: 'AUD', rowIndex: undefined, transactionDate: component.formGroup.controls.transactionDate.value }
                });
                expect(component.onCloseModal).toHaveBeenCalled();
            });
            it('should send prefilled values on add another with staff as existing with value from first row', () => {
                const data = {
                    dataItem: {
                        status: 'A',
                        disbursement: null
                    }
                };
                component.viewData.staffManualEntryforWIP = 0;
                jest.spyOn(component, 'onCloseModal');
                component.onRowAddedOrEdited(data);
                expect(modalService.openModal).toBeCalledWith(DisbursementDissectionWipComponent, {
                    animated: false, backdrop: 'static', class: 'modal-xl',
                    initialState: { currency: 'AUD', dataItem: { case: { code: 1, key: 1, name: '1234' }, debitNoteText: 'Notes', disbursement: { key: 1 }, name: { code: 1, displayName: 'ABC', key: 1 }, narrative: { key: 1 }, staff: { code: 3, displayName: 'existingStaff', key: 3 }, status: 'A' }, entityKey: 'ABC', grid: component.grid, isAdding: true, localCurrency: 'AUD', rowIndex: undefined, transactionDate: component.formGroup.controls.transactionDate.value }
                });
                expect(component.onCloseModal).toHaveBeenCalled();
            });
        });
        it('should call the onCloseModal', () => {
            component.formGroup = {
                controls: {
                    currency: {
                        value: { code: 'AUD' }
                    },
                    totalAmount: {
                        value: 120
                    },
                    transactionDate: {
                        value: new Date()
                    }
                }
            };

            component.gridOptions = { _selectPage: jest.fn(), maintainFormGroup$: { next: jest.fn() } } as any;
            jest.spyOn(component, 'updateChangeStatus');
            service.isAddAnotherChecked = {
                getValue: jest.fn().mockReturnValue(false)
            };

            const data = {
                dataItem: {
                    status: 'A',
                    disbursement: null
                }
            };
            const event = {
                success: true
            };
            component.onCloseModal(event, data);
            expect(component.updateChangeStatus).toHaveBeenCalled();
            expect(service.isAddAnotherChecked.getValue).toHaveBeenCalled();
        });
    });

    describe('individual methods and features', () => {
        it('should call removeAddedEmptyRow', () => {
            component.formGroup = {
                dirty: false,
                status: 'INVALID',
                setErrors: jest.fn()
            };
            const data = {
                dataItem: {
                    status: rowStatus.Adding,
                    disbursement: null
                }
            };
            component.grid.wrapper.data = [{
                status: rowStatus.Adding,
                disbursement: { value: 'abc' }
            },
            {
                status: rowStatus.Adding,
                disbursement: {}
            }];
            const res: any = component.grid.wrapper.data;
            component.removeAddedEmptyRow(data);
            expect(component.grid.wrapper.data).toEqual(res.filter(x => x && x.amount));
        });

        it('should call updateChangeStatus', () => {
            component.formGroup = {
                dirty: false,
                invalid: false,
                status: 'INVALID',
                setErrors: jest.fn(),
                controls: {
                    currency: {
                        value: { code: 'AUD' }
                    },
                    totalAmount: {
                        value: 120
                    },
                    transactionDate: {
                        value: new Date()
                    }
                }
            };

            component.updateChangeStatus();
            expect(component.grid.checkChanges).toHaveBeenCalled();
        });

        it('should call getSaveButtonStatus', () => {
            component.formGroup = {
                valid: true,
                reset: jest.fn(),
                patchValue: jest.fn(),
                markAsPristine: jest.fn(),
                controls: {
                    totalAmount: {
                        markAsPristine: jest.fn()
                    },
                    currency: { code: 'AUD' }
                }
            };
            component.grid.wrapper.data = [{
                status: rowStatus.Adding,
                disbursement: { value: 'abc' },
                foreignAmount: 100
            },
            {
                status: rowStatus.Adding,
                disbursement: {},
                foreignAmount: 100
            }];

            const result = component.getSaveButtonStatus();
            expect(result).toBeFalsy();
            expect(component.disableSave).toBeFalsy();
        });

        it('should call reset', () => {
            component.viewData = {
                localCurrency: 'AUD',
                entities: [{ isDefault: true, entityKey: 123, entityName: 'ABC' }]
            };
            component.formGroup = {
                reset: jest.fn(),
                patchValue: jest.fn(),
                markAsPristine: jest.fn(),
                controls: {
                    totalAmount: {
                        markAsPristine: jest.fn()
                    },
                    currency: { code: 'AUD' },
                    entity: {
                        markAsPristine: jest.fn()
                    }
                }
            };
            component.grid.wrapper.data = [{
                status: rowStatus.Adding,
                disbursement: { value: 'abc' },
                foreignAmount: 100
            },
            {
                status: rowStatus.Adding,
                disbursement: {},
                foreignAmount: 100
            }];
            jest.spyOn(component, 'getSaveButtonStatus');
            jest.spyOn(component, 'setDefaultEntity');
            component.reset();
            expect(component.totalAmountEl.showError$.next).toHaveBeenCalledWith(false);
            expect(component.getSaveButtonStatus).toHaveBeenCalled();
            expect(component.setDefaultEntity).toHaveBeenCalled();

        });

        it('should call getTotalDissectionAmount', () => {
            component.formGroup = {
                value: {
                    currency: { code: 'AUD' }
                }
            };
            component.grid.wrapper.data = [{
                status: rowStatus.Adding,
                disbursement: { value: 'abc' },
                foreignAmount: 100
            },
            {
                status: rowStatus.Adding,
                disbursement: {},
                foreignAmount: 100
            }];

            const result = component.getTotalDissectionAmount();
            expect(result).toBe(200);
        });
    });

    describe('submit disbursement details', () => {
        it('should not call submit if form invalid', () => {
            component.formGroup = {
                valid: false,
                dirty: true,
                status: 'INVALID',
                setErrors: jest.fn()
            };

            jest.spyOn(component, 'getTotalDissectionAmount');
            const res: any = component.grid.wrapper.data;
            component.submit();
            expect(component.getTotalDissectionAmount).not.toHaveBeenCalled();
        });

        it('should show alert on amount mismatched', () => {
            component.formGroup = {
                dirty: false,
                valid: true
            };
            const value = component.unallocatedAmount.getValue();
            jest.spyOn(component, 'prepareDisbursementRequest');
            component.submit();
            expect(value).not.toBe(0);
            expect(notificationService.alert).toHaveBeenCalled();
            expect(component.prepareDisbursementRequest).not.toHaveBeenCalled();
        });

        it('should call save api', done => {
            component.formGroup = {
                dirty: false,
                valid: true,
                reset: jest.fn(),
                value: {
                    totalAmount: 500,
                    entity: 123,
                    associate: { key: 111, displayName: 'Associate Name' }
                }
            };
            const request = {
                dissectedDisbursements: [{ wipSeqNo: 1, transDate: new Date() }],
                entityKey: 123,
                associateKey: 45,
                associateName: 'Associate Name'
            };
            component.unallocatedAmount.next(0);
            const value = component.unallocatedAmount.getValue();
            jest.spyOn(component, 'getTotalDissectionAmount').mockReturnValue(component.formGroup.value.totalAmount);
            jest.spyOn(component, 'prepareDisbursementRequest').mockReturnValue(request);
            jest.spyOn(component, 'reset');
            component.submit();
            expect(value).toBe(0);
            expect(component.prepareDisbursementRequest).toHaveBeenCalled();
            service.submitDisbursement(request).subscribe(res => {
                expect(res).toBeDefined();
                expect(component.reset).toHaveBeenCalled();
                done();
            });
        });
    });
});