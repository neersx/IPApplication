import { EventEmitter } from '@angular/core';
import { GridDataResult } from '@progress/kendo-angular-grid';
import { SelectableSettings } from '@progress/kendo-angular-treeview';
import { BehaviorSubject } from 'rxjs';
import * as _ from 'underscore';
import { IpxGridOptions } from './ipx-grid-options';
import { IPXKendoGridSelectAllService } from './ipx-kendo-grid-selectall.service';

export class GridSelectionHelper {
    allSelectedItems: Array<any>;
    rowSelection: Array<any> = [];
    rowSelectionKey = '';
    isAllPageSelect = false;
    allDeSelectIds: Array<number> = [];
    allSelectedIds: Array<number> = [];
    allDeSelectedItems: Array<any> = [];
    countOfRecord: Array<string> = [];
    isSelectAll = false;
    singleRowSelected$ = new BehaviorSubject<boolean>(false);
    readonly rowSelectionChanged = new EventEmitter<any>();

    constructor(private readonly selectAllService: IPXKendoGridSelectAllService) { }

    readonly _isMultipick = (gridOptions: IpxGridOptions): boolean => {
        if (!gridOptions.selectable) {
            return false;
        }
        const selectable = gridOptions.selectable as SelectableSettings;

        return selectable.mode === 'multiple' && selectable.enabled;
    };

    readonly getCurrentData = (data: any): Array<any> => {
        if (data) {

            return (data as GridDataResult).data ? (data as GridDataResult).data : data as Array<any>;
        }

        return [];
    };

    checkChanged = (dataItem?: any, dataOptions?: any, wrapperData?: any): any => {
        if (this._isMultipick(dataOptions) || dataOptions.bulkActions) {
            const data: Array<any> = this.getCurrentData(wrapperData);
            if (dataOptions.onDataItemCheckboxSelection) {
                dataOptions.onDataItemCheckboxSelection(dataItem, data);
            }
            const gridData: any = wrapperData;
            const isPagingEnabled = gridData.total;
            const selectedRows: any = [];
            const deselectedRows: any = [];
            const deselectedIds: Array<any> = [];
            const selectedIds: Array<any> = [];
            if (!this.allSelectedItems) {
                this.allSelectedItems = [];
            }
            if (this.allSelectedItems.length === 0 && this.rowSelection && this.rowSelection.length > 0) {
                this.allSelectedItemWhenItsLengthZero(data);
            }
            this.selectDeselectRow({ items: data }, selectedRows, deselectedRows);
            this.selectDeselectIds({ items: selectedRows }, selectedIds);
            this.selectDeselectIds({ items: deselectedRows }, deselectedIds);
            if (!this.isAllPageSelect) {
                this.rowSelection = [...this.rowSelection, ...selectedIds].filter((row) => deselectedIds.indexOf(row) === -1);
                this.setAllSelectedItems({ items: [...(this.allSelectedItems || []), ...selectedRows] }, deselectedIds);
                const afterRemovingDeselected = this.rowSelection.filter(val => deselectedIds.indexOf(val) === -1);
                const uniqueNew = selectedIds.filter(val => afterRemovingDeselected.indexOf(val) === -1);
                afterRemovingDeselected.push(...uniqueNew);
                this.isSelectAll = _.every(data, (d) => {
                    return d.selected === true;
                });

                this.singleRowSelected$.next((this.allSelectedItems && this.allSelectedItems.length === 1));
                this.rowSelectionChanged.emit({
                    dataItem,
                    rowSelection: this.allSelectedItems,
                    selectedRows, deselectedRows,
                    totalRecord: gridData.total ? gridData.total : gridData.length,
                    allDeSelectIds: deselectedIds
                });
                this.countOfRecord = [];
                this.allDeSelectedItems = [];
                this.allDeSelectIds = [];
            } else {
                this.allSelectedItems = [];
                const selectDeselct = this.selectAllService.manageSelectDeSelect(deselectedIds, selectedIds,
                    this.allDeSelectIds, this.allDeSelectedItems, this.countOfRecord, data, this.rowSelectionKey, isPagingEnabled);
                this.allSelectedIds = selectDeselct.selectedIds;
                this.allDeSelectIds = selectDeselct.allDeSelectIds;
                this.allDeSelectedItems = selectDeselct.allDeSelectedItems;
                this.countOfRecord = selectDeselct.countOfRecord;
                this.rowSelectionChanged.emit(
                    {
                        rowSelection: this.countOfRecord,
                        nonPagingRecordCount: !isPagingEnabled ? selectDeselct.allDeSelectIds.length !== 0 ? selectDeselct.nonPagingRecordCount : selectDeselct.countOfRecord.length : null,
                        totalRecord: gridData.total ? gridData.total : gridData.length,
                        allDeSelectIds: this.allDeSelectIds
                    });
            }
        }

        return this.allSelectedItems;
    };

