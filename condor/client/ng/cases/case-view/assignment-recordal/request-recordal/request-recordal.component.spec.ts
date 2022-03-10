import { BsModalRefMock, ChangeDetectorRefMock, DateHelperMock, EventEmitterMock, IpxNotificationServiceMock, TranslateServiceMock } from 'mocks';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { GridSelectionHelper } from 'shared/component/grid/ipx-grid-selection-helper';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { AffectedCaseStatusEnum, RecordalRequestType, StepType } from '../affected-cases.model';
import { RequestRecordalComponent } from './request-recordal.component';

describe('RequestRecordalComponent', () => {
    let component: RequestRecordalComponent;
    let service: {
        getRequestRecordal(caseKey: number): any;
        getCaseReference(caseId: number): Observable<any>;
        onSaveRecordal(caseId: number, seqIds: Array<number>, requestedDate: Date, requestType: RecordalRequestType): Observable<any>
    };
    const selectAllService = { manageSelectDeSelect: jest.fn };
    let gridSelectionHelper: GridSelectionHelper;
    let cdRef: ChangeDetectorRefMock;
    let modalRef: BsModalRefMock;
    let dateService: DateHelperMock;
    let ipxNotificationService: IpxNotificationServiceMock;
    let ipxShortcutService: IpxShortcutsServiceMock;
    let translateService: TranslateServiceMock;
    let mockResponse: any;
    let mockResults: any;
    let columns: any;
    let destroy$: any;
    beforeEach(() => {
        gridSelectionHelper = new GridSelectionHelper(selectAllService as any);
        (gridSelectionHelper.rowSelectionChanged as any) = new EventEmitterMock<Array<any>>();
        columns = ['col1', 'col2'];
        mockResponse = { totalRows: 40, columns, rows: [] };
        mockResults = {
            filterable: true,
            pageable: true,
            pageSize: 20,
            read$: mockResponse,
            reorderable: true,
            sortable: true,
            selectable: { mode: 'single' },
            locked: false,
            pipe: jest.fn().mockReturnValue({ map: jest.fn() })
        };
        service = {
            getRequestRecordal: jest.fn().mockReturnValue(of(mockResults)),
            getCaseReference: jest.fn().mockReturnValue(of(123)),
            onSaveRecordal: jest.fn().mockReturnValue(of({ result: 'success' }))
        };
        destroy$ = of({}).pipe(delay(1000));
        translateService = new TranslateServiceMock();
        cdRef = new ChangeDetectorRefMock();
        modalRef = new BsModalRefMock();
        dateService = new DateHelperMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        ipxShortcutService = new IpxShortcutsServiceMock();
        component = new RequestRecordalComponent(service as any, translateService as any, ipxNotificationService as any, modalRef as any, destroy$, ipxShortcutService as any, dateService as any);

        (component as any).sbsModalRef = {
            hide: jest.fn()
        } as any;

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
        component._resultsGrid = new IpxKendoGridComponentMock() as any;
        component._resultsGrid.hasItemsSelected = jest.fn().mockReturnValue(true);
        component._resultsGrid.wrapper = {
            data: [
                { rowKey: '123^11', selected: true, isEditable: true, rowStatus: AffectedCaseStatusEnum.NotFiled },
                { rowKey: '123^12', selected: true, isEditable: false, rowStatus: AffectedCaseStatusEnum.Filed }
            ]
        } as any;
        component._resultsGrid.gridSelectionHelper.rowSelection = [...component._resultsGrid.wrapper.data as any];
        component._resultsGrid.getSelectedItems = jest.fn().mockReturnValue([true, false]);
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    describe('request recordal component functions', () => {
        it('should initialise component correctly', () => {
            jest.spyOn(component, 'handleShortcuts');
            component.ngOnInit();
            const columnFields = component.gridOptions.columns.map(col => col.field);
            expect(component.handleShortcuts).toBeCalled();
            expect(columnFields).toEqual(['caseReference', 'country', 'officialNo', 'stepId', 'recordalType', 'status', 'requestDate', 'recordDate']);
        });

        it('should toggle steps correctly', () => {
            component.showAllSteps = true;
            jest.spyOn(component._resultsGrid, 'search');
            component.toggleSteps({}, StepType.AllSteps);
            expect(component._resultsGrid.search).toBeCalled();
        });

        it('toggle should be mutually exclusive', () => {
            component.showAllSteps = true;
            component.showNextSteps = true;
            jest.spyOn(component._resultsGrid, 'search');
            component.toggleSteps({}, StepType.AllSteps);
            expect(component.showNextSteps).toBeFalsy();
            component.showAllSteps = true;
            component.showNextSteps = false;
            component.toggleSteps({}, StepType.AllSteps);
            expect(component.showNextSteps).toBeFalsy();
        });
    });

    describe('ondateChange', () => {
        it('should enable save on valid date', () => {
            const control = {
                value: new Date(),
                setErrors: jest.fn()
            };
            component.requestDateCtrl = { control };
            const event = new Date();
            component.onDateChanged(event);
            expect(component.requestDateCtrl.control.value).toEqual(event);
            expect(component.requestedDate).toEqual(event);
            expect(component.isSaveDisabled).toBeFalsy();
        });

        it('should disable save on empty date', () => {
            const control = {
                value: null,
                setErrors: jest.fn().mockReturnValue(jest.fn())
            };
            component.requestDateCtrl = { control };
            const event = null;
            component.onDateChanged(event);
            expect(component.requestDateCtrl.control.value).toEqual(event);
            expect(component.requestedDate).not.toEqual(event);
        });

        it('should send warning for future date', () => {
            const futureDate = new Date().setDate(new Date().getDate() + 1);
            const control = {
                value: futureDate,
                setErrors: jest.fn().mockReturnValue({})
            };
            component.requestDateCtrl = { control };
            const event = futureDate;
            component.onDateChanged(event);
            expect(component.requestDateCtrl.control.value).toEqual(event);
            expect(component.requestedDate).toEqual(event);
        });
        it('check if save button is disabled', () => {
            const control = {
                value: null,
                setErrors: jest.fn().mockReturnValue({})
            };
            component.requestDateCtrl = { control, invalid: true };
            const event = null;
            component.enableDisableSave();
            expect(component.requestDateCtrl.control.value).toEqual(event);
            expect(component.isSaveDisabled).toBeTruthy();
        });
    });

    describe('Recordal Request component set save and close', () => {
        it('set recordal request data with showSteps', () => {
            component.isSaveDisabled = false;
            component.requestType = RecordalRequestType.Request;
            component.showNextSteps = true;
            const response = [
                { rowKey: '123^11', selected: true, editable: true, status: AffectedCaseStatusEnum.NotFiled },
                { rowKey: '123^12', selected: true, editable: false, status: AffectedCaseStatusEnum.Filed }
            ];
            component.setData(response);
            expect(component.filteredData.length).toBe(1);
        });
        it('set recordal request data without showSteps', () => {
            component.isSaveDisabled = false;
            component.requestType = RecordalRequestType.Request;
            component.showNextSteps = false;
            const response = [
                { rowKey: '123^11', selected: true, editable: true, status: AffectedCaseStatusEnum.NotFiled },
                { rowKey: '123^12', selected: true, editable: false, status: AffectedCaseStatusEnum.Filed }
            ];
            component.setData(response);
            expect(component.filteredData.length).toBe(1);
            expect(component.filteredData).toEqual(response.filter(x => x.status === AffectedCaseStatusEnum.NotFiled));
        });
        it('save recordal request  modal', () => {
            component.isSaveDisabled = false;
            component.requestType = RecordalRequestType.Request;
            component.onSave();
            service.onSaveRecordal(123, [1], new Date(), component.requestType).subscribe(res => {
                expect((component as any).sbsModalRef.hide).toHaveBeenCalled();
                expect(component.isSaving).toBeFalsy();
            });
            expect(service.onSaveRecordal).toBeCalled();
        });

        it('close recordal request  modal', () => {
            component.isSaveDisabled = true;
            component.close();
            expect((component as any).sbsModalRef.hide).toHaveBeenCalled();
        });
    });
});