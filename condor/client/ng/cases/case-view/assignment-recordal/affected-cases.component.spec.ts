import { fakeAsync, tick } from '@angular/core/testing';
import { RootScopeServiceMock } from 'ajs-upgraded-providers/mocks/rootscope.service.mock';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { ChangeDetectorRefMock, ElementRefMock, EventEmitterMock, IpxNotificationServiceMock, NotificationServiceMock, Renderer2Mock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { SearchHelperService } from 'search/common/search-helper.service';
import { GridSelectionHelper } from 'shared/component/grid/ipx-grid-selection-helper';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { CaseDetailServiceMock } from '../case-detail.service.mock';
import { AddAffectedCaseComponent } from './add-affected-case/add-affected-case.component';
import { AffectedCasesComponent } from './affected-cases.component';
import { AffectedCasesItems, BulkOperationType, RecordalRequestType } from './affected-cases.model';
import { RecordalStepsComponent } from './recordal-steps/recordal-steps.component';

describe('AffectedCasesComponent', () => {
    let gridSelectionHelper: GridSelectionHelper;
    const selectAllService = { manageSelectDeSelect: jest.fn };
    let component: AffectedCasesComponent;
    let localSettings: LocalSettingsMock;
    let cdRef: ChangeDetectorRefMock;
    let rootService: RootScopeServiceMock;
    let elementRef: ElementRefMock;
    let caseDetailService: CaseDetailServiceMock;
    let caseSearchHelperService;
    let ipxNotificationService: any;
    let mockResponse: any;
    let mockResults: any;
    let columns: any;
    let service: {
        getAffectedCases(caseKey: number): any;
        getColumns$(): any;
        updatedAffectedCases: Array<AffectedCasesItems>;
        performBulkOperation(caseKey: number, selectedRowKeys: Array<AffectedCasesItems>, deSelectedRowKeys: Array<AffectedCasesItems>, isAllSelected: boolean, filter: any, operationType: BulkOperationType): any;
    };
    let modalService: ModalServiceMock;
    let renderer2: Renderer2Mock;
    let notificationService: NotificationServiceMock;
    let shortcutsService: IpxShortcutsServiceMock;
    let destroy$: any;
    beforeEach(() => {
        gridSelectionHelper = new GridSelectionHelper(selectAllService as any);
        (gridSelectionHelper.rowSelectionChanged as any) = new EventEmitterMock<Array<any>>();
        const stringColumn: any = {
            title: 'textColTitle',
            format: 'anyColumn',
            id: 'strCol',
            isColumnFreezed: false
        };

        const hyperlinkColumn: any = {
            title: 'hyperColTitle',
            format: 'string',
            id: 'hyperCol',
            isHyperlink: true,
            isColumnFreezed: false
        };

        columns = [stringColumn, hyperlinkColumn];
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
            getAffectedCases: jest.fn().mockReturnValue(mockResults),
            getColumns$: jest.fn().mockReturnValue(of(columns)),
            updatedAffectedCases: [] as any,
            performBulkOperation: jest.fn().mockReturnValue(of(null))
        };
        localSettings = new LocalSettingsMock();
        cdRef = new ChangeDetectorRefMock();
        rootService = new RootScopeServiceMock();
        caseDetailService = new CaseDetailServiceMock();
        modalService = new ModalServiceMock();
        renderer2 = new Renderer2Mock();
        notificationService = new NotificationServiceMock();
        elementRef = new ElementRefMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        const translateServiceMock = new TranslateServiceMock();
        caseSearchHelperService = new SearchHelperService();
        shortcutsService = new IpxShortcutsServiceMock();
        destroy$ = of({}).pipe(delay(1000));
        component = new AffectedCasesComponent(localSettings as any, cdRef as any, rootService as any, service as any,
            caseSearchHelperService, modalService as any, caseDetailService as any, renderer2 as any, elementRef as any, ipxNotificationService, notificationService as any, translateServiceMock as any, destroy$, shortcutsService as any);
        component.isHosted = false;
        component.topic = {
            hasErrors$: new BehaviorSubject<Boolean>(false),
            setErrors: jest.fn(),
            getErrors: jest.fn(),
            hasChanges: false,
            key: 'assignedCases',
            title: 'Assignment Recordal',
            params: {
                viewData: {
                    caseKey: 123
                }
            }
        } as any;
        component._resultsGrid = new IpxKendoGridComponentMock() as any;
        component._resultsGrid.wrapper = {
            data: [
                { rowKey: '123^11', steps: [{ step1: true, step2: false }] },
                { rowKey: '123^12', steps: [{ step1: true, step2: false }] }
            ]
        } as any;
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    describe('ngOnInit', () => {
        it('should initialise the column configs correctly', () => {
            component.topic = {
                hasErrors$: new BehaviorSubject<Boolean>(false),
                setErrors: jest.fn(),
                params: {
                    viewData: {
                        canMaintainCase: true
                    }
                }
            } as any;

            component.ngOnInit();
            const columnFields = component.gridOptions.columns.map(col => col.field);
            component.topic.hasErrors$.subscribe((err) => { expect(err).toBeFalsy(); });
            expect(component.topic.hasChanges).toBe(false);
            expect(columnFields).toEqual(['strCol', 'hyperCol.value']);
        });

        it('should initialize shortcuts', () => {
            component.ngOnInit();
            expect(shortcutsService.observeMultiple$).toHaveBeenCalledWith([RegisterableShortcuts.ADD]);
        });

        it('should call add on event if hosted', fakeAsync(() => {
            component.openAddAffectedCases = jest.fn();
            component.isHosted = true;
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.ADD;
            component.ngOnInit();
            tick(shortcutsService.interval);

            expect(component.openAddAffectedCases).toHaveBeenCalled();
        }));

        it('should return data and pagination to grid', () => {

            component.ngOnInit();
            const readResult: any = mockResults;
            expect(readResult.pageSize).toBe(20);
            expect(readResult.pageable).toBe(true);
            expect(readResult.selectable).toBeDefined();
            expect(readResult.read$.columns).toBe(columns);
        });

        it('should return column locked property false when no column is freezed', () => {
            component.ngOnInit();
            const returnedColumns = component.buildColumns(columns);
            expect(component.anyColumnLocked).toBeFalsy();
            expect(returnedColumns[0].locked).toBeFalsy();
            expect(returnedColumns[1].locked).toBeFalsy();
        });

        it('should set total rows into the component', () => {

            component.ngOnInit();
            expect(component.totalRecords).not.toBe(40);
        });

        it('should toggle grid columns correctly for false', () => {
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
            component._resultsGrid.dataOptions = gridOptions;

            component.toggleRecordalStepStatusColumn(false);
            expect(component.gridOptions.columns[0].hidden).toBeTruthy();
            expect(component.gridOptions.columns[1].hidden).toBeTruthy();
            expect(component.gridOptions.columns[2].hidden).toBeFalsy();
        });

        it('should toggle grid columns correctly for true', () => {
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
            component._resultsGrid.dataOptions = gridOptions;

            component.toggleRecordalStepStatusColumn(true);
            expect(component.gridOptions.columns[0].hidden).toBeFalsy();
            expect(component.gridOptions.columns[1].hidden).toBeFalsy();
            expect(component.gridOptions.columns[2].hidden).toBeFalsy();
        });

        it('should get and apply filter data', () => {
            component.gridOptions = { _search: jest.fn().mockReturnValue({}), read$: jest.fn(), columns: [] };
            jest.spyOn(component.gridOptions, '_search');
            const obj = {
                form: {
                    stepNo: 1,
                    recordalStatus: ['Filed'],
                    recordalTypeNo: 2
                },
                filter: []
            };
            component.getFilterData(obj);
            expect(component.gridOptions._search).toBeCalled();
            expect(component.showFilter).toBeFalsy();
        });
    });

    it('should call requestRecordal', () => {
        const grid = component._resultsGrid;
        jest.spyOn(component, 'performRecordalOperations');
        component.requestRecordal(grid);
        expect(component.performRecordalOperations).toBeCalledWith(grid, RecordalRequestType.Request);
    });

    it('should call rejectRecordal', () => {
        const grid = component._resultsGrid;
        jest.spyOn(component, 'performRecordalOperations');
        component.rejectRecordal(grid);
        expect(component.performRecordalOperations).toBeCalledWith(grid, RecordalRequestType.Reject);
    });

    it('should call applyRecordal', () => {
        const grid = component._resultsGrid;
        jest.spyOn(component, 'performRecordalOperations');
        component.applyRecordal(grid);
        expect(component.performRecordalOperations).toBeCalledWith(grid, RecordalRequestType.Apply);
    });

    it('should call performRecordalOperations', () => {
        const grid = component._resultsGrid;
        const operationType = RecordalRequestType.Request;
        modalService.content = { onClose$: new Observable() };
        component.performRecordalOperations(grid, operationType);
        expect(modalService.openModal).toBeCalled();
        modalService.content.onClose$.subscribe(res => {
            expect(res.toBeDefined());
            expect(res.toBe('success'));
        });
    });

    it('should open recordal steps window', () => {
        component.openRecordalSteps();

        expect(modalService.openModal).toHaveBeenCalledWith(RecordalStepsComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-xl',
            initialState: {
                isHosted: false,
                canMaintain: false,
                caseKey: component.caseKey
            }
        });
    });

    it('should open recordal steps window', () => {
        component.openAddAffectedCases();
        expect(modalService.openModal).toHaveBeenCalledWith(AddAffectedCaseComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                caseKey: component.caseKey
            }
        });
    });

    describe('setAgent', () => {
        it('should open Set Agent modal', () => {
            component.ngOnInit();
            component._resultsGrid.getRowSelectionParams().rowSelection = [1, 2, 3];
            component._resultsGrid.getRowSelectionParams().allSelectedItems = [1, 2, 3];
            component.setAffectedCaseAgent(component._resultsGrid);
            expect(modalService.openModal).toHaveBeenCalled();
        });
        it('should open Set Agent modal for all rows', () => {
            component.ngOnInit();
            component._resultsGrid.getRowSelectionParams().isAllPageSelect = true;
            component._resultsGrid.getRowSelectionParams().allDeSelectedItems = [3];
            component.setAffectedCaseAgent(component._resultsGrid);
            expect(modalService.openModal).toHaveBeenCalled();
        });
    });

    describe('deleteAffectedCases', () => {
        beforeEach(() => {
            component._resultsGrid.getRowSelectionParams().isAllPageSelect = true;
            component._resultsGrid.getRowSelectionParams().allDeSelectedItems = [{ entryNo: 5 }, { entryNo: 6 }];
            ipxNotificationService.openDeleteConfirmModal = jest.fn().mockReturnValue({ content: { confirmed$: of(true), cancelled$: of(true) } });
        });
        it('getchanges called before save', () => {
            component.stepColumns = [{ step1: 'step1', step2: 'step2' }];
            const data = component.getChanges();
            expect(data).toBeDefined();
            expect(service.updatedAffectedCases.length).toEqual(0);
        });

        it('should enable save when updatedAffectedCases has values', () => {
            component.stepColumns = [{ step1: 'step1', step2: 'step2' }];
            service.updatedAffectedCases = [
                {
                    rowKey: '123^11',
                    caseRef: '123',
                    jurisdiction: 'AUS',
                    officialNo: '123'
                }
            ];
            component.checkValidationAndEnableSave();
            expect(caseDetailService.hasPendingChanges$.getValue()).toBeTruthy();
        });

        it('should disable save when updatedAffectedCases has no value', () => {
            component.stepColumns = [{ step1: 'step1', step2: 'step2' }];
            service.updatedAffectedCases = [];
            component.checkValidationAndEnableSave();
            expect(caseDetailService.hasPendingChanges$.getValue()).toBeFalsy();
        });

        it('should return the corrent row from dataRow', () => {
            let row = component.getDataRow('123^11');
            expect(row).toBeDefined();
            expect(row.rowKey).toEqual('123^11');
            row = component.getDataRow('123^111');
            expect(row).toBeUndefined();
        });

        it('should return success notification when bulk delete success for all selected records', (done) => {
            const response = { status: 'success' };
            component.deleteAffectedCases(component._resultsGrid);
            service.performBulkOperation = jest.fn().mockReturnValue(of(response));
            service.performBulkOperation(123, null, null, false, null, BulkOperationType.DeleteAffectedCases).subscribe((res: any) => {
                expect(res).toBe(response);
                done();
            });
        });

        it('should return partial complete notification when all records are not deleted', (done) => {
            const response = { status: 'partialComplete', cannotDeleteCaselistIds: [1, 2] };
            service.performBulkOperation = jest.fn().mockReturnValue(of(response));
            component.deleteAffectedCases(component._resultsGrid);
            service.performBulkOperation(123, null, null, false, null, BulkOperationType.DeleteAffectedCases).subscribe(res => {
                expect(res).toBe(response);
                done();
            });
        });

        it('should return unable to complete notification when no records are deleted', (done) => {
            const response = { status: 'unableToComplete' };
            service.performBulkOperation = jest.fn().mockReturnValue(of(response));
            component.deleteAffectedCases(component._resultsGrid);
            service.performBulkOperation(123, null, null, false, null, BulkOperationType.DeleteAffectedCases).subscribe(res => {
                expect(res).toBe(response);
                done();
            });
        });
    });
    describe('clearAffectedCasesAgents', () => {
        beforeEach(() => {
            component._resultsGrid.getRowSelectionParams().isAllPageSelect = true;
            component._resultsGrid.getRowSelectionParams().allDeSelectedItems = [{ entryNo: 5 }, { entryNo: 6 }];
            ipxNotificationService.openConfirmationModal = jest.fn().mockReturnValue({ content: { confirmed$: of(true), cancelled$: of(true) } });
        });
        it('should return success notification when bulk clear agent success for all selected records', (done) => {
            const response = { status: 'success' };
            component.clearAffectedCaseAgent(component._resultsGrid);
            service.performBulkOperation = jest.fn().mockReturnValue(of(response));
            service.performBulkOperation(123, null, null, false, null, BulkOperationType.ClearAffectedCaseAgent).subscribe((res: any) => {
                expect(res).toBe(response);
                done();
            });
        });
        it('should return unable to complete notification when clear agent is not successful', (done) => {
            const response = { status: 'unableToComplete' };
            service.performBulkOperation = jest.fn().mockReturnValue(of(response));
            component.clearAffectedCaseAgent(component._resultsGrid);
            service.performBulkOperation(123, null, null, false, null, BulkOperationType.ClearAffectedCaseAgent).subscribe(res => {
                expect(res).toBe(response);
                done();
            });
        });
    });
});
