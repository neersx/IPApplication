import { async } from '@angular/core/testing';
import { FormBuilder, FormControl, FormGroup, Validators } from '@angular/forms';
import { RootScopeServiceMock } from 'ajs-upgraded-providers/mocks/rootscope.service.mock';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock, NotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { WindowParentMessagingServiceMock } from 'mocks/window-parent-messaging.service.mock';
import { of } from 'rxjs';
import { FormControlWarning } from 'shared/component/forms/form-control-warning';
import { any } from 'underscore';
// tslint:disable-next-line: no-require-imports
import _ = require('underscore');
import { CaseDetailServiceMock } from '../case-detail.service.mock';
import { ChecklistHostComponent } from './checklist-model';
import { ChecklistsComponent, ChecklistsComponentTopic } from './checklists.component';

describe('Checklists Component', () => {
    let component: (viewData ?: any) => ChecklistsComponent;
    let service: CaseDetailServiceMock;
    let localSettings: LocalSettingsMock;
    let cdr: ChangeDetectorRefMock;
    let rootService: RootScopeServiceMock;
    let parentMsg: WindowParentMessagingServiceMock;
    let notificationServiceMock: NotificationServiceMock;
    let modalService: ModalServiceMock;
    let warningService: any;
    localSettings = new LocalSettingsMock();

    const checklistData: any = {
        data: [{
                question: 'Question 1',
                questionId: '11',
                dateValue: null,
                yesDateOption: 0,
                noDateOption: 0,
                countValue: 1,
                periodTypeDescription: '',
                amountValue: 1.1,
                textValue: 'df',
                listSelection: '',
                staffName: '',
                isProcessed: 1
            },
            {
                question: 'Question 2',
                questionId: '12',
                dataValue: null,
                yesDateOption: 0,
                noDateOption: 0,
                countValue: 1,
                periodTypeDescription: '',
                amountValue: 1.1,
                textValue: 'df',
                listSelection: '',
                staffName: '',
                isProcessed: 1
            },
            {
                question: 'Question 3',
                questionId: '13',
                dataValue: null,
                yesDateOption: 0,
                noDateOption: 0,
                countValue: 1,
                periodTypeDescription: '',
                amountValue: 1.1,
                textValue: 'df',
                listSelection: '',
                staffName: '',
                isProcessed: 1
            }
        ]
    };

    beforeEach(() => {
        component = (viewData ?: any): ChecklistsComponent => {
            service = new CaseDetailServiceMock();
            cdr = new ChangeDetectorRefMock();
            rootService = new RootScopeServiceMock();
            modalService = new ModalServiceMock();
            warningService = {};
            parentMsg = new WindowParentMessagingServiceMock();
            const data = [1, 2, 3];
            service.getCaseChecklistTypes$.mockReturnValue(of ({
                selectedChecklistType: 1,
                checklistTypes: data,
                selectedChecklistCriteriaKey: null
            }));
            service.getCaseChecklistDataHybrid$.mockReturnValue(of (checklistData));
            service.getCaseChecklistData$.mockReturnValue(of (checklistData));
            notificationServiceMock = new NotificationServiceMock();
            rootService.isHosted = false;
            const c = new ChecklistsComponent(service as any, cdr as any, localSettings, parentMsg as any, rootService as any,
                new FormBuilder(), warningService, modalService as any, notificationServiceMock as any);
            c.topic = {
                params: {
                    viewData: viewData || {}
                }
            } as any;
            c.ngOnInit();
            c.gridOptions._search = jest.fn();
            c.dataBound = jest.fn().mockReturnValue(of(checklistData));

            return c;
        };
    });

    it('should create the component', () => {
        expect(component).toBeTruthy();
    });

    describe('checklists', () => {
        it('initialize', async (() => {
            const c = component();
            c.topic = new ChecklistsComponentTopic({
                viewData: {
                    caseId: 111
                }
            });
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({})
                }
            } as any;
            c.ngOnInit();
            expect(c.checklistTypes).not.toBe(null);
            expect(c.selectedChecklistTypeId).toBeDefined();
            expect(c.selectedCriteriaKey).toBeDefined();
            expect(c.hasValidChecklistTypes).toBeDefined();
            service.getCaseChecklistTypes$().subscribe(() => {
                expect(c.selectedChecklistTypeId).toBe(1);
                expect(c.selectedCriteriaKey).toBe(null);
                expect(c.gridOptions).toBeDefined();
                c.gridOptions._search = jest.fn();
            });
        }));

        it('change Checklist Type', () => {
            const c = component();
            c.checklistTypes = [{
                    checklistType: 1,
                    checklistTypeDescription: 'Initial',
                    checklistCriteriaKey: -1
                },
                {
                    checklistType: 2,
                    checklistTypeDescription: 'information',
                    checklistCriteriaKey: -2
                },
                {
                    checklistType: 3,
                    checklistTypeDescription: 'information 2',
                    checklistCriteriaKey: -3
                }
            ];
            c.ngOnInit();
            expect(c.changeChecklistType).toBeDefined();
            expect(c.selectedChecklistTypeId).toBe(1);
            c.changeChecklistType = jest.fn();
            c.selectedChecklistTypeId = 2;
            c.changeChecklistType();
            expect(c.changeChecklistType).toHaveBeenCalled();
        });

        it('disable for no valid checklists', async (() => {
            const c = component();
            service.getCaseChecklistTypes$.mockReturnValue(of ({
                selectedChecklistType: null,
                checklistTypes: null,
                selectedChecklistCriteriaKey: null
            }));
            c.ngOnInit();
            expect(c.hasValidChecklistTypes).toBeFalsy();
        }));

        it('should Change value as per cached value for remembering value', async (() => {
            const gridCacheddata: any = {
                data: [{
                        question: 'Question 1',
                        questionId: 11,
                        dateValue: null,
                        yesDateOption: 0,
                        noDateOption: 0,
                        countValue: 1,
                        periodTypeDescription: '',
                        amountValue: 20.2,
                        textValue: 'test cache',
                        listSelection: '',
                        staffName: '',
                        isProcessed: 1
                    }
                ]
            };
            const checklistDataResult: any = {
                data: [{
                        question: 'Question 1',
                        questionNo: 11,
                        dateValue: null,
                        countValue: 1,
                        amountValue: 1.1,
                        textValue: 'aaaa',
                        listSelectionKey: '',
                        staffName: '',
                        isProcessed: 1
                    },
                    {
                        question: 'Question 2',
                        questionNo: 12,
                        dataValue: null,
                        countValue: 1,
                        amountValue: 1.1,
                        textValue: 'df',
                        listSelectionKey: '',
                        staffName: '',
                        isProcessed: 1
                    }
                ]
            };
            const c = component();
            c.topic = new ChecklistsComponentTopic({
                viewData: {
                    caseId: 111,
                    hostId: ChecklistHostComponent.ChecklistWizardHost,
                    genericKey: 1
                }
            });
            c.grid = {
                rowEditFormGroups: {
                    ['11']: new FormGroup({})
                }
            } as any;
            c.gridOptions._search = jest.fn();
            c.cachedData = {
                checklistTypeId: 3,
                checklistCriteriaKey: 2,
                rows: gridCacheddata.data
            };
            c.gridCacheddata = gridCacheddata.data;
            rootService.isHosted = true;
            expect(c.setCachedData(checklistDataResult.data)[0].textValue).toEqual('test cache');
            expect(c.setCachedData(checklistDataResult.data)[0].amountValue).toEqual(20.2);
        }));

        it('should flag whether to show processing info or not', () => {
            const c = component();
            const dataItem = {
                noRateDesc: 'big rate'
            };
            expect(c.showProcessingInfo(dataItem)).toBeTruthy();
        });

        it('should reset the form when discard clicked', () => {
            const c = component();
            c.grid = {
                rowEditFormGroups: {
                    ['-370']: new FormGroup({})
                }
            } as any;
            c.ngOnInit();
            service.resetChanges$.next(true);
            expect(c.grid.rowEditFormGroups).toBeNull();
        });

        it('should call the warning popup', () => {
            const c = component();
            c.topic = new ChecklistsComponentTopic({
                viewData: {
                    caseId: 111,
                    hostId: ChecklistHostComponent.ChecklistHost
                }
            });
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({})
                }
            } as any;
            c.gridOptions._search = jest.fn();
            const data = [1, 2, 3];
            service.getCaseChecklistTypes$.mockReturnValue(of ({
                selectedChecklistType: 1,
                checklistTypes: data,
                selectedChecklistCriteriaKey: null
            }));
            service.getChecklistDocuments$.mockReturnValue(of ({
                1: 'test Doc 1'
            }));
            rootService.isHosted = true;
            warningService.getCasenamesWarnings = jest.fn().mockReturnValue(of({ budgetCheckResult: true }));
            modalService.modalRef.content = { btnClicked: of(), onBlocked: of(true) };
            c._handleCaseNameWarningConfirmation = jest.fn();
            c.ngOnInit();
            expect(modalService.openModal).toHaveBeenCalled();
            expect(warningService.restrictOnWip).toBeTruthy();
            expect(c._handleCaseNameWarningConfirmation).toHaveBeenCalled();
        });

        it('should take the value of generic key', () => {
            const c = component();
            c.topic = new ChecklistsComponentTopic({
                viewData: {
                    caseId: 111,
                    hostId: ChecklistHostComponent.ChecklistHost,
                    genericKey: 1
                }
            });
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({})
                }
            } as any;
            c.gridOptions._search = jest.fn();
            const data = [{checklistType: 1}, {checklistType: 2}, {checklistType: 3}];
            service.getCaseChecklistTypes$.mockReturnValue(of ({
                selectedChecklistType: 2,
                checklistTypes: data,
                selectedChecklistCriteriaKey: null
            }));
            rootService.isHosted = true;
            c.ngOnInit();
            expect(c.selectedChecklistTypeId).toBe(1);
        });

        it('should take the cached checklist type', () => {
            const c = component();
            c.topic = new ChecklistsComponentTopic({
                viewData: {
                    caseId: 111,
                    hostId: ChecklistHostComponent.ChecklistWizardHost,
                    genericKey: 1
                }
            });
            c.cachedData = {
                checklistTypeId: 3,
                checklistCriteriaKey: 2
            };
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({})
                }
            } as any;
            c.gridOptions._search = jest.fn();
            const data = [{checklistType: 1}, {checklistType: 2}, {checklistType: 3}];
            service.getCaseChecklistTypes$.mockReturnValue(of ({
                selectedChecklistType: 2,
                checklistTypes: data,
                selectedChecklistCriteriaKey: null
            }));
            rootService.isHosted = true;
            c.ngOnInit();
            expect(c.selectedChecklistTypeId).toBe(3);
            expect(c.selectedCriteriaKey).toBe(2);
        });

        it('should have no paging when in hosted hybrid mode', () => {
            const c = component();
            c.isHosted = true;
            expect(c.getPaging()).toBeFalsy();
        });

        it('should default the date when no date entered on yes or no answer', () => {
            const dataItem = {
                yesDateOption: 1,
                noDateOption: 1
            };
            const c = component();
            service.eventDate.mockReturnValue(c.today);
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({
                        countValue: new FormControl(),
                        yesUpdateEventId: new FormControl(),
                        dateValue: new FormControl(),
                        yesAnswer: new FormControl({
                            value: false,
                            disabled: false
                        }),
                        noAnswer: new FormControl({
                            value: false,
                            disabled: false
                        })
                    })
                }
            } as any;
            c.grid.rowEditFormGroups['1001'].setValue({yesAnswer: true, noAnswer: false, countValue: 1, dateValue: null, yesUpdateEventId: null});
            c.grid.isValid = () => true;
            c.changeAnswer('yes', true, c.grid.rowEditFormGroups['1001'], dataItem);

            expect(c.grid.rowEditFormGroups['1001'].value.dateValue).toEqual(c.today);
        });

        it('should null the date when the user unchecks the yes answer', () => {
            const dataItem = {
                yesDateOption: 1,
                noDateOption: 0
            };
            const c = component();
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({
                        countValue: new FormControl(),
                        yesUpdateEventId: new FormControl(),
                        dateValue: new FormControl(),
                        yesAnswer: new FormControl({
                            value: false,
                            disabled: false
                        })
                    })
                }
            } as any;
            c.grid.rowEditFormGroups['1001'].setValue({yesAnswer: false, countValue: 1, dateValue: c.today, yesUpdateEventId: null});
            c.grid.isValid = () => true;
            c.changeAnswer('yes', true, c.grid.rowEditFormGroups['1001'], dataItem);

            expect(c.grid.rowEditFormGroups['1001'].value.dateValue).toEqual(null);
        });

        it('should null the date when the user unchecks the no answer', () => {
            const dataItem = {
                yesDateOption: 0,
                noDateOption: 1
            };
            const c = component();
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({
                        countValue: new FormControl(),
                        noUpdateEventId: new FormControl(),
                        dateValue: new FormControl(),
                        noAnswer: new FormControl({
                            value: false,
                            disabled: false
                        })
                    })
                }
            } as any;
            c.grid.rowEditFormGroups['1001'].setValue({noAnswer: false, countValue: 1, dateValue: c.today, noUpdateEventId: null});
            c.grid.isValid = () => true;
            c.changeAnswer('no', true, c.grid.rowEditFormGroups['1001'], dataItem);

            expect(c.grid.rowEditFormGroups['1001'].value.dateValue).toEqual(null);
        });

        it('should have date validation on yes or no answer or date value', () => {
            const dataItem = {
                yesDateOption: null,
                noDateOption: null
            };
            const c = component();
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({
                        countValue: new FormControl(),
                        yesUpdateEventId: new FormControl(),
                        noUpdateEventId: new FormControl(),
                        dateValue: new FormControl(),
                        yesAnswer: new FormControl({
                            value: false,
                            disabled: false
                        }),
                        noAnswer: new FormControl({
                            value: false,
                            disabled: false
                        })
                    })
                }
            } as any;
            c.grid.isValid = () => false;
            c.grid.rowEditFormGroups['1001'].setValue({yesAnswer: true, noAnswer: false, countValue: 1, dateValue: null, yesUpdateEventId: 123, noUpdateEventId: null});
            c.changeAnswer('yes', true, c.grid.rowEditFormGroups['1001'], dataItem);
            expect(c.grid.rowEditFormGroups['1001'].controls.dateValue.errors).toEqual({required: true});

            c.grid.rowEditFormGroups['1001'].setValue({yesAnswer: false, noAnswer: true, countValue: 1, dateValue: null, yesUpdateEventId: null, noUpdateEventId: 123});
            c.changeAnswer('no', true, c.grid.rowEditFormGroups['1001'], dataItem);
            expect(c.grid.rowEditFormGroups['1001'].controls.dateValue.errors).toEqual({required: true});

            c.changeAnswer('dateValue', new Date(), c.grid.rowEditFormGroups['1001'], dataItem);
            expect(c.grid.rowEditFormGroups['1001'].controls.dateValue.dirty).toEqual(true);
            expect(c.grid.rowEditFormGroups['1001'].controls.dateValue.touched).toEqual(true);

            c.grid.rowEditFormGroups['1001'].setValue({yesAnswer: true, noAnswer: true, countValue: 1, dateValue: null, yesUpdateEventId: null, noUpdateEventId: 123});
            c.changeAnswer('yes', true, c.grid.rowEditFormGroups['1001'], dataItem);
            expect(c.grid.rowEditFormGroups['1001'].controls.noAnswer.value).toEqual(false);
            expect(c.grid.rowEditFormGroups['1001'].controls.dateValue.errors).toEqual(null);

            c.grid.rowEditFormGroups['1001'].setValue({yesAnswer: true, noAnswer: true, countValue: 1, dateValue: null, yesUpdateEventId: 123, noUpdateEventId: null});
            c.changeAnswer('no', true, c.grid.rowEditFormGroups['1001'], dataItem);
            expect(c.grid.rowEditFormGroups['1001'].controls.yesAnswer.value).toEqual(false);
            expect(c.grid.rowEditFormGroups['1001'].controls.dateValue.errors).toEqual(null);

            c.changeAnswer('dateValue', null, c.grid.rowEditFormGroups['1001'], dataItem);
            expect(c.grid.rowEditFormGroups['1001'].controls.dateValue.errors).toEqual(null);
        });

        it('should change child Answer if dependent', () => {
            const dataItem = {
                questionNo: 1001,
                yesAnswer: new FormControl({
                    value: true,
                    disabled: false
                }),
                noAnswer: null,
                textValue: 'checklist text for a form'
            };
            const dataItem1 = {
                questionNo: 1002,
                yesAnswer: new FormControl({
                    value: true,
                    disabled: false
                }),
                noAnswer: null,
                textValue: 'checklist text for a form',
                sourceQuestionId: 1001,
                answerSourceYes: 6,
                answerSourceNo: 7
            };
            const c = component();
            c.originalData = {
                    dataItem,
                    dataItem1
            };
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({
                        yesAnswer: new FormControl({
                            value: false,
                            disabled: false
                        }),
                        noAnswer: new FormControl({
                            value: false,
                            disabled: false
                        }),
                        yesUpdateEventId: new FormControl(),
                        noUpdateEventId: new FormControl(),
                        dateValue: new FormControl(),
                        questionId: new FormControl(1001)
                    }),
                    ['1002']: new FormGroup({
                        yesAnswer: new FormControl(),
                        noAnswer: new FormControl(),
                        yesUpdateEventId: new FormControl(),
                        noUpdateEventId: new FormControl(),
                        dateValue: new FormControl(),
                        sourceQuestionId: new FormControl(1001),
                        questionId: new FormControl(1002)
                    })
                }
            } as any;
            c.grid.isValid = () => false;
            c.grid.rowEditFormGroups['1001'].setValue({yesAnswer: true, noAnswer: false, dateValue: null, yesUpdateEventId: 123, noUpdateEventId: null, questionId: '1001'});
            c.changeAnswer('yes', true, c.grid.rowEditFormGroups['1001'], dataItem);
            expect(c.grid.rowEditFormGroups['1002'].controls.yesAnswer.value).toEqual(true);
            expect(c.grid.rowEditFormGroups['1002'].controls.noAnswer.value).toEqual(false);
            expect(c.grid.rowEditFormGroups['1002'].controls.yesAnswer.disabled).toEqual(true);
            expect(c.grid.rowEditFormGroups['1002'].controls.noAnswer.disabled).toEqual(true);

            c.grid.rowEditFormGroups['1001'].setValue({yesAnswer: false, noAnswer: true, dateValue: null, yesUpdateEventId: 123, noUpdateEventId: null, questionId: '1002'});
            c.changeAnswer('no', true, c.grid.rowEditFormGroups['1001'], dataItem);
            expect(c.grid.rowEditFormGroups['1002'].controls.yesAnswer.value).toEqual(false);
            expect(c.grid.rowEditFormGroups['1002'].controls.noAnswer.value).toEqual(true);
            expect(c.grid.rowEditFormGroups['1002'].controls.yesAnswer.disabled).toEqual(true);
            expect(c.grid.rowEditFormGroups['1002'].controls.noAnswer.disabled).toEqual(true);
        });

        it('should validate the controls and mark them dirty', () => {
            const c = component();
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({
                        yesNoOption: new FormControl(),
                        countValue: new FormControl(),
                        textValue:  new FormControl(null, Validators.required),
                        yesUpdateEventId: new FormControl(),
                        noUpdateEventId: new FormControl(),
                        dateValue: new FormControl(),
                        yesAnswer: new FormControl({
                            value: false,
                            disabled: false
                        }, Validators.required),
                        noAnswer: new FormControl({
                            value: false,
                            disabled: false
                        }, Validators.required)
                    })
                }
            } as any;
            c.grid.isValid = () => false;
            c.grid.checkChanges = () => jest.fn();
            c.grid.rowEditFormGroups['1001'].setValue({yesNoOption: 0, yesAnswer: true, noAnswer: false, countValue: [1, {required: true}], textValue: ['aaa', {required: true}], dateValue: null, yesUpdateEventId: 123, noUpdateEventId: 333});
            c.grid.rowEditFormGroups['1001'].controls.textValue.setValue('');
            c.isValid();
            expect(c.grid.rowEditFormGroups['1001'].controls.textValue.dirty).toEqual(true);
            expect(c.grid.rowEditFormGroups['1001'].controls.textValue.touched).toEqual(true);
            expect(c.grid.rowEditFormGroups['1001'].controls.textValue.errors).toEqual({required: true});

            c.grid.rowEditFormGroups['1001'].setValue({yesNoOption: 1, yesAnswer: false, noAnswer: false, countValue: null, textValue: null, dateValue: null, yesUpdateEventId: 123, noUpdateEventId: 333});
            c.isValid();
            expect(c.grid.rowEditFormGroups['1001'].controls.yesAnswer.dirty).toEqual(true);
            expect(c.grid.rowEditFormGroups['1001'].controls.noAnswer.dirty).toEqual(true);
            expect(c.grid.rowEditFormGroups['1001'].controls.noAnswer.errors).toEqual({required: true});
            expect(c.isValidData).toBeFalsy();
            expect(c.isYesNoRequired(c.grid.rowEditFormGroups['1001'])).toBe(true);
        });

        it('should mark disabled mandatory options as valid', () => {
            const dataItem = {
                questionNo: 1001,
                yesAnswer: new FormControl({
                    value: true,
                    disabled: false
                }),
                noAnswer: null,
                textValue: 'checklist text for a form'
            };
            const dataItem1 = {
                questionNo: 1002,
                yesAnswer: new FormControl({
                    value: true,
                    disabled: false
                }),
                noAnswer: null,
                textValue: 'checklist text for a form',
                sourceQuestionId: 1001,
                answerSourceYes: 8,
                answerSourceNo: 7,
                yesNoOption: 1
            };
            const c = component();
            c.originalData = {
                dataItem,
                dataItem1
            };
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({
                        yesAnswer: new FormControl({
                            value: false,
                            disabled: false
                        }),
                        noAnswer: new FormControl({
                            value: false,
                            disabled: false
                        }),
                        yesUpdateEventId: new FormControl(),
                        noUpdateEventId: new FormControl(),
                        dateValue: new FormControl(),
                        questionId: new FormControl(1001)
                    }),
                    ['1002']: new FormGroup({
                        yesAnswer: new FormControl(),
                        noAnswer: new FormControl(),
                        yesUpdateEventId: new FormControl(),
                        noUpdateEventId: new FormControl(),
                        dateValue: new FormControl(),
                        sourceQuestionId: new FormControl(1001),
                        questionId: new FormControl(1002)
                    })
                }
            } as any;
            c.grid.isValid = () => false;
            c.grid.checkChanges = jest.fn();
            c.grid.rowEditFormGroups['1001'].setValue({ yesAnswer: true, noAnswer: false, dateValue: null, yesUpdateEventId: 123, noUpdateEventId: null, questionId: '1001' });
            c.changeAnswer('yes', true, c.grid.rowEditFormGroups['1001'], dataItem);
            expect(c.grid.rowEditFormGroups['1002'].controls.yesAnswer.value).toBeFalsy();
            expect(c.grid.rowEditFormGroups['1002'].controls.noAnswer.value).toBeFalsy();
            expect(c.grid.rowEditFormGroups['1002'].controls.yesAnswer.disabled).toBeTruthy();
            expect(c.grid.rowEditFormGroups['1002'].controls.noAnswer.disabled).toBeTruthy();
            c.isValid();
            expect(c.grid.rowEditFormGroups['1002'].controls.yesAnswer.errors).toBeNull();
            expect(c.grid.rowEditFormGroups['1002'].controls.noAnswer.errors).toBeNull();

            c.grid.rowEditFormGroups['1001'].setValue({ yesAnswer: false, noAnswer: true, dateValue: null, yesUpdateEventId: 123, noUpdateEventId: null, questionId: '1001' });
            c.changeAnswer('no', true, c.grid.rowEditFormGroups['1001'], dataItem);
            expect(c.grid.rowEditFormGroups['1002'].controls.yesAnswer.value).toBeFalsy();
            expect(c.grid.rowEditFormGroups['1002'].controls.noAnswer.value).toBeTruthy();
            expect(c.grid.rowEditFormGroups['1002'].controls.yesAnswer.disabled).toBeTruthy();
            expect(c.grid.rowEditFormGroups['1002'].controls.noAnswer.disabled).toBeTruthy();
            c.isValid();
            expect(c.grid.rowEditFormGroups['1002'].controls.noAnswer.errors).toBeNull();
            expect(c.grid.rowEditFormGroups['1002'].controls.yesAnswer.errors).toBeNull();
        });

        it('should send a change message to old web when edited', () => {
            const dataItem = {
                yesDateOption: 1,
                noDateOption: 1
            };
            const c = component();
            c.isHosted = true;
            service.eventDate.mockReturnValue(c.today);
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({
                        countValue: new FormControl(),
                        yesUpdateEventId: new FormControl(),
                        dateValue: new FormControl(),
                        yesAnswer: new FormControl({
                            value: false,
                            disabled: false
                        }),
                        noAnswer: new FormControl({
                            value: false,
                            disabled: false
                        })
                    })
                }
            } as any;
            c.grid.rowEditFormGroups['1001'].setValue({yesAnswer: true, noAnswer: false, countValue: 1, dateValue: null, yesUpdateEventId: null});
            c.grid.rowEditFormGroups['1001'].markAsDirty();
            c.grid.isValid = () => true;
            c.changeAnswer('yes', true, c.grid.rowEditFormGroups['1001'], dataItem);

            expect(parentMsg.postLifeCycleMessage).toHaveBeenCalledWith({
                action: 'onChange',
                target: c.hostingComponent,
                payload: {
                    isDirty: true
                }
            });

        });
    });

    describe('formGroups', () => {
        const dataItem = {
            questionNo: -370,
            yesEventNumber: null,
            yesRateNumber: 3,
            noEventNumber: 1,
            noRateNumber: null,
            periodTypeKey: null,
            yesAnswer: new FormControl({
                value: true,
                disabled: false
            }),
            noAnswer: null,
            textValue: 'checklist text for a form',
            countValue: 12,
            dateValue: null,
            staffNameKey: null,
            amountValue: 123.5,
            listSelectionKey: null,
            isProcessed: 1
        };
        const dataItem1 = {
            questionNo: -371,
            yesEventNumber: null,
            yesRateNumber: null,
            noEventNumber: 1,
            noRateNumber: null,
            periodTypeKey: null,
            yesAnswer: null,
            noAnswer: null,
            textValue: 'checklist text for a form',
            countValue: 12,
            dateValue: null,
            staffNameKey: null,
            amountValue: 123.5,
            listSelectionKey: null,
            sourceQuestionId: -370,
            answerSourceYes: 4,
            answerSourceNo: 5
        };

        it('should assign default value in form group correctly', () => {
            const c = component();
            c.originalData = {
                dataItem,
                dataItem1
            };
            const fg = c.createFormGroup(dataItem1);
            expect(Object.keys(fg.controls).length).toEqual(23);
            expect(fg.value.questionId).toEqual(dataItem1.questionNo);
            expect(fg.value.sourceQuestionId).toEqual(dataItem.questionNo);
            expect(fg.controls.yesAnswer.value).toEqual(true);
            expect(fg.controls.noAnswer.value).toEqual(false);
            expect(fg.controls.yesAnswer.disabled).toEqual(true);
            expect(fg.controls.noAnswer.disabled).toEqual(true);
        });

        it('should flag changes when a question is answered', () => {
            const c = component();
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({countValue: new FormControlWarning()})
                }
            } as any;
            c.grid.rowEditFormGroups['1001'].setValue({countValue: 10023943});
            c.grid.rowEditFormGroups['1001'].markAsDirty();
            expect(c.anyChanges()).toBeTruthy();
            expect(c.getChanges().checklistQuestions.rows[0].countValue).toEqual(10023943);
        });
        it('should show and hide the date field correctly', () => {
            const c = component();
            const fg = c.createFormGroup(dataItem);
            expect(c.hideDate(dataItem, fg)).toEqual(true);
        });
        it('should not open regeneration dialog when new checklist', () => {
            const c = component();
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({countValue: new FormControlWarning(), isProcessed: new FormControlWarning()}),
                    ['1002']: new FormGroup({countValue: new FormControlWarning(), isProcessed: new FormControlWarning()})
                }
            } as any;
            c.grid.rowEditFormGroups['1001'].setValue({countValue: 2, isProcessed: 0});
            c.grid.rowEditFormGroups['1002'].setValue({countValue: 1, isProcessed: 0});
            c.grid.rowEditFormGroups['1001'].markAsDirty();
            c.grid.rowEditFormGroups['1002'].markAsDirty();
            expect(c.getChanges().checklistQuestions.showRegenerationDialog).toBeFalsy();
        });
        it('should open regeneration dialog checklist already processed and user changes charges or document questions', () => {
            const c = component();
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({countValue: new FormControlWarning(), isProcessed: new FormControlWarning(), hasYesCharge: new FormControlWarning(), yesAnswer: new FormControlWarning()}),
                    ['1002']: new FormGroup({countValue: new FormControlWarning(), isProcessed: new FormControlWarning()})
                }
            } as any;
            c.grid.rowEditFormGroups['1001'].setValue({countValue: 2, isProcessed: 1, hasYesCharge: true, yesAnswer: true});
            c.grid.rowEditFormGroups['1002'].setValue({countValue: 1, isProcessed: 1});
            c.grid.rowEditFormGroups['1001'].markAsDirty();
            c.grid.rowEditFormGroups['1002'].markAsDirty();
            expect(c.getChanges().checklistQuestions.showRegenerationDialog).toBeTruthy();
        });

        it('should open regeneration dialog when general documents', () => {
            const c = component();
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({countValue: new FormControlWarning(), isProcessed: new FormControlWarning(), hasYesCharge: new FormControlWarning(), yesAnswer: new FormControlWarning()}),
                    ['1002']: new FormGroup({countValue: new FormControlWarning(), isProcessed: new FormControlWarning()})
                }
            } as any;
            c.grid.rowEditFormGroups['1001'].setValue({countValue: 2, isProcessed: 1, hasYesCharge: true, yesAnswer: true});
            c.grid.rowEditFormGroups['1002'].setValue({countValue: 1, isProcessed: 1});
            c.grid.rowEditFormGroups['1001'].markAsDirty();
            c.grid.rowEditFormGroups['1002'].markAsDirty();
            c.hasGeneralDocuments = true;
            const generalDocs = {
                1: 'test Doc 1'
            };
            service.getChecklistDocuments$.mockReturnValue(of (generalDocs));
            c.checklistCriteriaGeneralDocs = generalDocs;
            expect(c.getChanges().checklistQuestions.showRegenerationDialog).toBeTruthy();
            expect(c.hasGeneralDocuments).toBe(true);
            expect(c.getChanges().checklistQuestions.generalDocs).toBe(generalDocs);
        });

        it('should open regeneration dialog checklist already processed and user changes charges or document questions', () => {
            const c = component();
            const gridCacheddata: any = [{
                question: 'Question 1',
                questionId: '11',
                dateValue: null,
                yesDateOption: 0,
                noDateOption: 0,
                countValue: 1,
                periodTypeDescription: '',
                amountValue: 20.2,
                textValue: 'test cache',
                listSelection: '',
                staffName: '',
                isProcessed: 1
            }];
            c.gridCacheddata = gridCacheddata;
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({countValue: new FormControlWarning(), isProcessed: new FormControlWarning(), hasYesCharge: new FormControlWarning(), yesAnswer: new FormControlWarning()}),
                    ['1002']: new FormGroup({countValue: new FormControlWarning(), isProcessed: new FormControlWarning()})
                }
            } as any;
            c.grid.rowEditFormGroups['1001'].setValue({countValue: 2, isProcessed: 1, hasYesCharge: true, yesAnswer: true});
            c.grid.rowEditFormGroups['1002'].setValue({countValue: 1, isProcessed: 1});
            c.grid.rowEditFormGroups['1001'].markAsDirty();
            c.grid.rowEditFormGroups['1002'].markAsDirty();
            expect(c.getChanges().checklistQuestions.rows.length).toBe(3);
        });
    });

    describe('OnHostNavigation', () => {
        it('should navigate for workflow wizard and remember changes made in last step', () => {
            const c = component();
            const res: any = {};
            const payload: any = {
                data: {
                    checklistTypeId: 3,
                    checklistCriteriaKey: 2,
                    rows: [
                        {
                            question: 'Question 1',
                            questionId: 11,
                            dateValue: null,
                            yesDateOption: 0,
                            noDateOption: 0,
                            countValue: 1,
                            periodTypeDescription: '',
                            amountValue: 20.2,
                            textValue: 'test cache',
                            listSelection: '',
                            staffName: '',
                            isProcessed: 1
                        }
                    ]
                }
            };
            c.setOnHostNavigation(payload, res);
            expect(c.cachedData).not.toBeNull();
            expect(c.selectedCriteriaKey).not.toBeNull();
            expect(c.selectedChecklistTypeId).not.toBeNull();
            expect(c.selectedCriteriaKey).toBe(2);
            expect(c.selectedChecklistTypeId).toBe(3);
            expect(c.gridCacheddata).not.toBeNull();
        });

        it('should define onNavigationAction', () => {
            const c = component();
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({countValue: new FormControlWarning(), isProcessed: new FormControlWarning(), hasYesCharge: new FormControlWarning(), yesAnswer: new FormControlWarning()}),
                    ['1002']: new FormGroup({countValue: new FormControlWarning(), isProcessed: new FormControlWarning()})
                }
            } as any;
            c.grid.rowEditFormGroups['1001'].setValue({countValue: 2, isProcessed: 1, hasYesCharge: true, yesAnswer: true});
            c.grid.rowEditFormGroups['1002'].setValue({countValue: 1, isProcessed: 1});
            c.grid.rowEditFormGroups['1001'].markAsDirty();
            c.grid.rowEditFormGroups['1002'].markAsDirty();
            const res: any = {};
            const payload: any = {};
            c.grid.isValid = () => true;
            c.setOnHostNavigation(payload, res);
            expect(c.onNavigationAction).toBeDefined();
        });

        it('should call onNavigationAction and set values for post message', () => {
            const c = component();
            c.grid = {
                rowEditFormGroups: {
                    ['1001']: new FormGroup({
                        yesNoOption: new FormControl(),
                        countValue: new FormControl(),
                        textValue:  new FormControl(null, Validators.required),
                        yesUpdateEventId: new FormControl(),
                        noUpdateEventId: new FormControl(),
                        dateValue: new FormControl(),
                        yesAnswer: new FormControl({
                            value: false,
                            disabled: false
                        }, Validators.required),
                        noAnswer: new FormControl({
                            value: false,
                            disabled: false
                        }, Validators.required),
                        isProcessed: new FormControlWarning(),
                        hasYesCharge: new FormControlWarning()
                    })
                }
            } as any;
            c.grid.isValid = () => false;
            c.grid.checkChanges = () => jest.fn();
            c.grid.rowEditFormGroups['1001'].setValue({yesNoOption: 0, yesAnswer: true, noAnswer: false, countValue: [1, {required: true}], textValue: ['aaa', {required: true}], dateValue: null, yesUpdateEventId: 123, noUpdateEventId: 333, isProcessed: false, hasYesCharge: false});
            c.grid.rowEditFormGroups['1001'].controls.textValue.setValue('');

            const payload: any = {};
            const e: any = {};
            const then = jest.fn(() => any);
            c.setOnHostNavigation(payload, then);
            expect(c.onNavigationAction).toBeDefined();
            const changedData = c.getChanges();
            c.grid.rowEditFormGroups['1001'].controls.textValue.setValue('aaa');
            c.onNavigationAction(e);
            expect(c.getChanges().checklistQuestions.isValidData).toBe(false);
            expect(parentMsg.postLifeCycleMessage).toHaveBeenCalledWith({
                action: 'onValidated',
                target: c.hostingComponent,
                payload: {
                    isDirty: true,
                    data: changedData
                }
            });

            c.grid.rowEditFormGroups['1001'].controls.textValue.setValue('bbb');
            c.grid.rowEditFormGroups['1001'].controls.isProcessed.setValue(1);
            c.grid.rowEditFormGroups['1001'].controls.hasYesCharge.setValue(true);
            c.grid.rowEditFormGroups['1001'].markAsDirty();
            c.grid.isValid = () => true;
            modalService.modalRef.content = { proceedData: of(true), dontSave: of() };
            c.onNavigationAction(e);
            expect(modalService.openModal).toHaveBeenCalled();
            expect(c.isRegeneratedPopupShown).toBeTruthy();
        });

        it('should define onChangeAction', () => {
            const c = component();
            c.setOnChangeAction();
            expect(c.onChangeAction).toBeDefined();
        });

        it('should make null onChangeAction', () => {
            const c = component();
            c.removeOnChangeAction();
            expect(c.onChangeAction).toBeNull();
        });

        it('should set valid Data to true, if no changes', () => {
            const c = component();
            c.grid = {} as any;
            c.ngOnInit();
            c.grid.isValid = () => false;
            c.grid.checkChanges = () => jest.fn();
            const payload: any = {};
            const e: any = {};
            const then = jest.fn(() => any);
            const defaultChangedData = {
                checklistQuestions: {
                    rows: [],
                    checklistCriteriaKey: null,
                    checklistTypeId: 1,
                    showRegenerationDialog: false,
                    generalDocs: [],
                    isValidData: true
                }
            };
            c.setOnHostNavigation(payload, then);
            c.onNavigationAction(e);
            expect(parentMsg.postLifeCycleMessage).toHaveBeenCalledWith({
                action: 'onValidated',
                target: c.hostingComponent,
                payload: {
                    isDirty: true,
                    data: defaultChangedData
                    }
                });
        });
    });
});