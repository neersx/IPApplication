import { EventEmitterMock } from 'mocks/event-emitter.mock';
import { GridSelectionHelper } from './ipx-grid-selection-helper';
describe('Angular Kendo Grid', () => {
    let gridSelectionHelper: GridSelectionHelper;
    const selectAllService = { manageSelectDeSelect: jest.fn };
    beforeEach(() => {
        gridSelectionHelper = new GridSelectionHelper(selectAllService as any);
        (gridSelectionHelper.rowSelectionChanged as any) = new EventEmitterMock<Array<any>>();
    });
    describe('isMultipic', () => {
        it('isMultipic should return true if mode is multiple', () => {
            const options = { columns: [], selectable: { mode: 'multiple', enabled: true } };
            expect(gridSelectionHelper._isMultipick(options as any)).toBeTruthy();
        });

        it('isMultipic should return false if mode is single', () => {
            const options = { columns: [], selectable: { mode: 'single', enabled: true } };
            expect(gridSelectionHelper._isMultipick(options as any)).toBeFalsy();
        });
    });
    describe('checkChanged', () => {
        it('selects the page that already has some selections using zero based row index', () => {
            const options = { selectable: { mode: 'multiple', enabled: true }, onDataBound: jest.fn() };
            const dataset = [1, 2, 3, 4, 5].map((val, index) => ({ val, index }));
            const data = { data: dataset, total: dataset.length };
            gridSelectionHelper.rowSelection = [2, 4]; // index 2 and 4
            gridSelectionHelper.allSelectedItems = [data.data[2], data.data[4]];
            gridSelectionHelper.allSelectedItems.forEach(row => row.selected = true);
            gridSelectionHelper.isAllPageSelect = false;
            gridSelectionHelper.checkChanged(undefined, options, data);
            expect(gridSelectionHelper.rowSelection.length).toEqual(2);
            expect(gridSelectionHelper.rowSelectionChanged.emit).toHaveBeenCalledWith(expect.objectContaining({ dataItem: undefined, deselectedRows: [{ index: 0, val: 1 }, { index: 1, val: 2 }, { index: 3, val: 4 }], rowSelection: [{ index: 2, selected: true, val: 3 }, { index: 4, selected: true, val: 5 }], selectedRows: [] }));
        });

        it('selects the page that already has some selections using selection key', () => {
            const options = { selectable: { mode: 'multiple', enabled: true }, onDataBound: jest.fn() };
            const defaultSelection = [{ id: 2, text: 'def', selected: true }, { id: 4, text: 'jkl', selected: true }];
            const data = [{ id: 1, text: 'abc' }, { id: 3, text: 'ghi' }, ...defaultSelection];
            gridSelectionHelper.rowSelectionKey = 'id';
            gridSelectionHelper.rowSelection = [];
            gridSelectionHelper.allSelectedItems = [...defaultSelection];
            gridSelectionHelper.isAllPageSelect = false;
            gridSelectionHelper.checkChanged(undefined, options, data);
            expect(gridSelectionHelper.rowSelection.length).toEqual(2);
            expect(gridSelectionHelper.rowSelectionChanged.emit).toHaveBeenCalledWith(expect.objectContaining({
                dataItem: undefined, deselectedRows:
                    [data[0], data[1]], rowSelection: [data[2], data[3]],
                selectedRows: [data[2], data[3]]
            }));
        });
        it('selects the page in a multi page selection', () => {
            const options = { selectable: { mode: 'multiple', enabled: true }, onDataBound: jest.fn() };
            const alreadySelected = ['def', 'jkl', 'uvw', 'xyz'];
            const data = [{ id: 1, text: 'abc', selected: true }, { id: 2, text: 'def' }, { id: 3, text: 'ghi' }, { id: 4, text: 'jkl' }];
            gridSelectionHelper.rowSelectionKey = 'text';
            gridSelectionHelper.rowSelection = [];
            const alreadySelectedItems = alreadySelected.map((text, id) => ({ text, id: id + 4 }));
            gridSelectionHelper.allSelectedItems = alreadySelectedItems;

            gridSelectionHelper.isAllPageSelect = false;
            gridSelectionHelper.checkChanged(undefined, options, data);
            expect(gridSelectionHelper.rowSelection.length).toEqual(1);
            expect(gridSelectionHelper.rowSelectionChanged.emit).toHaveBeenCalledWith(expect.objectContaining({
                dataItem: undefined, deselectedRows: [data[1], data[2],
                data[3]], rowSelection: [{ id: 6, text: 'uvw' }, { id: 7, text: 'xyz' }, data[0]],
                selectedRows: [data[0]]
            }));
        });
        it('deselects the page with key ', () => {
            const options = { selectable: { mode: 'multiple', enabled: true }, onDataBound: jest.fn() };
            gridSelectionHelper.allSelectedItems = [];
            const data = [{ id: 1, text: 'abc' }, { id: 2, text: 'def' }, { id: 3, text: 'ghi' }];
            gridSelectionHelper.rowSelectionKey = 'text';
            expect(gridSelectionHelper.rowSelection.length).toEqual(0);
            gridSelectionHelper.checkChanged(undefined, options, data);
            expect(gridSelectionHelper.rowSelectionChanged.emit).toHaveBeenCalledWith(expect.objectContaining({ deselectedRows: [{ id: 1, text: 'abc' }, { id: 2, text: 'def' }, { id: 3, text: 'ghi' }], rowSelection: [], selectedRows: [] }));
        });
    });
    describe('row selection', () => {
        let data: any;
        let dataOptions: any;
        beforeEach(() => {
            dataOptions = { columns: [], selectable: { mode: 'multiple', enabled: true } };
            data = [{ id: 1, text: 'abc' }, { id: 2, text: 'def' }, { id: 3, text: 'ghi' }, { id: 4, text: 'ghi' }, { id: 5, text: 'ghi' }, { id: 6, text: 'ghi' }, { id: 7, text: 'ghi' }, { id: 8, text: 'ghi' }, { id: 9, text: 'ghi' }, { id: 10, text: 'ghi' }, { id: 11, text: 'ghi' }];
            gridSelectionHelper.rowSelection = [0];
        });
        const initWithData = (gridOptions: any): void => {
            dataOptions = { columns: [], ...gridOptions };
        };

        it('raises event only if selectable is set', () => {
            initWithData({ selectable: false } as any);
            gridSelectionHelper.checkChanged(undefined, dataOptions, data);
            expect(gridSelectionHelper.rowSelectionChanged.emit).not.toHaveBeenCalled();
        });

        it('should raise event correctly if only deselectedRows in event', () => {
            dataOptions.selectable = { mode: 'multiple', enabled: true };
            gridSelectionHelper.rowSelection = [0, 1];
            gridSelectionHelper.allSelectedItems = [];
            const deselectedRows = [{ dataItem: data[1], index: 0 }]; // Only row 0 is selected now, which was already selected
            data = [...deselectedRows];
            gridSelectionHelper.checkChanged(undefined, dataOptions, data);
            expect(gridSelectionHelper.rowSelectionChanged.emit).toHaveBeenCalledWith(expect.objectContaining({ selectedRows: [], deselectedRows, rowSelection: gridSelectionHelper.allSelectedItems }));
        });

        it('should add the selected records to existing selection', () => {
            const selectedRows = [{ dataItem: data[1], index: 1 }];
            selectedRows.forEach((row) => (row as any).selected = true);
            data = [...selectedRows];
            gridSelectionHelper.checkChanged(undefined, dataOptions, data);
            expect(gridSelectionHelper.rowSelectionChanged.emit).toHaveBeenCalledWith(expect.objectContaining({ selectedRows, deselectedRows: [], rowSelection: gridSelectionHelper.allSelectedItems }));
        });

        it('should handle multiple selected records', () => {
            const selectedRows = [{ dataItem: data[1], index: 1 }, { dataItem: data[2], index: 2 }];
            selectedRows.forEach((row) => (row as any).selected = true);
            data = [...selectedRows];
            gridSelectionHelper.rowSelection = [];
            gridSelectionHelper.checkChanged(undefined, dataOptions, data);
            expect(gridSelectionHelper.rowSelectionChanged.emit).toHaveBeenCalledWith(expect.objectContaining({ selectedRows, deselectedRows: [], rowSelection: gridSelectionHelper.allSelectedItems }));
        });

        it('should handle mix of selected records and deselected records', () => {
            const selectedRows = [{ dataItem: data[1], index: 1 }, { dataItem: data[2], index: 2 }];
            const deselectedRows = [{ dataItem: data[0], index: 0 }];
            selectedRows.forEach((row) => (row as any).selected = true);
            data = [...selectedRows, ...deselectedRows];
            gridSelectionHelper.rowSelection = [];
            gridSelectionHelper.checkChanged(undefined, dataOptions, data);
            expect(gridSelectionHelper.rowSelectionChanged.emit).toHaveBeenCalledWith(expect.objectContaining({ selectedRows, deselectedRows, rowSelection: gridSelectionHelper.allSelectedItems }));
        });

        it('should handle mix of selected records and deselected records using selection key', () => {
            gridSelectionHelper.rowSelectionKey = 'text';
            gridSelectionHelper.rowSelection = ['ghi'];
            const selectedRows = [{
                dataItem: data[0],
                index: 0,
                selected: true
            }, {
                dataItem: data[1],
                index: 1,
                selected: true
            }];
            const deselectedRows = [{ dataItem: data[2], index: 2 }];
            selectedRows.forEach((row) => row.selected = true);
            data = [...selectedRows, ...deselectedRows];
            gridSelectionHelper.allSelectedItems = [];
            gridSelectionHelper.checkChanged(undefined, dataOptions, data);
            expect(gridSelectionHelper.rowSelectionChanged.emit).toHaveBeenCalledWith(expect.objectContaining({ selectedRows, deselectedRows }));
            expect(gridSelectionHelper.isSelectAll).toBe(false);
        });
        it('should set isSelectAll true if all records are selected on page', () => {
            const selectedRows = [{ dataItem: data[1], index: 1 }, { dataItem: data[2], index: 2 }];
            selectedRows.forEach((row) => (row as any).selected = true);
            data = [...selectedRows];
            gridSelectionHelper.allSelectedItems = [];
            gridSelectionHelper.checkChanged(undefined, dataOptions, data);
            expect(gridSelectionHelper.isSelectAll).toBe(true);
        });
        it('should get all selected items in group', () => {
            gridSelectionHelper.allSelectedItems = [{ dataItem: data[1], index: 1 }];
            const selectedRows = [{ dataItem: data[0], index: 0 }, { dataItem: data[1], index: 1 }, { dataItem: data[2], index: 2 }];
            selectedRows.forEach((row) => (row as any).selected = true);
            data = [...selectedRows];
            gridSelectionHelper.rowSelectionKey = 'dataItem';
            gridSelectionHelper.setAllSelectedItems(selectedRows, [1]);
            expect(gridSelectionHelper.allSelectedItems[1]).toBe(selectedRows);
        });

        it('should select deselected rows', () => {
            const data1 = [{ id: 123, name: 'abwc', selected: false }, { id: 234, name: 'cde', selected: false }, { id: 487, name: 'efg', selected: false }];
            const selectedRows = [{ id: 487, name: 'abc', selected: true }];
            const deSelectedRows = [{ id: 261, name: 'aed' }];
            gridSelectionHelper.rowSelection = [1];
            gridSelectionHelper.rowSelectionKey = 'dataItem';
            gridSelectionHelper.selectDeselectRow(data1, selectedRows, deSelectedRows);
            expect(deSelectedRows.length).toBe(2);
            expect(deSelectedRows[1]).toBe(data1);
        });

        it('should select deselected Ids', () => {
            const row = { dataItem: data[0], index: 0 };
            let selectDeselectIds = [1, 2];
            gridSelectionHelper.rowSelectionKey = 'dataItem';
            gridSelectionHelper.selectDeselectIds(row, selectDeselectIds);
            expect(selectDeselectIds.length).toBe(3);
            expect(selectDeselectIds[2]).toBe(row.dataItem);
            gridSelectionHelper.rowSelectionKey = '';
            selectDeselectIds = [1, 2];
            gridSelectionHelper.selectDeselectIds(row, selectDeselectIds);
            expect(selectDeselectIds.length).toBe(3);
            expect(selectDeselectIds[2]).toBe(0);
        });
    });
    describe('selectDeselectPage', () => {
        let data: any;
        let dataOptions: any;
        beforeEach(() => {
            dataOptions = { columns: [], selectable: { mode: 'multiple', enabled: true } };
            data = [{ id: 1, text: 'abc' }, { id: 2, text: 'def' }, { id: 3, text: 'ghi' }, { id: 4, text: 'ghi' }, { id: 5, text: 'ghi' }, { id: 6, text: 'ghi' }, { id: 7, text: 'ghi' }, { id: 8, text: 'ghi' }, { id: 9, text: 'ghi' }, { id: 10, text: 'ghi' }, { id: 11, text: 'ghi' }];
            gridSelectionHelper.rowSelection = [1, 3];
        });
        it('should select all records when present in deselect array', () => {
            const selectedRows = [data[1], data[2]];
            const deselectedRows = [data[0]];
            selectedRows.forEach((row) => (row).selected = true);
            data = [...selectedRows, ...deselectedRows];
            gridSelectionHelper.isAllPageSelect = true;
            gridSelectionHelper.rowSelectionKey = 'id';
            gridSelectionHelper.allDeSelectIds = [1];
            gridSelectionHelper.selectDeselectPage(data);
            expect(data[0].selected).toBe(true);
        });
        it('should select all records', () => {
            gridSelectionHelper.isAllPageSelect = false;
            gridSelectionHelper.rowSelectionKey = 'id';
            gridSelectionHelper.allDeSelectIds = [1];
            gridSelectionHelper.selectDeselectPage(data);
            expect(data[0].selected).toBe(true);
            expect(data[1].selected).toBe(false);
            expect(data[2].selected).toBe(true);
            expect(gridSelectionHelper.isSelectAll).toBe(false);
        });
    });
    describe('clearSelection', () => {
        it('should reset all fields', () => {
            gridSelectionHelper.allSelectedItems = [{ key: 1 }, { key: 2 }];
            gridSelectionHelper.isAllPageSelect = true;
            gridSelectionHelper.allDeSelectIds = [3, 4];
            gridSelectionHelper.allDeSelectedItems = [{ key: 4 }, { key: 5 }];
            gridSelectionHelper.countOfRecord = ['10, 20'];
            gridSelectionHelper.allSelectedIds = [1, 2];
            gridSelectionHelper.resetSelection();
            expect(gridSelectionHelper.allSelectedItems).toEqual([]);
            expect(gridSelectionHelper.rowSelection).toEqual([]);
            expect(gridSelectionHelper.isAllPageSelect).toEqual(false);
            expect(gridSelectionHelper.allDeSelectIds).toEqual([]);
            expect(gridSelectionHelper.allSelectedIds).toEqual([]);
            expect(gridSelectionHelper.countOfRecord).toEqual([]);
            expect(gridSelectionHelper.allDeSelectedItems).toEqual([]);
        });
        it('should emit rowSelection with empty fields', () => {
            gridSelectionHelper.allSelectedItems = [{ key: 1 }, { key: 2 }];
            gridSelectionHelper.isAllPageSelect = true;
            gridSelectionHelper.ClearSelection();
            expect(gridSelectionHelper.allSelectedItems).toEqual([]);
            expect(gridSelectionHelper.isAllPageSelect).toEqual(false);
            expect(gridSelectionHelper.rowSelectionChanged.emit).toBeCalledWith({ rowSelection: [], totalRecord: 0, allDeSelectIds: [], isSortingEvent: false });
        });
    });
    describe('Select/Clear all page', () => {
        it('should set selected true for all rows', () => {
            gridSelectionHelper.rowSelection = [1, 2, 3];
            const data = [{ id: 1, text: 'abc', selected: false }, { id: 2, text: 'def', selected: false }, { id: 3, text: 'ghi', selected: true }];
            gridSelectionHelper.selectAllPage(data);
            expect(gridSelectionHelper.isAllPageSelect).toEqual(true);
            expect(data[0].selected).toEqual(true);
            expect(gridSelectionHelper.countOfRecord).toEqual(['1', '2', '3']);
        });
        it('clears selection', () => {
            gridSelectionHelper.rowSelection = [1, 2, 3];
            const data = [{ id: 1, text: 'abc', selected: true }, { id: 2, text: 'def', selected: true }, { id: 3, text: 'ghi', selected: true }];
            gridSelectionHelper.deselectAllPage(data);
            expect(gridSelectionHelper.rowSelection.length).toEqual(0);
            expect(data[0].selected).toEqual(false);
        });
    });
});