    readonly allSelectedItemWhenItsLengthZero = (data: any): void => {
        if (_.isArray(data)) {
            data.forEach(item => {
                this.allSelectedItemWhenItsLengthZero(item);
            });
        } else {
            if (data.selected && this.rowSelection.indexOf(this.rowSelectionKey && data[this.rowSelectionKey] ? data[this.rowSelectionKey] : data.index) !== -1) {
                this.allSelectedItems.push(data);
            }
        }
    };

    readonly selectDeselectRow = (data: any, selectedRows: any, deSelectedRows: any): void => {
        if (data.items) {
            data.items.forEach(item => {
                this.selectDeselectRow(item, selectedRows, deSelectedRows);
            });
        } else {
            if (data.selected && this.rowSelection.indexOf(this.rowSelectionKey && data[this.rowSelectionKey] ? data[this.rowSelectionKey] : data.index) === -1) {
                selectedRows.push(data);
            }
            if (!data.selected) {
                deSelectedRows.push(data);
            }
        }
    };

    readonly setAllSelectedItems = (item: any, deselectId: any): void => {
        if (item.items) {
            item.items.forEach(items => {
                this.setAllSelectedItems(items, deselectId);
            });
        } else {
            if (deselectId.indexOf(this.rowSelectionKey && item[this.rowSelectionKey] ? item[this.rowSelectionKey] : item.index) === -1) {
                if (!this.allSelectedItems.find(el => el[this.rowSelectionKey] === item[this.rowSelectionKey])) {
                    this.allSelectedItems.push(item);
                }
            } else {
                this.allSelectedItems = _.filter(this.allSelectedItems, (avl) => {
                    return !_.contains(deselectId, avl[this.rowSelectionKey]);
                });
            }
        }
    };

    readonly selectDeselectIds = (row: any, selectDeselect: Array<number>): void => {
        if (row.items) {
            row.items.forEach(item => {
                this.selectDeselectIds(item, selectDeselect);
            });
        } else {
            selectDeselect.push(this.rowSelectionKey && (row[this.rowSelectionKey] || row[this.rowSelectionKey] === 0) ? row[this.rowSelectionKey] : row.index);
        }
    };

    ClearSelection(isSortingEvent = false): void {
        this.resetSelection();
        this.rowSelectionChanged.emit({ rowSelection: [], totalRecord: 0, allDeSelectIds: [], isSortingEvent });
    }

    resetSelection(): void {
        this.allSelectedItems = [];
        this.rowSelection = [];
        this.isAllPageSelect = false;
        this.allDeSelectIds = [];
        this.allSelectedIds = [];
        this.countOfRecord = [];
        this.allDeSelectedItems = [];
    }

    selectDeselectPage = (data: Array<any>): void => {
        if (this.isAllPageSelect) {
            this.getDelselectedRowOnSelectAll({ items: data });
        } else {
            this.getSelectedRowOnPaging({ items: data });
            this.isSelectAll = _.every(data, (d) => {
                return d.selected === true;
            });
        }
    };

    readonly getDelselectedRowOnSelectAll = (row: any): void => {
        if (row.items) {
            row.items.forEach(item => {
                this.getDelselectedRowOnSelectAll(item);
            });
        } else {
            row.selected = this.allDeSelectIds.indexOf(row[this.rowSelectionKey].toString()) === -1;
        }
    };

    readonly getSelectedRowOnPaging = (row: any): void => {
        if (row.items) {
            row.items.forEach(item => {
                this.getSelectedRowOnPaging(item);
            });
        } else {
            row.selected = this.rowSelection.indexOf(row[this.rowSelectionKey]) !== -1;
        }
    };

    selectAllPage = (data: any): void => {
        const rows: Array<any> = this.getCurrentData(data);
        this.setSelection({ items: rows }, true);
        this.isAllPageSelect = true;
        this.setRowCount(data);
    };

    deselectAllPage = (data: any): void => {
        const rows: Array<any> = this.getCurrentData(data);
        this.setSelection({ items: rows }, false);
        this.resetSelection();
    };

    readonly setSelection = (row: any, checked: boolean): void => {
        if (row.items) {
            row.items.forEach(item => {
                this.setSelection(item, checked);
            });
        } else {
            row.selected = checked;
        }
    };

    readonly setRowCount = (data: any): void => {
        this.countOfRecord = [];
        const total: number = data.total || data.length;
        for (let i = 1; i <= total; i++) {
            this.countOfRecord.push(i.toString());
        }
    };
}