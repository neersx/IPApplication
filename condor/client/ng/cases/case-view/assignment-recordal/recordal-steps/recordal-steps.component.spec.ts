import { FormBuilder, FormGroup } from '@angular/forms';
import { DateServiceMock } from 'ajs-upgraded-providers/mocks/date-service.mock';
import { NotificationServiceMock } from 'ajs-upgraded-providers/notification-service.mock';
import { BsModalRefMock, ChangeDetectorRefMock, IpxNotificationServiceMock, TranslateServiceMock } from 'mocks';
import { BehaviorSubject, Observable } from 'rxjs';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { RecordalStep, RecordalStepElement, RecordalStepElementForm, StepElements } from '../affected-cases.model';
import { RecordalStepsComponent } from './recordal-steps.component';

describe('RecordalStepsComponent', () => {
    let component: RecordalStepsComponent;
    let recordalStep: RecordalStep;
    let service: {
        rowSelected$: BehaviorSubject<StepElements>;
        stepElementForm: Array<RecordalStepElementForm>;
        getRecordalSteps(caseKey: number): any;
        getRecordalStepElements(caseKey: number, stepId: number): any;
        clearStepElementRowFormData(stepId: number, rowId: number): void;
        clearStepElementFormData(): void;
        saveRecordalSteps(data: any): Observable<any>;
    };
    let notificationService: NotificationServiceMock;
    let cdRef: ChangeDetectorRefMock;
    let modalRef: BsModalRefMock;
    let dateService: DateServiceMock;
    let formBuilder: FormBuilder;
    let translateService: TranslateServiceMock;
    let ipxNotificationService: IpxNotificationServiceMock;
    beforeEach(() => {
        service = {
            rowSelected$: new BehaviorSubject<StepElements>({ stepId: 1 } as any),
            stepElementForm: [
                {
                    stepId: 1, rowId: 1, form: { status: 'INVALID', dirty: false }
                }
            ] as any,
            getRecordalSteps: jest.fn(),
            getRecordalStepElements: jest.fn(),
            clearStepElementRowFormData: jest.fn(),
            clearStepElementFormData: jest.fn(),
            saveRecordalSteps: jest.fn().mockReturnValue(new Observable())
        };
        notificationService = new NotificationServiceMock();
        cdRef = new ChangeDetectorRefMock();
        modalRef = new BsModalRefMock();
        dateService = new DateServiceMock();
        formBuilder = new FormBuilder();
        translateService = new TranslateServiceMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        component = new RecordalStepsComponent(cdRef as any, service as any, modalRef as any, dateService as any, formBuilder as any, notificationService as any, ipxNotificationService as any, translateService as any);
        component.isHosted = false;
        component.resultsGrid = {
            checkChanges: jest.fn(),
            closeEditedRows: jest.fn(),
            isValid: jest.fn(),
            isDirty: jest.fn(),
            closeRow: jest.fn(),
            focusRow: jest.fn(),
            wrapper: {
                data: [
                    {
                        caseId: 1,
                        stepId: 1,
                        id: 1,
                        value: 'value1',
                        status: 'A'
                    }, {
                        caseId: 1,
                        stepId: 2,
                        id: 1,
                        value: 'value2'
                    }
                ]
            },
            rowEditFormGroups: [
                'formgroup1',
                'formgroup2'
            ]
        } as any;
        (component as any).sbsModalRef = {
            hide: jest.fn()
        } as any;
        const recordalStepElements: Array<RecordalStepElement> = [
            { caseId: 1, id: 1, stepId: 1, elementId: 1, element: 'Element1', label: 'value', namePicklist: null, typeText: 'name' },
            { caseId: 1, id: 2, stepId: 2, elementId: 1, element: 'Element1', label: 'value', namePicklist: null, typeText: 'name' },
            { caseId: 1, id: 2, stepId: 2, elementId: 2, element: 'Element1', label: 'value', namePicklist: null, typeText: 'name' }
        ];
        recordalStep = {
            caseId: 1, id: 1, stepId: 1, stepName: 'Step 1', recordalType: null, modifiedDate: '1999/1/1',
            caseRecordalStepElements: recordalStepElements
        };
        const gridOptions = {
            filterable: true,
            sortable: false,
            reorderable: true,
            canAdd: true,
            columns: [
                { field: 'status1', fixed: true, locked: true, hidden: false },
                { field: 'status2', fixed: true, locked: true, hidden: false },
                { field: 'caseRef', fixed: true, locked: true, hidden: false }
            ]
        } as any;

        component.gridOptions = gridOptions;
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });
    it('should set rowSelected', () => {
        service.rowSelected$.next = jest.fn();
        const recordalStepElement: Array<RecordalStepElement> = [{
            caseId: 1,
            id: 1,
            stepId: 1,
            elementId: 1,
            label: 'Label 1',
            namePicklist: [{ key: 1, vlaue: 'value' }],
            element: 'ele',
            typeText: 'name'
        }];
        const step: RecordalStep = {
            id: 1,
            caseId: 1,
            stepId: 1,
            stepName: 'step 1',
            recordalType: {
                key: 1,
                value: 'Change of Address'
            },
            modifiedDate: new Date(),
            caseRecordalStepElements: recordalStepElement
        };
        component.resultsGrid = { rowEditFormGroups: { ['1001']: new FormGroup({}) } } as any;
        jest.spyOn(component, 'processRecordalRelments');
        component.dataItemClicked(step);
        const stepElements = { stepId: 1, recordalStepElement, recordalType: 1 };
        expect(service.rowSelected$.next).toHaveBeenCalledWith(stepElements);
        expect(component.processRecordalRelments).toHaveBeenCalled();
    });
    it('should call saveRecordalSteps on save', () => {
        component.onSave();
        expect(service.saveRecordalSteps).toHaveBeenCalled();
    });
    it('should clear the formGroup and rowEditFormGroups on resetForm', () => {
        component.resultsGrid = { rowEditFormGroups: { ['1001']: new FormGroup({}) } } as any;
        component.gridOptions.formGroup = { dirty: false } as any;
        component.resultsGrid.closeRow = jest.fn();
        component.resetForm();
        expect(component.gridOptions.formGroup).toBeUndefined();
        expect(component.resultsGrid.rowEditFormGroups).toBeNull();
        expect(component.formGroup).toBeNull();
        expect(component.resultsGrid.closeRow).toHaveBeenCalled();
    });
    it('onStepAddOrEdit should call the dataItemclikced and focus row', () => {
        const event: any = { rowIndex: 1, dataItem: { caseId: 1, stepId: 1, id: 1, elementId: 1 } };
        component.dataItemClicked = jest.fn();
        component.onStepAddOrEdit(event);
        expect(component.resultsGrid.focusRow).toHaveBeenCalledWith(1);
        expect(component.dataItemClicked).toHaveBeenCalledWith(event.dataItem);
    });
    it('on dataItemClicked if row is invalid alert should be displayed', () => {
        recordalStep.id = 2;
        const stepElemtns: StepElements = { stepId: 1 };
        ipxNotificationService.openAlertModal = jest.fn();
        service.rowSelected$.next(stepElemtns);
        component.dataItemClicked(recordalStep);
        expect(ipxNotificationService.openAlertModal).toHaveBeenCalled();
    });
    it('on dataItemClicked if row is valid alert should be displayed', () => {
        const stepElemtns: StepElements = { stepId: 1 };
        component.processRecordalRelments = jest.fn();
        service.rowSelected$.next(stepElemtns);
        component.dataItemClicked(recordalStep);
        expect(component.processRecordalRelments).toHaveBeenCalledWith(recordalStep);
    });
    it('on loadRecordalElement should set the rowSelected$', () => {
        service.rowSelected$.next = jest.fn();
        component.loadRecordalElement(recordalStep);
        expect(service.rowSelected$.next).toHaveBeenCalled();
    });

    it('close recordal steps modal', () => {
        component.close();
        expect((component as any).sbsModalRef.hide).toHaveBeenCalled();
        expect(service.clearStepElementFormData).toHaveBeenCalled();
    });

    it('should return isFormDirty true when dataRows has new status added', () => {
        component.resultsGrid.checkChanges = () => jest.fn();
        component.resultsGrid.isValid = jest.fn().mockReturnValue(true);
        component.gridOptions.formGroup = { dirty: false } as any;
        const isDirty = component.isFormDirty();
        expect(isDirty).toBeTruthy();
    });

    it('should return isFormDirty false when grid dataRows had new status but grid is not valid', () => {
        component.resultsGrid.checkChanges = () => jest.fn();
        component.resultsGrid.isValid = jest.fn().mockReturnValue(false);
        component.gridOptions.formGroup = { dirty: false } as any;
        const isDirty = component.isFormDirty();
        expect(isDirty).toBeFalsy();
    });

    it('should return isFormDirty false when dataRows has no new status added and grid is valid', () => {
        component.resultsGrid = { rowEditFormGroups: { ['1001']: new FormGroup({}) } } as any;
        component.resultsGrid = {
            wrapper: {
                data: [
                    {
                        caseId: 1,
                        stepId: 1,
                        id: 1,
                        value: 'value1'
                    }, {
                        caseId: 1,
                        stepId: 2,
                        id: 1,
                        value: 'value2'
                    }
                ]
            },
            rowEditFormGroups: [
                'formgroup1',
                'formgroup2'
            ]
        } as any;
        component.resultsGrid.checkChanges = () => jest.fn();
        component.resultsGrid.isValid = jest.fn().mockReturnValue(true);
        component.gridOptions.formGroup = { dirty: false } as any;
        const isDirty = component.isFormDirty();
        expect(isDirty).toBeFalsy();
    });

    it('on processRecordalRelments if recorcalType is defined should load the recordalElements', () => {
        const event: any = {
            id: 1, isAssigned: true, recordalType: {
                key: 1,
                value: 'Change of Address'
            }
        };
        component.loadRecordalElement = jest.fn();
        component.processRecordalRelments(event);
        expect(component.loadRecordalElement).not.toHaveBeenCalled();
    });
});