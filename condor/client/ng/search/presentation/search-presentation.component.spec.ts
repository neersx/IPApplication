import { async } from '@angular/core/testing';
import { AppContextServiceMock } from 'core/app-context.service.mock';
import { BehaviorSubjectMock, BsModalRefMock, CaseSearchServiceMock, ChangeDetectorRefMock, HttpClientMock, IpxGridOptionsMock, IpxNotificationServiceMock, KeyBoardShortCutService, NotificationServiceMock, Renderer2Mock, StateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { SearchOperator } from 'search/common/search-operators';
import { queryContextKeyEnum } from 'search/common/search-type-config.provider';
import { SaveOperationType, SaveSearchEntity } from 'search/savedsearch/saved-search.model';
import { Criteria, QueryData } from 'search/task-planner/task-planner.data';
import { TaskPlannerServiceMock } from 'search/task-planner/task-planner.service.mock';
import * as _ from 'underscore';
import { DueDateColumnsValidator } from './search-presentation-due-date.validator';
import { SearchPresentationComponent } from './search-presentation.component';
import { PresentationColumnView } from './search-presentation.model';
import { SearchPresentationService } from './search-presentation.service';

describe('SearchPresentationComponent', () => {
    let c: SearchPresentationComponent;
    let service: SearchPresentationService;
    const dueDateColumnValidator = new DueDateColumnsValidator();
    const keyBoardShortMock = new KeyBoardShortCutService();
    let httpMock: HttpClientMock;
    let diffMock: any;
    let differMock: any;
    const stateMock = new StateServiceMock();
    const notificationServiceMock = new NotificationServiceMock();
    const changeRefMock = new ChangeDetectorRefMock();
    const taskPlannerService = new TaskPlannerServiceMock();
    const notification = new IpxNotificationServiceMock();
    const rendererMock = new Renderer2Mock();
    const bsModalRefMock = new BsModalRefMock();
    const casesearchServiceMock = new CaseSearchServiceMock();
    let gridoptionsMock;
    let behaviorSubjectMock;
    const modalServiceMock = new ModalServiceMock();
    const e: any = { dataTransfer: {} };
    let availableColumns: Array<PresentationColumnView>;
    let selectedColumns: Array<PresentationColumnView>;
    let searchPersistenceServiceMock;
    let saveSearchServiceMock;
    let appContextServiceMock;

    beforeEach(() => {
        availableColumns = [
            { id: '9_C', parentId: null, columnKey: null, columnDescription: 'Column9', groupKey: 23, groupDescription: 'Group 23', displayName: 'Column9', isGroup: false, sortDirection: '', groupBySortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false },
            { id: '10_C', parentId: null, columnKey: 2, columnDescription: 'Column 10', groupKey: null, groupDescription: null, displayName: 'Column10', isGroup: false, sortDirection: '', groupBySortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false },
            { id: '11_C', parentId: null, columnKey: 3, columnDescription: 'Column 5', groupKey: null, groupDescription: null, displayName: 'Column5', isGroup: false, sortDirection: '', groupBySortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false },
            { id: '6_C', parentId: null, columnKey: 3, columnDescription: 'Column 6', groupKey: null, groupDescription: null, displayName: 'Column6', isGroup: false, sortDirection: '', groupBySortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false },
            { id: '7_C', parentId: null, columnKey: 3, columnDescription: 'Column 7', groupKey: null, groupDescription: null, displayName: 'Column7', isGroup: false, sortDirection: '', groupBySortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false },
            { id: '8_C', parentId: null, columnKey: 3, columnDescription: 'Column 8', groupKey: null, groupDescription: null, displayName: 'Column8', isGroup: false, sortDirection: '', groupBySortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false },
            { id: '-13_G', parentId: null, columnKey: 0, columnDescription: null, groupKey: -13, groupDescription: null, displayName: 'Column8', isGroup: false, sortDirection: '', groupBySortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false }
        ];

        selectedColumns = [
            { id: '11_C', isMandatory: false, parentId: null, columnKey: 3, columnDescription: 'Column 5', groupKey: null, groupDescription: null, displayName: 'Column5', isGroup: false, sortOrder: null, sortDirection: '', groupBySortOrder: null, groupBySortDirection: '', hidden: false, freezeColumn: true, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false },
            { id: '6_C', isMandatory: true, parentId: null, columnKey: 3, columnDescription: 'Column 6', groupKey: null, groupDescription: null, displayName: 'Column6', isGroup: false, sortOrder: 1, sortDirection: 'D', groupBySortOrder: null, groupBySortDirection: '', hidden: true, freezeColumn: true, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false },
            { id: '7_C', isMandatory: false, parentId: null, columnKey: 3, columnDescription: 'Column 7', groupKey: null, groupDescription: null, displayName: 'Column7', isGroup: false, sortOrder: 2, sortDirection: '', groupBySortOrder: null, groupBySortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false },
            { id: '8_C', isMandatory: false, parentId: null, columnKey: 3, columnDescription: 'Column 8', groupKey: null, groupDescription: null, displayName: 'Column8', isGroup: false, sortOrder: 3, sortDirection: '', groupBySortOrder: null, groupBySortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false }
        ];
        gridoptionsMock = new IpxGridOptionsMock();
        behaviorSubjectMock = new BehaviorSubjectMock();
        httpMock = new HttpClientMock();
        service = new SearchPresentationService(httpMock as any);
        searchPersistenceServiceMock = {
            getSearchPresentationData: jest.fn().mockReturnValue({
                selectedColumns,
                availableColumnsForSearch: availableColumns
            }),
            setSearchPresentationData: jest.fn()
        };
        saveSearchServiceMock = { update: jest.fn() };
        diffMock = { diff: jest.fn() };
        differMock = { find: jest.fn().mockReturnValue({ create: jest.fn().mockReturnValue(diffMock) }) };
        appContextServiceMock = new AppContextServiceMock();
        c = new SearchPresentationComponent(stateMock as any, rendererMock as any, service, changeRefMock as any, casesearchServiceMock as any, modalServiceMock as any, keyBoardShortMock as any, searchPersistenceServiceMock, dueDateColumnValidator as any, differMock, saveSearchServiceMock, notificationServiceMock as any, appContextServiceMock, taskPlannerService as any, notification as any);
        c.stateParams = { queryKey: 0, queryName: '', q: '1234', filter: {}, selectedColumns: [], levelUpState: '', isPublic: false, queryContextKey: null, activeTabSeq: 1 };
        e.dataTransfer.getData = jest.fn().mockReturnValue(JSON.stringify({ id: '7_C', parentId: null, columnKey: 3, columnDescription: 'Column 7', groupKey: null, groupDescription: null, displayName: 'Column7', isGroup: false, sortOrder: 2, sortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false }));
        c.taskPlannerViewData = {
            q: '',
            filter: {},
            isExternal: true,
            queryContext: 970,
            permissions: {},
            criteria: new Criteria(),
            query: new QueryData(),
            isPublic: true,
            maintainEventNotes: true,
            reminderDeleteButton: 1,
            timePeriods: [],
            maintainTaskPlannerSearch: true

        };
    });

    it('should create the component', async(() => {
        expect(c).toBeTruthy();
    }));

    it('Revert to default', async(() => {
        spyOn(service, 'revertToDefault').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
                expect(response.length).toEqual(1);
                c.userHasDefaultPresentation = false;
                c.gridOptions = gridoptionsMock;
                spyOn(gridoptionsMock, '_search').and.returnValue(selectedColumns);
                spyOn(c, 'reduce');
                spyOn(c, 'reloadPresentation');
                c.reloadPresentation();
            }
        });
        c.revertToDefault();
        expect(c.userHasDefaultPresentation).toEqual(false);
        expect(c.reloadPresentation).toHaveBeenCalled();
    }));

    it('make Default Presentation', async(() => {
        c.viewData = { filter: {}, queryKey: null, queryName: '', isExternal: false, queryContextKey: 0, importanceOptions: {}, isPublic: false };
        spyOn(service, 'makeMyDefaultPresentation').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
                expect(response.length).toEqual(1);
                c.userHasDefaultPresentation = true;
                c.gridOptions = gridoptionsMock;
                spyOn(gridoptionsMock, '_search').and.returnValue(selectedColumns);
                spyOn(c, 'reduce');
                spyOn(c, 'reloadPresentation');
                c.reloadPresentation();
            }
        });
        c.makeDefaultPresentation();
        expect(c.userHasDefaultPresentation).toEqual(true);
        expect(c.reloadPresentation).toHaveBeenCalled();
    }));

    it('check previous state', async(() => {
        c.stateParams = { queryKey: 0, queryName: '', q: null, filter: {}, selectedColumns: [], levelUpState: 'search-results', isPublic: false, queryContextKey: null, activeTabSeq: 1 };
        c.stateParams.levelUpState = 'search-results';

        spyOn(service, 'getAvailableColumns').and.returnValue([]);
        stateMock.params.queryKey = '';
        c.viewData = { filter: {}, queryKey: null, queryName: '', isExternal: false, queryContextKey: 0, importanceOptions: {}, isPublic: false };
        c.ngOnInit();
        expect(c.hasPreviousState).toBe(true);
        expect(c.availableColumns).not.toBeNull();
    }));

    it('check if available coulmns are filtered', async(() => {
        c.filterAvailableColumns(availableColumns, selectedColumns);

        expect(c.availableColumns).toBeDefined();
        expect(c.availableColumns.getValue().length).toBe(3);
        expect(_.first(c.availableColumns.getValue()).id).toBe('9_C');
        expect(_.last(c.availableColumns.getValue()).id).toBe('-13_G');
    }));

    it('check maintenanaceColumnSecurity login with external ', async(() => {
        c.isExternal = true;
        c.maintenanaceColumnSecurity();
        expect(c.canEditColumn).toEqual(false);
    }));

    it('check maintenanaceColumnSecurity login through internal with permission  ', async(() => {
        c.isExternal = false;
        c.canCreateSavedSearch = true;
        c.viewData = { filter: {}, queryKey: null, queryName: '', isExternal: false, queryContextKey: 0, importanceOptions: {}, canCreateSavedSearch: true, canUpdateSavedSearch: true, canMaintainPublicSearch: true, userHasDefaultPresentation: false, canDeleteSavedSearch: true, canMaintainColumns: true };
        c.maintenanaceColumnSecurity();
        expect(c.canEditColumn).toEqual(true);
    }));

    it('check maintenanaceColumnSecurity login through internal without permission  ', async(() => {
        c.isExternal = false;
        c.viewData = { filter: {}, queryKey: null, queryName: '', isExternal: false, queryContextKey: 0, importanceOptions: {}, canCreateSavedSearch: true, canUpdateSavedSearch: true, canMaintainPublicSearch: true, userHasDefaultPresentation: false, canDeleteSavedSearch: true, canMaintainColumns: false };
        c.maintenanaceColumnSecurity();
        expect(c.canEditColumn).toEqual(false);
    }));

    it('check columns sorting', async(() => {
        c.initializeOrder(5);

        expect(c.sortOrder.length).toBe(5);
    }));

    it('should return true if value matches', async(() => {
        const result = c.contains('Billing', 'Billing');
        expect(result).toEqual(true);
    }));

    it('should return matched item from array', async(() => {
        c.searchTerm = 'Column9';
        c.availableColumnsForSearch = availableColumns;
        const result = c.search();
        expect(result.length).toEqual(1);
    }));

    it('should referesh the default selected columns', async(() => {
        c.searchTerm = 'Column9';
        c.availableColumnsForSearch = availableColumns;
        const result = c.search();
        expect(result.length).toEqual(1);
    }));

    describe('drop item from tree view to grid view', () => {
        it('should create drop zone from tree view to kendo Grid', async(() => {
            c.viewData = { filter: {}, queryKey: null, queryName: '', isExternal: false, queryContextKey: 0, importanceOptions: {}, canCreateSavedSearch: true, canUpdateSavedSearch: true, canMaintainPublicSearch: true, userHasDefaultPresentation: false, canDeleteSavedSearch: true };
            c.availableColumns = behaviorSubjectMock;
            c.selectedColumns = selectedColumns;
            spyOn(behaviorSubjectMock, 'getValue').and.returnValue(availableColumns);
            const item: PresentationColumnView = { id: '16_C', parentId: null, columnKey: 3, procedureItemId: '', displaySequence: 2, columnDescription: 'Column 6', groupKey: null, groupDescription: null, displayName: 'Column6', isGroup: false, freezeColumn: false, sortDirection: '', groupBySortDirection: '', hidden: false, isDefault: false, isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false };
            spyOn(c, 'sortKendoTreeviewDataSet').and.returnValue(selectedColumns);
            c.ngOnInit();
            c.gridOptions = gridoptionsMock;
            spyOn(gridoptionsMock, '_search').and.returnValue(selectedColumns);
            spyOn(c, 'reduce');
            expect(c.selectedColumns[0].id).toBe('11_C');
            expect(c.selectedColumns[0].freezeColumn).toBe(true);
            c.dropItemFromTreeViewToGrid(item);

            expect(c.selectedColumns.length).toBe(5);
            expect(c.selectedColumns[0].id).toBe('16_C');
            expect(_.last(c.availableColumns.getValue()).id).toBe('-13_G');
        }));
    });

    describe('check if duedate is available', () => {
        beforeEach(() => {
            selectedColumns = [
                { id: '9_C', parentId: null, columnKey: null, columnDescription: 'Column9', groupKey: 23, groupDescription: 'Group 23', displayName: 'Column9', isGroup: false, sortDirection: '', groupBySortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false },
                { id: '10_C', parentId: null, columnKey: 2, columnDescription: 'Column 10', groupKey: -44, groupDescription: null, displayName: 'Column10', isGroup: false, sortDirection: '', groupBySortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false },
                { id: '11_C', parentId: null, columnKey: 3, columnDescription: 'Column 5', groupKey: -45, groupDescription: null, displayName: 'Column5', isGroup: false, sortDirection: '', groupBySortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false },
                { id: '-13_G', parentId: null, columnKey: 0, columnDescription: null, groupKey: -13, groupDescription: null, displayName: 'Column8', isGroup: false, sortDirection: '', groupBySortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false }
            ];

            c.dueDateFormData = {
                event: true,
                adhoc: false,
                searchByRemindDate: false,
                isRange: true,
                isPeriod: false,
                rangeType: 3,
                searchByDate: true,
                dueDatesOperator: null,
                periodType: null,
                fromPeriod: 1,
                toPeriod: 1,
                startDate: new Date(),
                endDate: new Date(),
                importanceLevelOperator: SearchOperator.equalTo,
                importanceLevelFrom: '1',
                importanceLevelTo: '10',
                eventOperator: SearchOperator.equalTo,
                eventValue: null,
                eventCategoryOperator: SearchOperator.equalTo,
                eventCategoryValue: null,
                actionOperator: SearchOperator.equalTo,
                actionValue: '',
                isRenevals: true,
                isNonRenevals: true,
                isClosedActions: true,
                isAnyName: true,
                isStaff: true,
                isSignatory: true,
                nameTypeOperator: SearchOperator.equalTo,
                nameTypeValue: '',
                nameOperator: SearchOperator.equalTo,
                nameValue: '',
                nameGroupOperator: SearchOperator.equalTo,
                nameGroupValue: null,
                staffClassificationOperator: SearchOperator.equalTo,
                staffClassificationValue: ''
            };
            c.viewData = { filter: {}, queryKey: null, queryName: '', isExternal: false, queryContextKey: 0, importanceOptions: {}, isPublic: false };

        });

        it('should open due date', async(() => {
            c.hasAllDateColumn = false;
            c.hasDueDateColumn = false;
            spyOn(modalServiceMock, 'openModal').and.returnValue(bsModalRefMock);
            c.openDueDate();
            expect(c.isDueDatePoupOpen).toBe(true);
        }));

        it('should open due date with filter as null', async(() => {
            c.viewData = { filter: null, queryKey: null, queryName: '', isExternal: false, queryContextKey: 0, importanceOptions: {}, isPublic: false };
            spyOn(modalServiceMock, 'openModal').and.returnValue(bsModalRefMock);
            spyOn(bsModalRefMock.content.searchRecord, 'subscribe');
            spyOn(service, 'getDueDateSavedSearch').and.returnValue({
                subscribe: (response: any) => {
                    expect(response).toBeDefined();
                }
            });
            c.openDueDate();
            expect(c.isDueDatePoupOpen).toBe(true);
        }));

        it('should check date columns', async(() => {
            c.hasAllDateColumn = false;
            c.hasDueDateColumn = false;

            const result = dueDateColumnValidator.validate(false, selectedColumns);
            expect(result.hasDueDateColumn).toBeTruthy();
            expect(result.hasAllDateColumn).toBeFalsy();
        }));
    });

    describe('edit column and goToMaintainColumns', () => {

        it('should call openModal method', () => {
            const column = {
                id: '-94_C',
                parentId: '-19_G',
                columnKey: -94,
                columnDescription: 'The attention name for the Agent of the case',
                groupKey: -19,
                groupDescription: null,
                displayName: 'Agent Attentions',
                isGroup: false,
                displaySequence: null,
                sortOrder: null,
                sortDirection: null,
                hidden: false,
                freezeColumn: false,
                isDefault: false,
                procedureItemId: 'NameAttention',
                groupBySortOrder: null,
                groupBySortDirection: null
            };
            const state = 'updating';
            c.openModal(column, state);
            expect(modalServiceMock.openModal).toBeCalled();
            expect(c.isAvailableColumnEdit).toEqual(true);
        });

        it('should call goToMaintainColumns method', () => {
            c.queryContextKey = 2;
            const spy = spyOn(window, 'open');
            c.goToMaintainColumns();
            expect(spy).toHaveBeenCalled();
        });

        it('should call refreshAvailableColumns method', () => {
            c.gridOptions = gridoptionsMock;
            spyOn(gridoptionsMock, '_search').and.returnValue([]);
            c.refreshAvailableColumns();
            expect(c.availableColumnsMultipleSelelction).toEqual([]);
        });
    });

    describe('drop item from grid view to tree view', () => {
        it('should create drop zone from Kendo Grid', async(() => {
            c.viewData = { filter: {}, queryKey: null, queryName: '', isExternal: false, queryContextKey: 0, importanceOptions: {}, isPublic: false };
            c.availableColumns = behaviorSubjectMock;
            c.selectedColumns = selectedColumns;
            spyOn(behaviorSubjectMock, 'getValue').and.returnValue(availableColumns);
            const item: PresentationColumnView = { id: '6_C', parentId: null, columnKey: 3, procedureItemId: '', displaySequence: 2, columnDescription: 'Column 6', groupDescription: '', groupKey: null, displayName: 'Column6', isGroup: false, freezeColumn: false, sortDirection: '', groupBySortDirection: '', hidden: false, isDefault: false, isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false };

            c.ngOnInit();
            c.gridOptions = gridoptionsMock;
            spyOn(gridoptionsMock, '_search').and.returnValue(selectedColumns);
            spyOn(c, 'reduce');
            c.dropItemFromGridToTreeView(item);
            expect(c.selectedColumns.length).toBe(3);
            expect(c.availableColumns.getValue()[0].id).toBe('6_C');
            expect(_.first(c.availableColumns.getValue()).id).toBe('6_C');
            expect(_.last(c.availableColumns.getValue()).id).toBe('-13_G');
        }));

        it('Drop item from kendoGrid to KendoTreeview when there is mandatory item in kendoGrid', async(() => {
            c.viewData = { filter: {}, queryKey: null, queryName: '', isExternal: false, queryContextKey: 0, importanceOptions: {}, isPublic: false };
            c.availableColumns = behaviorSubjectMock;
            c.selectedColumns = selectedColumns;
            spyOn(behaviorSubjectMock, 'getValue').and.returnValue(availableColumns);
            c.ngOnInit();
            c.gridOptions = gridoptionsMock;
            spyOn(gridoptionsMock, '_search').and.returnValue(selectedColumns);
            spyOn(c, 'reduce');
            c.dropItemFromGridToTreeView(c.selectedColumns[1]);
            expect(c.selectedColumns.length).toBe(4);
        }));
        it('Drop item from kendoGrid to KendoTreeview when there is not mandatory item in kendoGrid', async(() => {
            c.viewData = { filter: {}, queryKey: null, queryName: '', isExternal: false, queryContextKey: 0, importanceOptions: {}, isPublic: false };
            c.availableColumns = behaviorSubjectMock;
            c.selectedColumns = selectedColumns;
            spyOn(behaviorSubjectMock, 'getValue').and.returnValue(availableColumns);
            c.ngOnInit();
            c.gridOptions = gridoptionsMock;
            spyOn(gridoptionsMock, '_search').and.returnValue(selectedColumns);
            spyOn(c, 'reduce');
            c.dropItemFromGridToTreeView(c.selectedColumns[0]);
            expect(c.selectedColumns.length).toBe(3);
        }));
        it('should call makeMultiplerecordForKendoGrid drag with other then select record', async(() => {
            const itemlist = [
                {
                    id: '-8_C',
                    parentId: '-12_G',
                    columnKey: -8
                },
                {
                    id: '-6_C',
                    parentId: '-12_G',
                    columnKey: -6
                }
            ];
            c.droppedItem = {
                id: '-7_C',
                parentId: '-12_G',
                columnKey: -7
            };
            c.dropItemFromGridToTreeView = jest.fn();
            c.makeMultiplerecordForKendoGrid(itemlist);
            expect(c.dropItemFromGridToTreeView).toHaveBeenCalled();
            expect(c.selectedColumnsMultipleSelelction).toEqual([]);
            expect(itemlist.length).toEqual(3);
        }));

        it('should call makeMultiplerecordForKendoGrid drag with selected record', async(() => {
            const itemlist = [
                {
                    id: '-8_C',
                    parentId: '-12_G',
                    columnKey: -8
                },
                {
                    id: '-6_C',
                    parentId: '-12_G',
                    columnKey: -6
                }
            ];
            c.droppedItem = {
                id: '-6_C',
                parentId: '-12_G',
                columnKey: -6
            };
            c.dropItemFromGridToTreeView = jest.fn();
            c.makeMultiplerecordForKendoGrid(itemlist);
            expect(c.dropItemFromGridToTreeView).toHaveBeenCalled();
            expect(c.selectedColumnsMultipleSelelction).toEqual([]);
            expect(itemlist.length).toEqual(2);
        }));
    });

    describe('drop item from tree view to grid view', () => {
        it('should call handleMultiplerecordForTreeview drag with other then select record', async(() => {
            c.availableColumnsMultipleSelelction =
                [
                    '-93_C',
                    '-94_C'
                ];
            c.droppedItem = {
                id: '-92_C',
                parentId: '-12_G',
                columnKey: -7
            };
            c.availableColumnsForSearch = [{
                id: '-93_C',
                parentId: '-12_G',
                columnKey: -7
            }, {
                id: '-92_C',
                parentId: '-12_G',
                columnKey: -7
            }, {
                id: '-94_C',
                parentId: '-12_G',
                columnKey: -7
            }, {
                id: '-12_C',
                parentId: '-12_G',
                columnKey: -7
            }, {
                id: '-13_C',
                parentId: '-12_G',
                columnKey: -7
            }, {
                id: '-14_C',
                parentId: '-12_G',
                columnKey: -7
            }, {
                id: '-15_C',
                parentId: '-12_G',
                columnKey: -7
            }, {
                id: '-16_C',
                parentId: '-12_G',
                columnKey: -7
            }, {
                id: '-17_C',
                parentId: '-12_G',
                columnKey: -7
            }] as any;
            c.dropItemFromTreeViewToGrid = jest.fn();
            c.handleMultiplerecordForTreeview();
            expect(c.dropItemFromTreeViewToGrid).toHaveBeenCalled();
            expect(c.availableColumnsMultipleSelelction).toEqual([]);
            expect(c.availableColumnsMultipleSelelction.length).toEqual(0);
        }));
    });

    describe('onDefaultPresentationChanged', () => {
        it('should show default columns on default checkbox button checked', async(() => {
            c.useDefaultPresentation = true;
            c.gridOptions = gridoptionsMock;
            spyOn(gridoptionsMock, '_search').and.returnValue([]);
            c.onDefaultPresentationChanged();
            expect(c.queryKey).toBe(null);
            expect(c.getSelectedColumnsOnly).toBe(true);
            expect(c.copyPresentationQuery).toBe(null);
            expect(c.gridOptions._search).toBeCalled();
        }));

        it('should reset presentation query and getSelectedColumnsOnly when default checkbox button un-checked', async(() => {
            c.useDefaultPresentation = false;
            c.gridOptions = gridoptionsMock;
            spyOn(gridoptionsMock, '_search').and.returnValue([]);
            c.onDefaultPresentationChanged();
            expect(c.copyPresentationQuery).toBe(undefined);
            expect(c.getSelectedColumnsOnly).toBe(false);
        }));
    });

    describe('onSavedQueriesChanged', () => {
        it('should set queryKey when savedQuery is changed', async(() => {
            c.copyPresentationQuery = { key: 51, value: 'picklist value' };
            c.gridOptions = gridoptionsMock;
            c.useDefaultPresentation = false;
            spyOn(gridoptionsMock, '_search').and.returnValue(selectedColumns);
            c.onSavedQueriesChanged();
            expect(c.queryKey).toBe(c.copyPresentationQuery.key);
            expect(c.getSelectedColumnsOnly).toBe(true);
            expect(c.gridOptions._search).toBeCalled();
        }));

        it('should not check the useDefaultPresentation when savedQuery is set to blank', async(() => {
            c.copyPresentationQuery = null;
            c.gridOptions = gridoptionsMock;
            c.useDefaultPresentation = false;
            spyOn(gridoptionsMock, '_search').and.returnValue(selectedColumns);
            c.onSavedQueriesChanged();
            expect(c.queryKey).not.toBeDefined();
            expect(c.getSelectedColumnsOnly).toBe(false);
            expect(c.gridOptions._search).not.toBeCalled();
        }));
    });

    describe('Save As feature', () => {

        beforeEach(() => {
            c.viewData = { filter: {}, queryKey: null, queryName: '', isExternal: false, queryContextKey: 0, importanceOptions: {}, isPublic: true };
            c.useDefaultPresentation = true;
        });

        it('should call save as function', async(() => {
            spyOn(c, 'openSaveSearch');
            const filterData = c.viewData.filter;
            c.saveAs();
            expect(c.openSaveSearch).toBeCalledWith(filterData, null, SaveOperationType.SaveAs);

        }));

        it('should call make default presentation', async(() => {
            const saveSearchEntity: SaveSearchEntity = {
                searchFilter: c.viewData.filter,
                updatePresentation: true,
                selectedColumns: c.selectedColumnsData,
                queryContext: undefined
            };
            spyOn(service, 'makeMyDefaultPresentation').and.returnValue({
                subscribe: (response: any) => {
                    expect(response).toBeDefined();
                }
            });
            c.makeDefaultPresentation();
            expect(service.makeMyDefaultPresentation).toBeCalledWith(saveSearchEntity);
        }));

    });

    describe('removeOnChangeAction', () => {
        it('should clear onChangeAction and set isShowingHeader to true', () => {
            c.onChangeAction = () => null;
            c.isShowingHeader = false;

            c.removeOnChangeAction();

            expect(c.onChangeAction).toBeNull();
            expect(c.isShowingHeader).toBeTruthy();
        });
    });

    describe('ngDoCheck', () => {
        it('should do nothing if onChangeAction not set', () => {
            c.onChangeAction = null;
            c.triggerChangeAction = jest.fn();
            c.ngDoCheck();

            expect(c.triggerChangeAction).not.toHaveBeenCalled();
        });

        it('should trigger change action if onChangeAction set and diff returns false', () => {
            c.onChangeAction = jest.fn();
            c.triggerChangeAction = jest.fn();
            diffMock.diff.mockReturnValue(false);
            c.ngDoCheck();

            expect(c.triggerChangeAction).not.toHaveBeenCalled();
        });

        it('should trigger change action if onChangeAction set and diff returns true', () => {
            c.onChangeAction = jest.fn();
            c.triggerChangeAction = jest.fn();
            diffMock.diff.mockReturnValue(true);
            c.ngDoCheck();

            expect(c.triggerChangeAction).toHaveBeenCalled();
        });
    });

    describe('OrderChange', () => {

        beforeEach(() => {
            gridoptionsMock = new IpxGridOptionsMock();
            behaviorSubjectMock = new BehaviorSubjectMock();
            httpMock = new HttpClientMock();
            service = new SearchPresentationService(httpMock as any);
            c = new SearchPresentationComponent(stateMock as any, rendererMock as any, service, changeRefMock as any, casesearchServiceMock as any, modalServiceMock as any, keyBoardShortMock as any, searchPersistenceServiceMock, dueDateColumnValidator as any, { find: jest.fn().mockReturnValue({ create: jest.fn() }) } as any, saveSearchServiceMock, notificationServiceMock as any, appContextServiceMock, taskPlannerService as any, notification as any);
            c.stateParams = { queryKey: 0, queryName: '', q: null, filter: {}, selectedColumns: [], levelUpState: '', isPublic: false, queryContextKey: null, activeTabSeq: 1 };
            e.dataTransfer.getData = jest.fn().mockReturnValue(JSON.stringify({ id: '7_C', parentId: null, columnKey: 3, columnDescription: 'Column 7', groupKey: null, groupDescription: null, displayName: 'Column7', isGroup: false, sortOrder: 2, sortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false }));
        });

        it('should not change the sortOrder for rest of the selectedColumns if any of the higher index sortOrder is set to blank', async(() => {
            c.selectedColumns = selectedColumns;
            selectedColumns[1].sortOrder = 1;
            selectedColumns[3].sortOrder = null;
            c.resetSortOrder(e, selectedColumns[3], 'sortOrder');
            expect(c.selectedColumns[1].sortOrder).toEqual(1);
            expect(c.selectedColumns[2].sortOrder).toEqual(2);
            expect(c.selectedColumns[3].sortOrder).toEqual(null);
        }));

        it('should rearrange the next index sortOrder when any previous index sortOrder is set to higher value', async(() => {
            c.selectedColumns = selectedColumns;
            selectedColumns[3].sortOrder = 2;
            c.resetSortOrder(e, selectedColumns[3], 'sortOrder');
            expect(c.selectedColumns[1].sortOrder).toEqual(1);
            expect(c.selectedColumns[2].sortOrder).toEqual(3);
            expect(c.selectedColumns[3].sortOrder).toEqual(2);
        }));

        it('should set sortOrder to next ascending number if any other sortOrder is given', async(() => {
            c.selectedColumns = selectedColumns;
            selectedColumns[3].sortOrder = 8;
            c.resetSortOrder(e, selectedColumns[3], 'sortOrder');
            expect(c.selectedColumns[3].sortOrder).toEqual(3);
        }));

        it('should rearrange the sortOrder for rest of the selectedColumns if any of the lower index sortOrder is set to blank', async(() => {
            c.selectedColumns = selectedColumns;
            selectedColumns[1].sortOrder = null;
            c.resetSortOrder(e, selectedColumns[1], 'sortOrder');
            expect(c.selectedColumns[2].sortOrder).toEqual(1);
            expect(c.selectedColumns[3].sortOrder).toEqual(2);
        }));

        it('should rearrange the previous index sortOrder when any next index sortOrder is set to lower value', async(() => {
            c.selectedColumns = selectedColumns;
            selectedColumns[1].sortOrder = 1;
            selectedColumns[2].sortOrder = 1;
            c.resetSortOrder(e, selectedColumns[2], 'sortOrder');
            expect(c.selectedColumns[1].sortOrder).toEqual(2);
            expect(c.selectedColumns[2].sortOrder).toEqual(1);
            expect(c.selectedColumns[3].sortOrder).toEqual(3);
        }));

        it('should disable sortDirection & set hidden to false when sortOrder is not defined', async(() => {
            c.selectedColumns = selectedColumns;
            c.onOrderChange(e, selectedColumns[0], 'sortDirection', 'sortOrder');
            expect(c.selectedColumns[0].sortDirection).toEqual(null);
            expect(c.selectedColumns[0].hidden).toEqual(false);
            expect(c.selectedColumns[0].sortOrder).toEqual(null);
        }));

        it('should enable sortDirection when sortOrder is given', async(() => {
            spyOn(c, 'resetSortOrder');
            c.selectedColumns = selectedColumns;
            selectedColumns[1].sortDirection = 'D';
            c.onOrderChange(e, selectedColumns[1], 'sortDirection', 'sortOrder');
            expect(c.selectedColumns[1].sortDirection).toEqual('D');
            expect(c.resetSortOrder).toBeCalled();
        }));

        it('should set sortDirection to "A" when no sort direction is set and sortOrder is given', async(() => {
            spyOn(c, 'resetSortOrder');
            c.selectedColumns = selectedColumns;
            selectedColumns[1].sortDirection = '';
            c.onOrderChange(e, selectedColumns[1], 'sortDirection', 'sortOrder');
            expect(c.selectedColumns[1].sortDirection).toEqual('A');
            expect(c.resetSortOrder).toBeCalled();
        }));

        describe('onOrderClick', () => {
            it('should set the sort direction to none when no sortOrder is given', async(() => {
                _.each(selectedColumns, (sc: any) => {
                    sc.freezeColumn = false;
                });
                selectedColumns[1].sortOrder = null;
                c.selectedColumns = selectedColumns;

                c.onOrderClick(selectedColumns[1], 'A', 'sortDirection', 'sortOrder');
                expect(c.selectedColumns[1].sortDirection).toEqual('');
            }));

            it('should set the sort direction when sortOrder is given', async(() => {
                c.selectedColumns = selectedColumns;
                selectedColumns[1].sortOrder = 1;
                c.onOrderClick(selectedColumns[1], 'D', 'sortDirection', 'sortOrder');
                expect(c.selectedColumns[1].sortDirection).toEqual('D');
            }));
        });

        describe('manageFreezeColumn', () => {
            it('should enable freeze column when sortOrder is not defined & hidden is unchecked', async(() => {
                c.selectedColumns = selectedColumns;
                c.isGroupingAllowed = true;
                jest.spyOn(c, 'manageGroupingAccess');
                c.manageFreezeColumn(0);
                expect(c.selectedColumns[0].isFreezeColumnDisabled).toEqual(false);
                expect(c.manageGroupingAccess).toBeCalledWith(c.selectedColumns);
            }));

            it('should disable freeze column when sortOrder is defined and hidden is chekced', async(() => {
                c.selectedColumns = selectedColumns;
                c.selectedColumns[1].hidden = true;
                c.manageFreezeColumn(1);
                expect(c.selectedColumns[1].isFreezeColumnDisabled).toEqual(true);
                expect(c.selectedColumns[1].freezeColumn).toEqual(false);
            }));
        });

        describe('manageGroupByColumn', () => {
            it('should disable GroupBySortOrder column when hidden is checked', async(() => {
                c.selectedColumns = selectedColumns;
                c.selectedColumns[0].groupBySortOrder = 1;
                c.selectedColumns[0].groupBySortDirection = 'A';
                c.manageGroupByColumn(true, 0);
                expect(c.selectedColumns[0].isGroupBySortOrderDisabled).toEqual(true);
                expect(c.selectedColumns[0].groupBySortOrder).toEqual(null);
                expect(c.selectedColumns[0].groupBySortDirection).toEqual(null);
            }));

            it('should enable GroupBySortOrder column when hidden is unchecked', async(() => {
                c.selectedColumns = selectedColumns;
                c.selectedColumns[0].isGroupBySortOrderDisabled = true;
                c.manageGroupByColumn(false, 0);
                expect(c.selectedColumns[0].isGroupBySortOrderDisabled).toEqual(false);
            }));

            it('should disable grouping and freezing in selected columns', async(() => {
                c.selectedColumns = selectedColumns;
                c.isGroupingAllowed = false;
                c.manageGroupingAccess(c.selectedColumns);
                expect(c.selectedColumns[0].isFreezeColumnDisabled).toEqual(true);
                expect(c.selectedColumns[0].isGroupBySortOrderDisabled).toEqual(true);
            }));
        });
    });

    describe('TaskPlanner', () => {
        it('check previous state for taskPlannerSearchBuilder', async(() => {
            const formData = {
                general: {
                    belongingToFilter: { value: 'myself', actingAs: {} }
                },
                cases: {
                    caseFamily: { operator: '0', value: { key: 12, code: 'AA', value: 'Test' } }
                }
            };
            c.stateParams = { queryKey: 0, queryName: '', q: null, filter: { formData }, selectedColumns: [], levelUpState: 'taskPlanner', isPublic: false, queryContextKey: null, activeTabSeq: 1 };
            spyOn(service, 'getAvailableColumns').and.returnValue([]);
            stateMock.params.queryKey = '';
            c.viewData = { filter: {}, queryKey: null, queryName: '', isExternal: false, queryContextKey: queryContextKeyEnum.taskPlannerSearch, importanceOptions: {}, isPublic: false };
            c.ngOnInit();
            expect(c.hasPreviousState).toBe(true);
            expect(c.additionalStateParams.formData).toBe(formData);
            expect(c.levelUpTooltip).toEqual('taskPlanner.searchBuilder.backToTaskPlanner');
        }));

        it('validate initializeMenuItems', async(() => {
            c.queryContextKey = queryContextKeyEnum.taskPlannerSearch;
            c.viewData = { filter: {}, queryKey: null, queryName: '', isExternal: false, queryContextKey: queryContextKeyEnum.taskPlannerSearch, importanceOptions: {}, isPublic: false };
            c.initializeMenuItems();
            expect(c.menuItems.length).toEqual(5);
            expect(c.menuItems[0].id).toEqual('edit');
            expect(c.menuItems[1].id).toEqual('saveas');
            expect(c.menuItems[2].id).toEqual('default');
            expect(c.menuItems[3].id).toEqual('revert');
            expect(c.menuItems[4].id).toEqual('delete');

        }));

        it('validate executeSearch for taskPlanner', async(() => {
            c.queryContextKey = queryContextKeyEnum.taskPlannerSearch;
            const filterCriteria = { searchRequest: { dates: { useDueDate: 1, useReminderDate: 1 } } };
            const formData = {
                general: {
                    belongingToFilter: { value: 'myself', actingAs: {} }
                },
                cases: {
                    caseFamily: { operator: '0', value: { key: 12, code: 'AA', value: 'Test' } }
                }
            };
            c.stateParams = { queryKey: 0, queryName: '', q: null, filter: { formData, filterCriteria }, selectedColumns: [], levelUpState: 'taskPlannerSearchBuilder', isPublic: false, queryContextKey: null, activeTabSeq: 1 };

            c.activeTabSeq = 1;
            c.viewData = { filter: {}, queryKey: -31, queryName: '', isExternal: false, queryContextKey: queryContextKeyEnum.taskPlannerSearch, importanceOptions: {}, isPublic: false };
            c.queryName = 'Search1';
            c.executeSearch();
            expect(stateMock.go).toHaveBeenCalledWith('taskPlanner', { filterCriteria, formData, searchBuilder: true, selectedColumns: c.selectedColumns, activeTabSeq: 1, queryKey: -31, searchName: 'Search1', isSelectedColumnChange: false });
        }));

        it('validate editSearchCriteria for taskPlanner', async(() => {
            c.queryContextKey = queryContextKeyEnum.taskPlannerSearch;
            const filterCriteria = { searchRequest: { dates: { useDueDate: 1, useReminderDate: 1 } } };
            const formData = {
                general: {
                    belongingToFilter: { value: 'myself', actingAs: {} }
                },
                cases: {
                    caseFamily: { operator: '0', value: { key: 12, code: 'AA', value: 'Test' } }
                }
            };
            c.stateParams = { queryKey: 0, queryName: '', q: null, filter: { formData, filterCriteria }, selectedColumns: [], levelUpState: 'taskPlannerSearchBuilder', isPublic: false, queryContextKey: null, activeTabSeq: 1 };
            c.viewData = { filter: { formData, filterCriteria }, queryKey: null, queryName: '', isExternal: false, queryContextKey: queryContextKeyEnum.taskPlannerSearch, importanceOptions: {}, isPublic: false };

            c.activeTabSeq = 1;
            c.editSearchCriteria();
            expect(stateMock.go).toHaveBeenCalledWith('taskPlannerSearchBuilder', { queryKey: null, canEdit: false, filterCriteria, formData, selectedColumns: c.selectedColumns, activeTabSeq: 1 });
        }));

        it('validate hasTaskPlannerContext with taskPlannerSearch', async(() => {
            c.queryContextKey = queryContextKeyEnum.taskPlannerSearch;
            const result = c.hasTaskPlannerContext();
            expect(result).toBeTruthy();
        }));

        it('validate hasTaskPlannerContext with caseSearch', async(() => {
            c.queryContextKey = queryContextKeyEnum.caseSearch;
            const result = c.hasTaskPlannerContext();
            expect(result).toBeFalsy();
        }));

        it('build Selected Columns when search presentation is not from taskplanner', async(() => {
            c.queryContextKey = queryContextKeyEnum.nameSearch;
            const columns = c.buildSelectedColumns();
            expect(c.isTaskPlannerPresentation).toEqual(false);
            expect(columns.length).toEqual(7);
        }));

        it('build Selected Columns when search presentation is from taskplanner', async(() => {
            c.queryContextKey = queryContextKeyEnum.taskPlannerSearch;
            const columns = c.buildSelectedColumns();
            expect(c.isTaskPlannerPresentation).toEqual(true);
            expect(columns.length).toEqual(6);
        }));

        it('Should call editSavedSearchDetails', async(() => {
            c.queryContextKey = 970;
            c.useDefaultPresentation = true;
            c.viewData = { filter: { filterCriteria: { searchRequest: { one: true } } }, queryKey: null, queryName: '', isExternal: false, queryContextKey: 0, importanceOptions: {}, isPublic: false };
            c.editSavedSearchDetails();
            expect(modalServiceMock.openModal).toHaveBeenCalled();
        }));

        it('Should call disableEditSaveSearch when query key is not there', async(() => {
            c.queryContextKey = 970;
            c.useDefaultPresentation = true;
            const result = c.disableEditSaveSearch();
            expect(result).toEqual(true);
        }));

        it('Should call disableEditSaveSearch when query key is there and come from taskplanner', async(() => {
            c.queryContextKey = 970;
            c.queryKey = 31;
            c.useDefaultPresentation = true;
            const result = c.disableEditSaveSearch();
            expect(result).toEqual(false);
        }));

        it('Should call disableEditSaveSearch when query key is there and come from casesearch', async(() => {
            c.queryContextKey = 2;
            c.queryKey = 31;
            c.useDefaultPresentation = true;
            c.canMaintainPublicSearch = true;
            c.viewData = { filter: {}, queryKey: 31, queryName: '', isExternal: false, queryContextKey: 0, importanceOptions: {}, isPublic: true };
            const result = c.disableEditSaveSearch();
            expect(result).toEqual(false);
        }));

        it('Should call deleteSavedSearch', async(() => {
            c.deleteSavedSearch();
            expect(notificationServiceMock.confirmDelete).toHaveBeenCalled();
        }));

        it('Should call disableDeleteSaveSearch when query key is not there', async(() => {
            c.queryContextKey = 970;
            c.useDefaultPresentation = true;
            const result = c.disableDeleteSaveSearch();
            expect(result).toEqual(true);
        }));

        it('Should call disableDeleteSaveSearch when query key is there and come from taskplanner', async(() => {
            c.queryContextKey = 970;
            c.queryKey = 31;
            c.useDefaultPresentation = true;
            const result = c.disableDeleteSaveSearch();
            expect(result).toEqual(false);
        }));

        it('Should call disableDeleteSaveSearch when query key is there and come from casesearch', async(() => {
            c.queryContextKey = 2;
            c.queryKey = 31;
            c.useDefaultPresentation = true;
            c.canMaintainPublicSearch = true;
            c.viewData = { filter: {}, queryKey: 31, queryName: '', isExternal: false, queryContextKey: 0, importanceOptions: {}, isPublic: true };
            const result = c.disableDeleteSaveSearch();
            expect(result).toEqual(false);
        }));
    });
});
