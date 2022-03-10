import { QueryList } from '@angular/core';
import { ColumnBase } from '@progress/kendo-angular-grid';
import { BehaviorSubjectMock } from 'mocks/behaviorsubject.mock';
import { EventEmitterMock } from 'mocks/event-emitter.mock';
import { of } from 'rxjs';
import { GridSelectionHelper } from './ipx-grid-selection-helper';

export class IpxKendoGridComponentMock {
    rowSelectionChanged = new EventEmitterMock<{ ctrlKey: boolean, shiftKey: boolean, selectedRows: Array<any>, deselectedRows: Array<any> }>();
    wrapper = { focus: jest.fn(), focusCell: jest.fn(), totalCount: 0, cellClick: of({}), leafColumns: new QueryList<ColumnBase>() } as any;
    dataBound = new EventEmitterMock<any>();
    dataOptions = {
        _selectRows: jest.fn()
    } as any;
    getExistingSelectedData = jest.fn(() => []);
    resetColumns = jest.fn();
    rowSelectionKey = '';
    columns = [];
    rowSelection = [];
    collapseAll = jest.fn();
    closeEditedRows = jest.fn();
    search = jest.fn();
    clear = jest.fn();
    totalRecord = new EventEmitterMock();
    getCurrentData = jest.fn(() => []);
    currentEditRowIdx = null;
    navigateByIndex = jest.fn();
    clearFilters = jest.fn();
    rowEditFormGroups = [];
    resetBulkActionMenu = jest.fn();
    addRow = jest.fn();
    closeRow = jest.fn();
    gridSelectionHelper = new GridSelectionHelper({ manageSelectDeSelect: jest.fn } as any);
    resetSelection = jest.fn();
    getSelectedItems = jest.fn().mockReturnValue([]);
    getRowSelectionParams = jest.fn().mockReturnValue({
        allSelectedItems: [],
        rowSelection: [],
        allDeSelectIds: [],
        isAllPageSelect: false,
        allDeSelectedItems: [],
        singleRowSelected$: of({})
    });
    clearSelection = jest.fn();
    selectAllPage = jest.fn();
    onAdd = jest.fn();
    expandAll = jest.fn();
}