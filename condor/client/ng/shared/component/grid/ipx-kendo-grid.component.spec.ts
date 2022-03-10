import { QueryList } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { ColumnReorderEvent, GridDataResult } from '@progress/kendo-angular-grid';
import { SortDescriptor } from '@progress/kendo-data-query';
import { ChangeDetectorRefMock, NgZoneMock, Renderer2Mock, TranslateServiceMock } from 'mocks';
import { EventEmitterMock } from 'mocks/event-emitter.mock';
import { IpxKendoGroupingServiceMock } from 'mocks/ipx-kendo-grouping.service.mock';
import { IpxGridDataBindingDirectiveMock } from './ipx-grid-data-binding.directive.mock';
import { GridHelper } from './ipx-grid-helper';
import { IpxGridOptions } from './ipx-grid-options';
import { IpxKendoGridComponent, rowStatus } from './ipx-kendo-grid.component';
import { EditTemplateColumnFieldDirective, TemplateColumnFieldDirective } from './ipx-template-column-field.directive';

describe('Angular Kendo Grid', () => {
    let grid: IpxKendoGridComponent;
    let gridHelper: GridHelper;
    const ipxGroupingService = new IpxKendoGroupingServiceMock();
    const zone = new NgZoneMock();
    let translateServiceMock: TranslateServiceMock;
    let changeRefMock: ChangeDetectorRefMock;
    const renderer = new Renderer2Mock();
    const selectAllService = { manageSelectDeSelect: jest.fn };
    beforeEach(() => {
        translateServiceMock = new TranslateServiceMock();
        gridHelper = new GridHelper();
        changeRefMock = new ChangeDetectorRefMock();
        grid = new IpxKendoGridComponent(zone as any, renderer as any, changeRefMock as any, translateServiceMock as any, selectAllService as any, ipxGroupingService as any);
        (grid.rowSelectionChanged as any) = new EventEmitterMock<Array<any>>();
        grid.templates = new QueryList<TemplateColumnFieldDirective>();
        grid.editTemplates = new QueryList<EditTemplateColumnFieldDirective>();
        grid.wrapper = jest.fn(() => ({ header: {} })) as any;
        grid.data = new IpxGridDataBindingDirectiveMock() as any;
        grid.wrapper.wrapper = { nativeElement: { querySelectorAll: jest.fn().mockReturnValue([]) } };
        grid.gridSelectionHelper.allSelectedItems = [];
        grid.gridSelectionHelper.rowSelection = [];
    });

    const initWithData = (gridOptions: IpxGridOptions): void => {
        grid.dataOptions = { columns: [], ...gridOptions };
        grid.ngOnInit();
    };

    const initWithGroupsData = (gridOptions: IpxGridOptions): void => {
        grid.dataOptions = {
            groups: [{
                dir: 'asc',
                field: 'casereference__77_.value'
            }], columns: [], ...gridOptions
        };
        grid.ngOnInit();
    };

    describe('Init', () => {
        it('init the default grid options', () => {
            initWithData({} as any);

            expect(grid.dataOptions._search).toBeDefined();
            expect(grid.dataOptions._selectPage).toBeDefined();
            expect(grid.dataOptions._selectRows).toBeDefined();
            expect(grid.pageSize).toBe(10);
            expect(grid.gridMessage).toBe('');
            expect(grid.dataOptions.autobind).toBe(true);
            expect(grid.dataOptions.rowClass).toBeDefined();
        });

        it('transforms the default grid options', () => {
            initWithData({
                filterable: true,
                sortable: false,
                autobind: false,
                canAdd: true,
                noResultsFoundMessage: 'No'
            } as any);

            expect(grid.dataOptions.filterable).toBe('menu');
            expect(grid.dataOptions.sortable).toEqual({
                mode: 'single'
            });
            expect(grid.dataOptions.autobind).toBe(false);
            expect(grid.itemName).toBe('grid.messages.defaultItemName');
            expect(grid.gridMessage).toBe('performSearchHint');
        });

        it('fixed column will be considered', () => {
            initWithData({
                filterable: true,
                sortable: false,
                autobind: false,
                reorderable: true,
                canAdd: true,
                noResultsFoundMessage: 'No',
                columns: [
                    { field: 'field1', fixed: true },
                    { field: 'field2', fixed: true },
                    { field: 'field3' }
                ]
            } as any);

            const event = new ColumnReorderEvent({ column: null, newIndex: 1, oldIndex: 2 });
            event.preventDefault = jest.fn();
            grid.onReorder(event);
            expect(event.preventDefault).toBeCalled();
        });

        it('anyColumnLocked should be return false if all columns are locked', () => {
            const gridOptions = {
                filterable: true,
                sortable: false,
                reorderable: true,
                canAdd: true,
                noResultsFoundMessage: 'No',
                columns: [
                    { field: 'field1', fixed: true, locked: true },
                    { field: 'field1', fixed: true, locked: true }
                ]
            } as any;

            grid.dataOptions = gridOptions;
            grid.ngAfterContentInit();
            expect(grid.anyColumnLocked).toBeFalsy();
        });

        it('anyColumnLocked should return true when atleast one column is lokced', () => {
            const gridOptions = {
                filterable: true,
                sortable: false,
                reorderable: true,
                canAdd: true,
                noResultsFoundMessage: 'No',
                columns: [
                    { field: 'field1', fixed: true, locked: true },
                    { field: 'field2', fixed: true, locked: false }
                ]
            } as any;

            grid.dataOptions = gridOptions;
            grid.ngAfterContentInit();
            expect(grid.anyColumnLocked).toBeTruthy();
        });

        it('sets autobind to false if page is selected by default', () => {
            initWithData({
                autobind: true,
                selectedRecords: { page: 2 }
            } as any);

            expect(grid.dataOptions.autobind).toBe(false);
            expect(grid.performActionsAfterViewInit.length).toBe(1);
        });

        it('sets row selection keys', () => {
            initWithData({
                selectedRecords: {
                    rows: {
                        rowKeyField: 'rowKeyColumn',
                        selectedKeys: [1, 2, 3, 4, 5, 6, 7]
                    }
                }
            } as any);
            expect(grid.dataOptions.selectable).toBe(true);
            expect(grid.gridSelectionHelper.rowSelectionKey).toBe('rowKeyColumn');
            expect(grid.gridSelectionHelper.rowSelection).toEqual([1, 2, 3, 4, 5, 6, 7]);
        });
    });

    describe('after view init', () => {
        const templateColumnFieldDirectiveMock = (template: string, field: string) => ({ key: field, template });

        it('sets column templates', () => {
            initWithData({
                columns: [
                    { template: 'TemplateRefObject1' },
                    { template: 'TemplateRefObject2' }
                ]
            } as any);

            grid.ngAfterViewInit();

            expect(grid.dataOptions.columns[0]._templateResolved).toBe('TemplateRefObject1');
            expect(grid.dataOptions.columns[1]._templateResolved).toBe('TemplateRefObject2');
        });

        it('resolves column templates', () => {
            initWithData({
                columns: [
                    { field: 'field1', template: true },
                    { template: 'TemplateRefObject2' }
                ]
            } as any);
            (grid.templates as any)._results = [templateColumnFieldDirectiveMock('TemplateRefObject1', 'field1')];

            grid.ngAfterViewInit();

            expect(grid.dataOptions.columns[0]._templateResolved).toBe('TemplateRefObject1');
            expect(grid.dataOptions.columns[1]._templateResolved).toBe('TemplateRefObject2');
        });

        it('performs scheduled actions', () => {
            initWithData({
                autobind: true,
                selectedRecords: { page: 2 },
                columns: []
            } as any);
            grid.wrapper.pageSize = (grid as any).pageSize;

            expect(grid.dataOptions.autobind).toBe(false);
            expect(grid.performActionsAfterViewInit.length).toBe(1);

            grid.ngAfterViewInit();

            expect(grid.wrapper.skip).toEqual(10);
            expect(grid.data.selectPage).toHaveBeenCalledWith(10);
        });
    });

    describe('rebuildColumnTemplates', () => {
        it('sets column templates', () => {
            initWithData({
                columns: [
                    { template: 'TemplateRefObject1' },
                    { template: 'TemplateRefObject2' }
                ]
            } as any);

            grid.ngAfterViewInit();
            gridHelper.rebuildColumnTemplates(grid.dataOptions, grid.templates, grid.editTemplates);

            expect(grid.dataOptions.columns[0]._templateResolved).toBe('TemplateRefObject1');
            expect(grid.dataOptions.columns[1]._templateResolved).toBe('TemplateRefObject2');
        });
    });

    describe('close editedRows', () => {
        it('close all rows of rowEditFormGroups ', () => {
            const options = { onDataBound: jest.fn() };
            grid.wrapper.closeRow = jest.fn();
            initWithData(options as any);
            grid.dataOptions.rowMaintenance = { rowEditKeyField: 'rowKey' };
            grid.rowEditFormGroups = { ['0']: new FormGroup({ rowKey: new FormControl('0') }) };

            grid.wrapper.data =
                [{ rowKey: 0 }, { rowKey: 1 }];

            grid.closeEditedRows(0);

            expect(grid.wrapper.closeRow).toHaveBeenCalledWith(0);
        });
    });

    describe('persist soft added/edited/deleted records', () => {
        it('should persist added records after grid rebind ', () => {
            const options = { onDataBound: jest.fn() };
            initWithData(options as any);
            grid.wrapper.closeRow = jest.fn();
            grid.wrapper.editRow = jest.fn();
            grid.wrapper.skip = 0;
            grid.dataOptions.rowMaintenance = { canEdit: true, canDelete: true, rowEditKeyField: 'rowKey' };
            grid.rowEditFormGroups = { ['3']: new FormGroup({ rowKey: new FormControl('3'), status: new FormControl(rowStatus.Adding) }) };
            grid.wrapper.data =
                [{ rowKey: '0', status: null }, { rowKey: '1', status: null }];

            grid.onDataBinding();

            expect(grid.wrapper.data.length).toEqual(3);
        });
        it('should persist edited/delted records after grid rebind ', () => {
            const options = { onDataBound: jest.fn() };
            initWithData(options as any);
            grid.wrapper.closeRow = jest.fn();
            grid.wrapper.editRow = jest.fn();
            grid.wrapper.skip = 0;
            grid.dataOptions.rowMaintenance = { canEdit: true, canDelete: true, rowEditKeyField: 'rowKey' };
            grid.rowEditFormGroups = { ['0']: new FormGroup({ rowKey: new FormControl('0'), status: new FormControl(rowStatus.deleting) }) };
            grid.wrapper.data =
                [{ rowKey: '0', status: null }, { rowKey: '1', status: null }];

            grid.onDataBinding();

            expect(grid.wrapper.data.length).toEqual(2);
            expect(grid.wrapper.data[0].status).toEqual(rowStatus.deleting);
        });
    });

    describe('data binding', () => {
        it('notifies event function of Grid options', () => {
            const options = { onDataBound: jest.fn() };
            initWithData(options as any);
            grid.wrapper.data = [1, 2];

            grid.onDataBinding();

            expect(options.onDataBound).toHaveBeenCalledWith([1, 2]);
        });

        it('sets paging to false if there is no data', () => {
            initWithData({ pageable: true } as any);
            grid.wrapper.pageable = true;
            grid.wrapper.data = [];
            grid.onDataBinding();

            expect(grid.wrapper.pageable).toBe(false);
        });

        it('shows no pagination control if data is available on single page', () => {
            initWithData({ pageable: true } as any);
            grid.wrapper.pageable = true;
            grid.wrapper.data = { data: [1, 2], total: 2 };
            grid.onDataBinding();

            expect(grid.wrapper.pageable).toEqual(false);
        });

        it('shows default paging if there is data and option set', () => {
            initWithData({ pageable: { pageSize: 5 } } as any);
            grid.wrapper.pageable = true;
            grid.wrapper.data = { data: [1, 2, 3, 4, 5, 6], total: 6 };
            grid.onDataBinding();

            expect(grid.wrapper.pageable).toEqual({
                type: 'numeric',
                pageSize: 5,
                pageSizes: [10, 20, 50, 100],
                previousNext: true,
                buttonCount: 5
            });
        });

        it('clears row selection on second data load if not persist selection', () => {
            initWithData({
                selectedRecords: {
                    rows: {
                        rowKeyField: 'rowKeyColumn',
                        selectedKeys: [1, 2, 3, 4, 5, 6, 7]
                    }
                }
            } as any);
            grid.wrapper.data = [];
            grid.onDataBinding();
            expect(grid.gridSelectionHelper.rowSelectionKey).toBe('rowKeyColumn');
            expect(grid.gridSelectionHelper.rowSelection).toEqual([1, 2, 3, 4, 5, 6, 7]);

            grid.onDataBinding();
            expect(grid.gridSelectionHelper.rowSelectionKey).toBe('rowKeyColumn');
            expect(grid.gridSelectionHelper.rowSelection).toEqual([]);
        });

        it('does not clears row selection on second data load if not persist selection', () => {
            initWithData({
                selectedRecords: {
                    rows: {
                        rowKeyField: 'rowKeyColumn',
                        selectedKeys: [1, 2, 3, 4, 5, 6, 7]
                    }
                },
                persistSelection: true
            } as any);
            grid.wrapper.data = [];
            grid.onDataBinding();
            expect(grid.gridSelectionHelper.rowSelectionKey).toBe('rowKeyColumn');
            expect(grid.gridSelectionHelper.rowSelection).toEqual([1, 2, 3, 4, 5, 6, 7]);

            grid.onDataBinding();
            expect(grid.gridSelectionHelper.rowSelectionKey).toBe('rowKeyColumn');
            expect(grid.gridSelectionHelper.rowSelection).toEqual([1, 2, 3, 4, 5, 6, 7]);
        });

        it('sets the no record message if there is no data', () => {

            initWithData({ gridMessages: { noResultsFound: 'No' } } as any);
            grid.wrapper.data = [1, 2];
            grid.onDataBinding();
            expect(grid.gridMessage).toBe('');

            grid.wrapper.data = [];
            grid.onDataBinding();
            expect(grid.gridMessage).toBe('No');
        });
        it('sets isSelectAll value based on records selected', () => {
            initWithData({
                pageSize: 3,
                selectedRecords: {
                    rows: {
                        rowKeyField: 'id',
                        selectedKeys: [1, 2, 3]
                    }
                },
                persistSelection: true
            } as any);
            grid.wrapper.data = [{ id: 1, selected: true }, { id: 2, selected: true }, { id: 3, selected: true }];

            grid.onDataBinding();
            expect(grid.gridSelectionHelper.isSelectAll).toBe(true);

            grid.wrapper.data = [{ id: 4, selected: false }, { id: 5, selected: false }, { id: 6, selected: false }];
            grid.onDataBinding();
            expect(grid.gridSelectionHelper.isSelectAll).toBe(false);
        });

        it('sets the no record message if there is no data', () => {

            initWithData({ gridMessages: { noResultsFound: 'No' } } as any);
            grid.wrapper.data = [1, 2];
            grid.onDataBinding();
            expect(grid.gridMessage).toBe('');

            grid.wrapper.data = [];
            grid.onDataBinding();
            expect(grid.gridMessage).toBe('No');
        });
        it('can clear the data', () => {
            initWithData({ noResultsFoundMessage: 'No' } as any);
            grid.wrapper.data = [1, 2];
            grid.onDataBinding();

            grid.clear();
            expect(grid.data.clear).toHaveBeenCalled();
            expect(grid.gridMessage).toBe('performSearchHint');
        });
        it('should have brand new search', () => {
            initWithData({ noResultsFoundMessage: 'No' } as any);
            grid.search();

            expect(grid.wrapper.skip).toBe(0);
            expect(grid.data.selectPage).toHaveBeenCalledWith(0);
        });
    });

    describe('row selection functions', () => {
        it('should return value based on rowSelection', () => {
            let retValue = grid.hasItemsSelected();
            expect(retValue).toBeFalsy();

            grid.gridSelectionHelper.rowSelection = [{ key: 1 }, { key: 2 }];
            retValue = grid.hasItemsSelected();
            expect(retValue).toBeTruthy();
        });

        it('should return selectedItems', () => {
            grid.gridSelectionHelper.allSelectedItems = [{ key: 1 }, { key: 2 }];
            let data = grid.getSelectedItems('key');
            expect(data).toEqual([1, 2]);

            grid.gridSelectionHelper.allSelectedItems = [];
            grid.gridSelectionHelper.allSelectedIds = [3, 4];
            data = grid.getSelectedItems('key');
            expect(data).toEqual([3, 4]);
        });

        it('should call resetSelection', () => {
            grid.gridSelectionHelper.resetSelection = jest.fn();
            grid.resetSelection();
            expect(grid.gridSelectionHelper.resetSelection).toHaveBeenCalled();
        });
    });

    describe('toggleSelectAll', () => {
        beforeEach(() => {
            initWithData({ selectable: { mode: 'multiple', enabled: true } } as any);
            grid.wrapper.data = [1, 2, 3, 4, 5].map(val => ({ val }));
        });
        it('select all rows when selectall checkbox is checked', () => {
            grid.gridSelectionHelper.isSelectAll = true;
            grid.gridSelectionHelper.allSelectedItems = [];
            grid.toggleSelectAll();
            expect(grid.gridSelectionHelper.rowSelection.length).toEqual(5);
        });
        it('deselect all rows when selectall checkbox is unchecked', () => {
            grid.gridSelectionHelper.isSelectAll = false;
            grid.gridSelectionHelper.allSelectedItems = [];
            grid.toggleSelectAll();
            expect(grid.gridSelectionHelper.rowSelection.length).toEqual(0);
        });
    });

    describe('aggregation on group', () => {
        beforeEach(() => {
            initWithData({ selectable: { mode: 'multiple', enabled: true } } as any);
        });
        it('check for context menu and isShowTemplateForGroup', () => {
            const groups: any = [{ field: 'column1' }];
            grid.gridSelectionHelper.allSelectedItems = [];
            expect(groups[0].aggregates).not.toBeDefined();
            grid.groupChange(groups);
            expect(grid.showContextMenu).toEqual(false);
            expect(grid.isShowTemplateForGroup).toEqual(true);
        });
    });

    describe('cell click', () => {
        beforeEach(() => {
            initWithData({ selectable: { mode: 'multiple', enabled: true } } as any);
            grid.wrapper.data = [{ id: 1, text: 'abc' }];
            grid.gridSelectionHelper.rowSelection = [0];
            grid.gridSelectionHelper.allSelectedItems = [];
        });
        it('change selected item on cell click', () => {
            grid.autoApplySelection = true;
            grid.dataItemClicked.emit = jest.fn();
            jest.spyOn(grid, 'checkChanged');
            const originalEvent = { preventDefault: jest.fn() };
            const dataItem = { id: 487, name: 'abc', selected: false };
            const sender = { type: '' };
            grid.onCellClick({ sender, dataItem, originalEvent, rowIndex: 0, columnIndex: 0, isEdited: false });
            expect(grid.checkChanged).toHaveBeenCalled();
            expect(dataItem.selected).toBeTruthy();
        });

    });

    describe('column reordering', () => {
        it('prevents reordering on fixed columns', () => {
            const columns = [
                { field: 'field0', title: '', fixed: true },
                { field: 'field1', title: 'field-1', fixed: true },
                { field: 'field2', title: 'field-2' },
                { field: 'field3', title: 'field-3', hidden: true },
                { field: 'field4', title: 'field-4' }
            ];
            const moved = new ColumnReorderEvent({ column: { field: 'field4', title: 'field-4' }, oldIndex: 3, newIndex: 0 });
            initWithData({
                columns,
                columnSelection: {
                    localSetting: {
                        getLocal: null,
                        setLocal: jest.fn()
                    }
                }
            } as any);
            moved.preventDefault = jest.fn();
            grid.onReorder(moved);
            expect(moved.preventDefault).toHaveBeenCalled();
            expect(grid.dataOptions.columnSelection.localSetting.setLocal).toHaveBeenCalledTimes(0);
        });

        it('preview should be empty when sorting or filtering data', () => {
            initWithData({ selectable: false } as any);
            grid.showPreview = true;
            grid.wrapper.data = [1, 2];
            grid.dataItemClicked.emit = jest.fn();
            grid.wrapper.wrapper = { nativeElement: { querySelectorAll: jest.fn().mockReturnValue([1, 2]) } };
            grid.onDataBinding();
            expect(grid.dataItemClicked.emit).toHaveBeenCalledWith({ caseKey: null, rowKey: -1 });
        });

        it('saves the new order to local storage', () => {
            const columns = [
                { field: 'field0', title: '', fixed: true },
                { field: 'field1', title: 'field-1', fixed: true },
                { field: 'field2', title: 'field-2' },
                { field: 'field3', title: 'field-3', hidden: true },
                { field: 'field4', title: 'field-4' }
            ];
            const moved = { column: { field: 'field4', title: 'field-4' }, oldIndex: 4, newIndex: 2 };
            initWithData({
                columns,
                columnSelection: {
                    localSetting: {
                        getLocal: null,
                        setLocal: jest.fn()
                    }
                }
            } as any);
            grid.onReorder(new ColumnReorderEvent(moved));
            expect(grid.dataOptions.columnSelection.localSetting.setLocal).toHaveBeenCalledWith([
                { field: 'field0', hidden: false, index: 0 },
                { field: 'field1', hidden: false, index: 1 },
                { field: 'field4', hidden: false, index: 2 },
                { field: 'field2', hidden: false, index: 3 },
                { field: 'field3', hidden: true, index: 4 }
            ]);
        });

        it('calibrate new columns order from storage', () => {
            const columns = [
                { field: 'field0', title: '', fixed: true },
                { field: 'field1', title: 'field-1', fixed: true },
                { field: 'field2', title: 'field-2' },
                { field: 'field3', title: 'field-3', hidden: true },
                { field: 'field4', title: 'field-4' }
            ];
            const stored = [
                { field: 'field1', title: 'field-1', index: 0 },
                { field: 'field4', title: 'field-4', index: 1 },
                { field: 'field3', title: 'field-3', hidden: true, index: 2 },
                { field: 'field2', title: 'field-2', index: 3 }
            ];
            initWithData({
                columns,
                columnSelection: {
                    localSetting: {
                        getLocal: stored,
                        setLocal: jest.fn()
                    }
                }
            } as any);
            expect(grid.dataOptions.columns).toEqual([
                { field: 'field0', title: '', fixed: true },
                { field: 'field1', title: 'field-1', fixed: true },
                { field: 'field4', title: 'field-4' },
                { field: 'field3', title: 'field-3', hidden: true },
                { field: 'field2', title: 'field-2' }
            ]);
        });

        it('works off the new order in local storage', () => {
            const columns = [
                { field: 'field0', title: '', fixed: true },
                { field: 'field1', title: 'field-1', fixed: true },
                { field: 'field2', title: 'field-2' },
                { field: 'field3', title: 'field-3', hidden: true },
                { field: 'field4', title: 'field-4' }
            ];
            const stored = [
                { field: 'field1', title: 'field-1', index: 0 },
                { field: 'field4', title: 'field-4', index: 1 },
                { field: 'field3', title: 'field-3', hidden: true, index: 2 },
                { field: 'field2', title: 'field-2', index: 3 }
            ];
            initWithData({
                columns,
                columnSelection: {
                    localSetting: {
                        getLocal: stored,
                        setLocal: jest.fn()
                    }
                }
            } as any);
            const moved = { column: { field: 'field4', title: 'field-4' }, oldIndex: 1, newIndex: 2 };
            grid.onReorder(new ColumnReorderEvent(moved));
            expect(grid.dataOptions.columnSelection.localSetting.setLocal).toHaveBeenCalledWith([
                { field: 'field0', hidden: false, index: 0 },
                { field: 'field1', hidden: false, index: 1 },
                { field: 'field4', hidden: false, index: 2 },
                { field: 'field3', hidden: true, index: 3 },
                { field: 'field2', hidden: false, index: 4 }
            ]);
        });
    });

    describe('Edit row', () => {
        it('should call the grid\'s editRow function on edit', () => {
            const rowIdx = 2;
            initWithData({} as any);
            grid.dataOptions.createFormGroup = jest.fn();
            const editRowSpy = grid.wrapper.editRow = jest.fn();
            const expandRowSpy = grid.wrapper.expandRow = jest.fn();
            grid.editRowAndDetails(rowIdx, null, true);
            expect(editRowSpy).toHaveBeenCalledWith(rowIdx, undefined);
            expect(expandRowSpy).toHaveBeenCalledWith(rowIdx);
        });
    });

    describe('Context Menu', () => {
        it('should assign grid\'s taskMenuDataItem when context menu is shown', () => {
            initWithData({} as any);
            grid.dataOptions.createFormGroup = jest.fn();
            grid.popupOpen.emit = jest.fn();
            const dataItem = { id: 487, name: 'abnc', isEditable: true };
            grid.showMenu(null, dataItem, 1);
            expect(grid.taskMenuDataItem).toEqual({ ...{ _rowIndex: 1 }, ...dataItem });
            expect(grid.popupOpen.emit).toHaveBeenCalled();
        });

        it('should emit the menuItemSelected event on selecting a menu item', () => {
            initWithData({} as any);
            grid.dataOptions.createFormGroup = jest.fn();
            const a = [1, 2]; // : MenuEvent = {sender: null, item: 1, index: '1', isDefaultPrevented: () => false, preventDefault: null};
            grid.menuItemSelected.subscribe((res: any) => {
                expect(res.event).toEqual(a);
            });
            grid.onMenuItemSelected(a as any);
        });
        it('should emit the correct  menu items', () => {
            initWithData({} as any);
            grid.dataOptions.createFormGroup = jest.fn();
            grid.rowMaintenance = {
                canEdit: true, inline: true, hideButtons: true,
                rowEditKeyField: 'eventCompositeKey'

            } as any;
            const dataItem = { id: 111 };

            const items = grid.getRowMaintenanceMenuItems(dataItem) as any;
            expect(items).not.toBeNull();
            expect(items.length).toBe(1);
            expect(items[0].icon).toEqual('cpa-icon cpa-icon-pencil-square-o');
            expect(items[0].rowMaintenanceItem).toBe(true);
            expect(items[0].text).toBe('Edit');
        });
    });

    describe('manual operations', () => {
        it('should have call one time bind on search', () => {
            initWithData({ noResultsFoundMessage: 'No', manualOperations: true } as any);
            grid.search();

            expect(grid.data.bindOneTimeData).toHaveBeenCalledWith();
        });
    });

    describe('expand/collapse operations', () => {
        it('should call expand row with specified rowindex', () => {
            const rowIdx = 1;
            initWithData({} as any);
            const expandRowSpy = grid.wrapper.expandRow = jest.fn();
            grid.expandAll(rowIdx);

            expect(expandRowSpy).toHaveBeenCalledWith(1);
        });

        it('should call expand row for all rowindexes', () => {
            initWithData({} as any);
            grid.wrapper.data = [1, 2];
            grid.wrapper.skip = 0;
            jest.spyOn(grid, 'getCurrentData').mockReturnValueOnce([1, 2]);
            const expandRowSpy = grid.wrapper.expandRow = jest.fn();
            grid.expandAll(null);

            expect(expandRowSpy).toHaveBeenCalledWith(0);
            expect(expandRowSpy).toHaveBeenCalledWith(1);
        });

        it('should call collapse row with specified rowindex', () => {
            const rowIdx = 1;
            initWithData({} as any);
            const collapseRowSpy = grid.wrapper.collapseRow = jest.fn();
            grid.collapseAll(rowIdx);

            expect(collapseRowSpy).toHaveBeenCalledWith(1);
        });

        it('should call collapse row for all rowindexes', () => {
            initWithData({} as any);
            grid.wrapper.data = [1, 2];
            grid.wrapper.skip = 0;
            jest.spyOn(grid, 'getCurrentData').mockReturnValueOnce([1, 2]);
            const collapseRowSpy = grid.wrapper.collapseRow = jest.fn();
            grid.collapseAll(null);

            expect(collapseRowSpy).toHaveBeenCalledWith(0);
            expect(collapseRowSpy).toHaveBeenCalledWith(1);
        });
    });

    describe('maintenance operations', () => {
        const createFromGroupFunc = () => { return new FormGroup({}); };
        beforeEach(() => {
            initWithData({ rowMaintenance: { rowEditKeyField: 'field' }, createFormGroup: createFromGroupFunc } as any);
        });
        it('should return valid or not ', () => {
            grid.rowEditFormGroups = { ['1001']: new FormGroup({ first: new FormControl('') }) };
            expect(grid.isValid()).toBeTruthy();
            grid.rowEditFormGroups['1001'].setErrors({ error: 'error' });
            expect(grid.isValid()).toBeFalsy();
        });
        it('should handle row edit ', () => {
            jest.spyOn(grid.dataOptions, 'createFormGroup');
            grid.wrapper.data =
                [{ rowKey: 0 }, { rowKey: 1 }];
            grid.wrapper.editRow = jest.fn().mockReturnValue([11, { field: '100', status: 'E' }]);
            const dataItem = { field: '100', status: 'E' };
            grid.rowEditHandler(null, 11, dataItem);
            expect(grid.rowEditFormGroups).not.toBeNull();
        });
        it('should handle row edit cancel ', () => {
            grid.wrapper.closeRow = jest.fn();
            grid.wrapper.data =
                [{ rowKey: 0 }, { rowKey: 1 }];
            const dataItem = { field: '100' };
            grid.rowEditFormGroups = { ['100']: new FormGroup({}) };
            grid.rowCancelHandler(null, 11, dataItem);
            expect(grid.rowEditFormGroups).not.toBeNull();
            expect(grid.wrapper.closeRow).toHaveBeenCalledWith(11);
        });
    });

    describe('task menu event', () => {
        it('validate markActive', () => {
            const task = { id: 'editCase', text: 'EditCase', items: [] };
            const subTask = { id: 'editCaseDetail', parent: task, text: 'Maintain Case Details' };
            task.items.push(subTask);
            grid.activeTaskMenuItems = [];
            grid.markActive(subTask);
            expect(grid.activeTaskMenuItems.length).toEqual(2);
            expect(grid.activeTaskMenuItems[0]).toEqual(subTask.id);
            expect(grid.activeTaskMenuItems[1]).toEqual(task.id);
        });

        it('validate isTaskItemActive', () => {
            const task = { id: 'editCase', text: 'EditCase', items: [] };
            const subTask = { id: 'editCaseDetail', parent: task, text: 'Maintain Case Details' };
            task.items.push(subTask);
            grid.activeTaskMenuItems = [];
            grid.markActive(task);
            const taskResult = grid.isTaskItemActive(task.id);
            expect(taskResult).toBeTruthy();
            const subTaskResult = grid.isTaskItemActive(subTask.id);
            expect(subTaskResult).toBeFalsy();
        });
    });

    describe('refresh grid', () => {
        it('refresh when group is not store', () => {
            initWithData({} as any);
            expect(grid.dataOptions._refresh).toBeDefined();
            grid.data.refreshGrid = jest.fn();
            grid.gridSelectionHelper.resetSelection = jest.fn();
            grid.wrapper.data =
                [{ rowKey: '0', status: null }, { rowKey: '1', status: null }];
            grid.refresh();
            expect(grid.dataOptions.groups).toEqual([]);
            expect(grid.data.refreshGrid).toHaveBeenCalled();
            expect(grid.gridSelectionHelper.resetSelection).toBeCalled();
        });

        it('refresh when group is store', () => {
            initWithData({} as any);
            expect(grid.dataOptions._refresh).toBeDefined();
            grid.data.refreshGrid = jest.fn();
            grid.wrapper.data =
                [{ rowKey: '0', status: null }, { rowKey: '1', status: null }];
            grid.storeGroupsForRefresh = [{
                dir: 'asc',
                field: 'casereference__77_.value'
            }];
            grid.gridSelectionHelper.resetSelection = jest.fn();
            grid.refresh();
            expect(grid.dataOptions.groups).toEqual(grid.storeGroupsForRefresh);
            expect(grid.data.refreshGrid).toHaveBeenCalled();
            expect(grid.gridSelectionHelper.resetSelection).toBeCalled();
        });

        it('restore Saved Group On Refresh when there stored groups', () => {
            initWithGroupsData({} as any);
            grid.restoreSavedGroupOnRefresh();
            expect(grid.storeGroupsForRefresh).toEqual(grid.dataOptions.groups);
        });
        it('restore Saved Group On Refresh when there not stored groups', () => {
            initWithGroupsData({} as any);
            grid.storeGroupsForRefresh = [{
                dir: 'asc',
                field: 'casereference__77_.value'
            }];
            grid.restoreSavedGroupOnRefresh();
            expect(grid.storeGroupsForRefresh).toEqual(grid.dataOptions.groups);
        });
    });
    describe('select de-select rows', () => {
        it('should call gridSelection selectAll', () => {
            grid.gridSelectionHelper.selectAllPage = jest.fn();
            grid.gridSelectionHelper.checkChanged = jest.fn();
            grid.selectAllPage();
            expect(grid.gridSelectionHelper.selectAllPage).toBeCalled();
            expect(grid.gridSelectionHelper.checkChanged).toBeCalled();
        });
        it('should clear selection', () => {
            initWithData({} as any);
            grid.gridSelectionHelper.deselectAllPage = jest.fn();
            grid.gridSelectionHelper.checkChanged = jest.fn();
            grid.clearSelection();
            expect(grid.gridSelectionHelper.deselectAllPage).toBeCalled();
            expect(grid.gridSelectionHelper.checkChanged).toBeCalled();
        });
    });

    it('should call childRecordForGrouping when expand', () => {
        initWithData({} as any);
        const childItem = { index: 0, dataItem: { items: [] } };
        grid.dataOptions.groups = [
            {
                field: 'propertytypedescription__8_',
                aggregates: [
                    {
                        field: 'propertytypedescription__8_',
                        aggregate: 'count'
                    }
                ]
            },
            {
                field: 'countryname__7_',
                aggregates: [
                    {
                        field: 'countryname__7_',
                        aggregate: 'count'
                    }
                ]
            }
        ];

        grid.applyGrouping(childItem);
        expect(childItem.dataItem.items.length).toEqual(1);
    });

    it('call detailExpand to check onDetailExpand propert is emited', () => {
        initWithData({} as any);
        const event = { index: 0, dataItem: { items: [] } };
        grid.dataOptions.groups = [
            {
                field: 'propertytypedescription__8_',
                aggregates: [
                    {
                        field: 'propertytypedescription__8_',
                        aggregate: 'count'
                    }
                ]
            },
            {
                field: 'countryname__7_',
                aggregates: [
                    {
                        field: 'countryname__7_',
                        aggregate: 'count'
                    }
                ]
            }
        ];
        grid.detailExpand(event);
        grid.menuItemSelected.subscribe((res: any) => {
            expect(res.event).toBeDefined();
        });
        expect(grid.onDetailExpand).toBeDefined();
    });

    describe('onSort', () => {
        it('should do manual sort when flag is on', () => {
            initWithData({} as any);
            grid.dataOptions.manualOperations = true;
            grid.wrapper.data = [{ rowKey: '0', status: 'a' }, { rowKey: '1', status: 'b' }];
            const sorting = new Array<SortDescriptor>();
            sorting.push({dir: 'desc', field: 'status'});
            grid.onSort(sorting);

            expect(grid.wrapper.data[0].status).toEqual('b');
            expect(grid.wrapper.data[0].rowKey).toEqual('1');
            expect(grid.wrapper.data[1].status).toEqual('a');
            expect(grid.wrapper.data[1].rowKey).toEqual('0');
        });

        it('should also handle sort when its a paged result', () => {
            initWithData({} as any);
            grid.dataOptions.manualOperations = true;
            grid.allItems = [{ rowKey: '0', status: 'a' }, { rowKey: '1', status: 'b' }, { rowKey: '2', status: 'c' }, { rowKey: '3', status: 'd' }, { rowKey: '4', status: 'e' }, { rowKey: '5', status: 'f' }];
            const gridResult: GridDataResult = { data: grid.allItems, total: grid.allItems.length };
            grid.wrapper.data = gridResult;
            const sorting = new Array<SortDescriptor>();
            sorting.push({dir: 'desc', field: 'status'});
            grid.wrapper.skip = 0;
            grid.wrapper.pageSize = 5;
            grid.onSort(sorting);

            expect(grid.wrapper.data.data[0].status).toEqual('f');
            expect(grid.wrapper.data.data[0].rowKey).toEqual('5');
            expect(grid.wrapper.data.data[4].status).toEqual('b');
            expect(grid.wrapper.data.data[4].rowKey).toEqual('1');
        });
    });
});