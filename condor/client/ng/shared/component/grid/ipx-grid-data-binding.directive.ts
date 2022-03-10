
import { ChangeDetectorRef, Directive, EventEmitter, Input, OnChanges, OnDestroy, OnInit, Output, SimpleChanges } from '@angular/core';
import { DataBindingDirective, DataStateChangeEvent, GridComponent } from '@progress/kendo-angular-grid';
import { FilterDescriptor, process, SortDescriptor, State } from '@progress/kendo-data-query';
import * as _ from 'underscore';
import { IpxGridOptions } from './ipx-grid-options';
import { GridPagableData } from './ipx-grid.models';
import { IpxGroupingService } from './ipx-kendo-grouping.service';

@Directive({
    selector: '[ipxGridDataBinding]'
})
export class IpxGridDataBindingDirective extends DataBindingDirective implements OnInit, OnDestroy, OnChanges {
    @Input('ipxGridDataBinding') set dataOptions(options: IpxGridOptions) {
        if (options && this._dataOptions !== options) {
            this._dataOptions = options;
            if (this._dataOptions.autobind) {
                this.getData();
            }
        }
    }
    get dataOptions(): IpxGridOptions {
        return this._dataOptions;
    }
    @Output('ipxOnGridDataBinding') readonly onDataBinding: EventEmitter<any> = new EventEmitter<any>();

    private lastSort: SortDescriptor | any = {};
    private _dataOptions: IpxGridOptions;

    constructor(private readonly gridRef: GridComponent, private readonly cdr: ChangeDetectorRef, private readonly ipxGroupingService: IpxGroupingService) {
        super(gridRef);
    }

    ngOnInit(): void {
        super.ngOnInit();
    }

    ngOnChanges(changes: SimpleChanges): void {
        if (changes.group) {
            return;
        }
    }

    onStateChange(state: DataStateChangeEvent): void {
        this.dataOptions.groups = state.group;
        super.onStateChange(state);
    }

    refreshGrid(): void {
        const initialState: State = {
            skip: 0,
            take: this.state.take || this.gridRef.pageSize,
            sort: [],
            filter: {
                logic: 'and',
                filters: []
            }
        };
        super.applyState(initialState);
        this.rebind();
    }

    bindOneTimeData(): void {
        this.getData();
    }

    selectPage(skip: number): void {
        this.state.skip = skip;
        this.rebind();
    }

    ngOnDestroy(): void {
        super.ngOnDestroy();
    }

    clear(): void {
        this.grid.data = [];
        this.onDataBinding.emit();
        this.notifyDataChange();
    }

    rebind(): void {
        if (this._dataOptions.manualOperations) {
            return;
        }

        this.getData();
    }

    addRow(item: any): number {
        if (!this.grid.data) {

            return null;
        }

        if (Array.isArray(this.grid.data)) {
            if (this._dataOptions.addRowToTheBottom) {
                (this.grid.data).push(item);

                return (this.grid.data).length - 1;
            }
            (this.grid.data).unshift(item);

            return 0;
        } else if (this.grid.data !== undefined) {
            if (this._dataOptions.addRowToTheBottom) {
                (this.grid.data).data.push(item);

                return (this.grid.data).data.length - 1;
            }

            (this.grid.data).data.unshift(item);
        }

        return 0;
    }

    removeRow(currentRowIdx: any): number {
        if (!this.grid.data) {

            return null;
        }

        if (Array.isArray(this.grid.data)) {
            this.grid.data.splice(currentRowIdx, 1);

            return this.grid.data.length - 1;
        }

        this.grid.data.data.splice(currentRowIdx, 1);

        return this.grid.data.data.length - 1;
    }

    closeRow(rowIdx: number, collapseRow = true): void {
        if (collapseRow) {
            this.grid.collapseRow(rowIdx);
        }
        this.grid.closeRow(rowIdx);
    }

    editRow(rowIdx: number, dataItem: any): void {
        this.grid.editRow(rowIdx);
    }

    private getData(): void {
        this.grid.loading = true;
        this.cdr.markForCheck();
        this._dataOptions.read$(this.queryParams()).subscribe(data => {
            this.grid.loading = false;
            this.grid.data = (data as GridPagableData).data === undefined ? data as Array<any> : { data: (data as GridPagableData).data, total: (data as GridPagableData).pagination.total };
            if (this.dataOptions.groups && !_.isEmpty(this.dataOptions.groups)) {
                this.applyGrouping();
            }
            this.cdr.markForCheck();
            this.onDataBinding.emit();
            this.notifyDataChange();
        }, (error) => {
            this.grid.loading = false;
            this.cdr.markForCheck();
        });
    }

    applyGrouping(): void {
        const convertedGroupResult = { data: [], total: 0 };
        this.dataOptions.groups.forEach((g) => g.aggregates = [{ field: g.field, aggregate: 'count' }]);
        const gridData: any = this.grid.data;
        const groupedResult = process(gridData.data, { group: new Array(1).fill(_.first(this.dataOptions.groups)) });
        this.ipxGroupingService.groupedDataSet$.next(groupedResult.data);
        groupedResult.data.forEach((item) => {
            convertedGroupResult.data.push(this.ipxGroupingService.convertRecordForGrouping(item));
        });
        convertedGroupResult.total = gridData.total;
        this.grid.data = convertedGroupResult;
        this.ipxGroupingService.isProcessCompleted$.next(true);
    }

    private queryParams(): any {
        // ToDo: Multiple column sorting option is available in the grid.
        const sortState: any = this.getSorting();
        const filters = this.getFilters();
        let skip = this.state.skip;
        if (this.hasSortingChanged(sortState)) {
            skip = 0;
            this.grid.skip = skip;
        }

        return {
            skip,
            take: this.dataOptions.groups && _.any(this.dataOptions.groups) ? null : (this._dataOptions.pageable ? (this.state.take || this.gridRef.pageSize) : null),
            sortBy: sortState.field,
            sortDir: sortState.dir,
            filters
        };
    }

    private readonly hasSortingChanged = (newsort: SortDescriptor): boolean => {
        if (Boolean(this.lastSort) !== Boolean(newsort)
            || this.lastSort.field !== newsort.field
            || this.lastSort.dir !== newsort.dir) {

            this.lastSort = newsort;

            return true;
        }

        return false;
    };

    private readonly getFilters = (): Array<FilterDescriptor> => {
        const filters = [];
        if (this.state.filter && this.state.filter.filters) {
            const allFilters = this.state.filter.filters.map((f): Array<FilterDescriptor> => {
                return this.mapFilters(f, 1);
            });
            for (const subFilters of allFilters) {
                for (const f of subFilters) {
                    filters.push(f);
                }
            }
        }

        return filters;
    };

    private readonly getSorting = (): SortDescriptor | any => {
        const sortState: any = this.state.sort && this.state.sort.length > 0 ? this.state.sort[0] : {};
        if (sortState.dir === undefined) {
            sortState.field = undefined;
        }

        return sortState;
    };

    private readonly mapFilters = (f: any, count?: number): Array<FilterDescriptor> => {
        if (f.filters) {
            // tslint:disable-next-line: no-parameter-reassignment
            return this.mapFilters(f.filters, count++);
        }
        if (f.length > 0) {
            return f;
        }
        if (count > 5) {
            return undefined;
        }
    };
}